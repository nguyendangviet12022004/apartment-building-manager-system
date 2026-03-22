package com.viet.backend.controller;

import com.viet.backend.dto.ServiceBookingResponse;
import com.viet.backend.model.*;
import com.viet.backend.repository.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
public class ServiceBookingController {

    private final ServiceBookingRepository bookingRepository;
    private final ServiceRepository serviceRepository;
    private final ApartmentRepository apartmentRepository;

    @GetMapping("/my")
    public ResponseEntity<List<ServiceBookingResponse>> getMyBookings(@RequestHeader("X-User-ID") Integer userId) {
        List<ServiceBooking> bookings = bookingRepository.findByApartment_Resident_User_Id(userId);
        return ResponseEntity.ok(bookings.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList()));
    }

    // API lấy lịch đã đặt trong ngày để hiển thị cho user
    @GetMapping("/schedule")
    public ResponseEntity<List<ServiceBookingResponse>> getSchedule(
            @RequestParam Long serviceId,
            @RequestParam String date) { // date format: 2023-10-27
        
        LocalDateTime startOfDay = java.time.LocalDate.parse(date).atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);

        List<ServiceBooking> bookings = bookingRepository.findConfirmedByDate(serviceId, startOfDay, endOfDay);
        return ResponseEntity.ok(bookings.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList()));
    }

    @GetMapping("/schedule/hourly")
    public ResponseEntity<List<Integer>> getHourlySchedule(
            @RequestParam Long serviceId,
            @RequestParam String date) {

        LocalDate localDate = LocalDate.parse(date);
        LocalDateTime startOfDay = localDate.atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);

        List<ServiceBooking> bookings = bookingRepository.findConfirmedByDate(serviceId, startOfDay, endOfDay);

        List<Integer> hourlyUsage = new ArrayList<>(Collections.nCopies(24, 0));

        for (int h = 0; h < 24; h++) {
            LocalDateTime slotStart = localDate.atTime(h, 0);
            LocalDateTime slotEnd = slotStart.plusHours(1);

            int currentHourUsage = 0;
            for (ServiceBooking b : bookings) {
                if (b.getStartTime().isBefore(slotEnd) && b.getEndTime().isAfter(slotStart)) {
                    currentHourUsage += b.getQuantity();
                }
            }
            hourlyUsage.set(h, currentHourUsage);
        }

        return ResponseEntity.ok(hourlyUsage);
    }

    @PostMapping
    public ResponseEntity<?> createBooking(@RequestBody BookingRequest req, @RequestHeader("X-User-ID") Integer userId) {
        // 1. Validate Service
        Service service = serviceRepository.findById(req.serviceId)
                .orElseThrow(() -> new RuntimeException("Service not found"));

        if (service.getServiceType() != Service.ServiceType.AMENITY) {
            return ResponseEntity.badRequest().body("Only AMENITY services can be booked via this API.");
        }

        // Validate Time
        if (req.startTime.isAfter(req.endTime) || req.startTime.isEqual(req.endTime)) {
            return ResponseEntity.badRequest().body("Start time must be before end time.");
        }
        if (req.startTime.isBefore(LocalDateTime.now())) {
            return ResponseEntity.badRequest().body("Cannot book in the past.");
        }

        // 2. Validate Apartment (Resident)
        Apartment apartment = apartmentRepository.findByResidentUserId(userId)
                .orElseThrow(() -> new RuntimeException("No apartment associated with this user"));

        // 3. Validate Availability (Capacity Check)
        List<ServiceBooking> conflicts = bookingRepository.findConflictingBookings(req.serviceId, req.startTime, req.endTime);
        
        int currentUsage = conflicts.stream().mapToInt(ServiceBooking::getQuantity).sum();
        int requestedQty = req.quantity != null ? req.quantity : 1;

        if (currentUsage + requestedQty > service.getCapacity()) {
            int remaining = Math.max(0, service.getCapacity() - currentUsage);
            return ResponseEntity.badRequest().body("Không thể đặt chỗ: Chỉ còn " + remaining + " chỗ trống trong khung giờ này.");
        }

        // 4. Calculate Total Price
        BigDecimal totalPrice;
        BigDecimal unitPrice = service.getUnitPrice();
        BigDecimal requestedQuantityDecimal = new BigDecimal(requestedQty);

        // The calculation logic depends on the service unit
        if ("Hour".equalsIgnoreCase(service.getUnit())) {
            // Calculate duration in hours, rounding up. E.g., 1h 1m becomes 2h.
            long minutes = Duration.between(req.startTime, req.endTime).toMinutes();
            BigDecimal hours = new BigDecimal(minutes).divide(new BigDecimal(60), 0, RoundingMode.CEILING);
            totalPrice = unitPrice.multiply(hours).multiply(requestedQuantityDecimal);
        } else {
            // For units like "Session", "Visit", "Day", assume it's a one-off price per quantity
            totalPrice = unitPrice.multiply(requestedQuantityDecimal);
        }

        // 5. Create Booking
        ServiceBooking booking = ServiceBooking.builder()
                .service(service)
                .apartment(apartment)
                .startTime(req.startTime)
                .endTime(req.endTime)
                .quantity(requestedQty)
                .note(req.note)
                .totalPrice(totalPrice)
                .status(ServiceBooking.BookingStatus.PENDING) // Mặc định chờ duyệt hoặc Confirm luôn tùy logic
                .build();

        ServiceBooking savedBooking = bookingRepository.save(booking);
        return ResponseEntity.ok(mapToResponse(savedBooking));
    }

    @PatchMapping("/{id}/cancel")
    public ResponseEntity<?> cancelBooking(@PathVariable Long id, @RequestHeader("X-User-ID") Integer userId) {
        ServiceBooking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Booking not found"));

        // 1. Check Ownership
        // Assuming Resident -> User relationship
        if (!booking.getApartment().getResident().getUser().getId().equals(userId)) {
            return ResponseEntity.status(403).body("You do not have permission to cancel this booking.");
        }

        // 2. Check Status
        if (booking.getStatus() == ServiceBooking.BookingStatus.CANCELLED ||
            booking.getStatus() == ServiceBooking.BookingStatus.REJECTED ||
            booking.getStatus() == ServiceBooking.BookingStatus.COMPLETED) {
            return ResponseEntity.badRequest().body("Booking cannot be cancelled in its current status.");
        }

        // 3. Time Rule: Must be at least 3 hours before start time
        // Example: Start 14:00. Limit 11:00. If Now is 11:30 -> Fail.
        LocalDateTime cancelLimit = booking.getStartTime().minusHours(3);
        if (LocalDateTime.now().isAfter(cancelLimit)) {
            return ResponseEntity.badRequest().body("Huỷ thất bại: Chỉ được phép hủy trước giờ hẹn 3 tiếng.");
        }

        // 4. Update Status
        booking.setStatus(ServiceBooking.BookingStatus.CANCELLED);
        ServiceBooking updated = bookingRepository.save(booking);

        // Optional: Return Payment if necessary (Not implemented yet)
        if (updated.getTotalPrice() != null && updated.getTotalPrice().compareTo(BigDecimal.ZERO) > 0) {
            // Logic hoàn tiền hoặc ghi nợ vào invoice tháng sau
            // TODO: Implement refund logic
        }

        return ResponseEntity.ok(mapToResponse(updated));
    }

    private ServiceBookingResponse mapToResponse(ServiceBooking booking) {
        return ServiceBookingResponse.builder()
                .id(booking.getId())
                .serviceId(booking.getService().getId())
                .serviceName(booking.getService().getServiceName())
                .apartmentId(booking.getApartment().getId())
                .apartmentCode(booking.getApartment().getApartmentCode())
                .startTime(booking.getStartTime())
                .endTime(booking.getEndTime())
                .quantity(booking.getQuantity())
            .totalPrice(booking.getTotalPrice())
                .note(booking.getNote())
                .status(booking.getStatus())
                .build();
    }

    @Data
    public static class BookingRequest {
        private Long serviceId;
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private Integer quantity;
        private String note;
    }
}