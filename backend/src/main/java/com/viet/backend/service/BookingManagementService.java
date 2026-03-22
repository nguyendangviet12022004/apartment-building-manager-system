package com.viet.backend.service;

import com.viet.backend.dto.BookingDTO;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.Notification;
import com.viet.backend.model.ServiceBooking;
import com.viet.backend.model.User;
import com.viet.backend.repository.NotificationRepository;
import com.viet.backend.repository.ServiceBookingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing service bookings (Manager role)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BookingManagementService {

    private final ServiceBookingRepository serviceBookingRepository;
    private final NotificationRepository notificationRepository;

    /**
     * Get all bookings with filtering and pagination
     */
    @Transactional(readOnly = true)
    public BookingDTO.BookingListResponse getBookings(BookingDTO.BookingFilterRequest request) {
        log.info("Fetching bookings with filters: search={}, status={}", 
                request.getSearch(), request.getStatus());

        // Set default pagination
        int page = request.getPage() != null ? request.getPage() : 0;
        int pageSize = request.getPageSize() != null ? request.getPageSize() : 20;
        
        // Get all bookings
        List<ServiceBooking> allBookings = serviceBookingRepository.findAll();
        log.info("Found {} total bookings in database", allBookings.size());
        
        // Map to DTOs and filter out nulls
        List<BookingDTO.BookingListItem> allBookingItems = allBookings.stream()
                .map(this::mapToListItem)
                .filter(item -> item != null)
                .collect(Collectors.toList());
        
        log.info("Successfully mapped {} bookings to DTOs", allBookingItems.size());
        
        // Apply filters
        List<BookingDTO.BookingListItem> filteredBookings = allBookingItems.stream()
                .filter(item -> applyFilters(item, request))
                .collect(Collectors.toList());

        log.info("After filtering: {} bookings match criteria", filteredBookings.size());

        // Calculate pagination
        int totalCount = filteredBookings.size();
        int totalPages = totalCount > 0 ? (int) Math.ceil((double) totalCount / pageSize) : 0;
        int fromIndex = page * pageSize;
        int toIndex = Math.min(fromIndex + pageSize, totalCount);

        // Get paginated results
        List<BookingDTO.BookingListItem> paginatedBookings = fromIndex < totalCount
                ? filteredBookings.subList(fromIndex, toIndex)
                : new ArrayList<>();

        log.info("Returning {} bookings (page {}/{}, total: {})", 
                paginatedBookings.size(), page + 1, totalPages, totalCount);

        return BookingDTO.BookingListResponse.builder()
                .bookings(paginatedBookings)
                .totalCount(totalCount)
                .page(page)
                .pageSize(pageSize)
                .totalPages(totalPages)
                .build();
    }

    /**
     * Map ServiceBooking entity to BookingListItem DTO
     */
    private BookingDTO.BookingListItem mapToListItem(ServiceBooking booking) {
        try {
            Apartment apartment = booking.getApartment();
            if (apartment == null) {
                log.warn("Booking {} has no apartment - skipping", booking.getId());
                return null;
            }

            User user = apartment.getResident() != null ? apartment.getResident().getUser() : null;
            if (user == null) {
                log.warn("Booking {} has no resident user - skipping", booking.getId());
                return null;
            }

            String residentName = (user.getFirstname() + " " + user.getLastname()).trim();
            if (residentName.isEmpty()) {
                residentName = user.getEmail();
            }

            String serviceName = booking.getService() != null ? booking.getService().getServiceName() : "Unknown Service";
            
            // Determine service icon based on service name
            String serviceIcon = determineServiceIcon(serviceName);

            return BookingDTO.BookingListItem.builder()
                    .bookingId(booking.getId())
                    .residentName(residentName)
                    .unitNumber(apartment.getApartmentCode())
                    .serviceName(serviceName)
                    .serviceIcon(serviceIcon)
                    .startTime(booking.getStartTime())
                    .endTime(booking.getEndTime())
                    .status(booking.getStatus().name())
                    .totalPrice(booking.getTotalPrice())
                    .quantity(booking.getQuantity())
                    .build();
                    
        } catch (Exception e) {
            log.error("Error mapping booking {}: {}", booking.getId(), e.getMessage(), e);
            return null;
        }
    }

    /**
     * Determine service icon based on service name
     */
    private String determineServiceIcon(String serviceName) {
        String lowerName = serviceName.toLowerCase();
        if (lowerName.contains("bbq") || lowerName.contains("grill")) {
            return "bbq";
        } else if (lowerName.contains("pool") || lowerName.contains("swimming")) {
            return "pool";
        } else if (lowerName.contains("gym") || lowerName.contains("fitness")) {
            return "gym";
        } else if (lowerName.contains("tennis") || lowerName.contains("court")) {
            return "tennis";
        } else if (lowerName.contains("parking")) {
            return "parking";
        } else {
            return "default";
        }
    }

    /**
     * Apply filters to booking item
     */
    private boolean applyFilters(BookingDTO.BookingListItem item, BookingDTO.BookingFilterRequest request) {
        if (item == null) {
            return false;
        }
        
        // Search filter (resident name or unit number)
        if (request.getSearch() != null && !request.getSearch().isEmpty()) {
            String search = request.getSearch().toLowerCase();
            boolean matchesSearch = 
                (item.getResidentName() != null && item.getResidentName().toLowerCase().contains(search)) ||
                (item.getUnitNumber() != null && item.getUnitNumber().toLowerCase().contains(search)) ||
                (item.getServiceName() != null && item.getServiceName().toLowerCase().contains(search));
            
            if (!matchesSearch) {
                return false;
            }
        }

        // Status filter
        if (request.getStatus() != null && !request.getStatus().isEmpty()) {
            if (!request.getStatus().equalsIgnoreCase(item.getStatus())) {
                return false;
            }
        }

        return true;
    }

    /**
     * Get booking details by booking ID
     */
    @Transactional(readOnly = true)
    public BookingDTO.BookingDetailResponse getBookingDetails(Long bookingId) {
        log.info("Fetching details for booking ID: {}", bookingId);
        
        ServiceBooking booking = serviceBookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found with ID: " + bookingId));
        
        Apartment apartment = booking.getApartment();
        if (apartment == null) {
            throw new RuntimeException("Apartment not found for booking ID: " + bookingId);
        }

        User user = apartment.getResident() != null ? apartment.getResident().getUser() : null;
        if (user == null) {
            throw new RuntimeException("User not found for booking ID: " + bookingId);
        }

        String residentName = (user.getFirstname() + " " + user.getLastname()).trim();
        if (residentName.isEmpty()) {
            residentName = user.getEmail();
        }

        return BookingDTO.BookingDetailResponse.builder()
                .bookingId(booking.getId())
                .residentName(residentName)
                .residentPhone(user.getPhone())
                .residentEmail(user.getEmail())
                .unitNumber(apartment.getApartmentCode())
                .serviceId(booking.getService().getId())
                .serviceName(booking.getService().getServiceName())
                .serviceDescription(booking.getService().getDescription())
                .unitPrice(booking.getService().getUnitPrice())
                .startTime(booking.getStartTime())
                .endTime(booking.getEndTime())
                .quantity(booking.getQuantity())
                .totalPrice(booking.getTotalPrice())
                .note(booking.getNote())
                .status(booking.getStatus().name())
                .createdAt(null)  // Add createdAt field to ServiceBooking entity if needed
                .build();
    }

    /**
     * Approve a booking request
     * Checks for time conflicts before approving
     */
    @Transactional
    public void approveBooking(Long bookingId) {
        log.info("Attempting to approve booking ID: {}", bookingId);
        
        ServiceBooking booking = serviceBookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        
        // Check if booking is in PENDING status
        if (booking.getStatus() != ServiceBooking.BookingStatus.PENDING) {
            throw new RuntimeException("Only PENDING bookings can be approved. Current status: " + booking.getStatus());
        }
        
        // Check for time conflicts
        List<ServiceBooking> conflicts = serviceBookingRepository.findConflictingBookings(
                booking.getService().getId(),
                booking.getStartTime(),
                booking.getEndTime()
        );
        
        // Filter out the current booking from conflicts
        conflicts = conflicts.stream()
                .filter(b -> !b.getId().equals(bookingId))
                .filter(b -> b.getStatus() == ServiceBooking.BookingStatus.CONFIRMED)
                .collect(Collectors.toList());
        
        if (!conflicts.isEmpty()) {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMM dd, yyyy HH:mm");
            String conflictTime = conflicts.get(0).getStartTime().format(formatter);
            throw new RuntimeException("Time conflict detected. Another booking exists at " + conflictTime);
        }
        
        // Update status to CONFIRMED
        booking.setStatus(ServiceBooking.BookingStatus.CONFIRMED);
        serviceBookingRepository.save(booking);
        
        log.info("Booking {} approved successfully", bookingId);
        
        // Send notification to resident
        sendNotificationToResident(booking, true);
    }

    /**
     * Reject a booking request
     */
    @Transactional
    public void rejectBooking(Long bookingId) {
        log.info("Attempting to reject booking ID: {}", bookingId);
        
        ServiceBooking booking = serviceBookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        
        // Check if booking is in PENDING status
        if (booking.getStatus() != ServiceBooking.BookingStatus.PENDING) {
            throw new RuntimeException("Only PENDING bookings can be rejected. Current status: " + booking.getStatus());
        }
        
        // Update status to REJECTED
        booking.setStatus(ServiceBooking.BookingStatus.REJECTED);
        serviceBookingRepository.save(booking);
        
        log.info("Booking {} rejected successfully", bookingId);
        
        // Send notification to resident
        sendNotificationToResident(booking, false);
    }

    /**
     * Send notification to resident about booking status update
     */
    private void sendNotificationToResident(ServiceBooking booking, boolean approved) {
        try {
            User user = booking.getApartment().getResident().getUser();
            String serviceName = booking.getService().getServiceName();
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMM dd, yyyy HH:mm");
            String bookingTime = booking.getStartTime().format(formatter);
            
            String title = approved 
                    ? "Booking Approved" 
                    : "Booking Rejected";
            
            String content = approved
                    ? String.format("Your booking for %s on %s has been approved", serviceName, bookingTime)
                    : String.format("Your booking for %s on %s has been rejected", serviceName, bookingTime);
            
            Notification notification = Notification.builder()
                    .user(user)
                    .title(title)
                    .content(content)
                    .detail(String.format("Booking ID: %d\nService: %s\nTime: %s", 
                            booking.getId(), serviceName, bookingTime))
                    .build();
            
            notificationRepository.save(notification);
            log.info("Notification sent to user {} for booking {}", user.getId(), booking.getId());
            
        } catch (Exception e) {
            log.error("Failed to send notification for booking {}: {}", booking.getId(), e.getMessage());
            // Don't throw exception, notification failure shouldn't block the approval/rejection
        }
    }
}
