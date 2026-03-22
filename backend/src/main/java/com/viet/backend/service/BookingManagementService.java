package com.viet.backend.service;

import com.viet.backend.dto.BookingDTO;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.ServiceBooking;
import com.viet.backend.model.User;
import com.viet.backend.repository.ServiceBookingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
}
