package com.viet.backend.controller;

import com.viet.backend.model.*;
import com.viet.backend.repository.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
public class ServiceBookingController {

    private final ServiceBookingRepository bookingRepository;
    private final ServiceRepository serviceRepository;
    private final ApartmentRepository apartmentRepository;

    @GetMapping("/my")
    public ResponseEntity<List<ServiceBooking>> getMyBookings(@RequestHeader("X-User-ID") Integer userId) {
        return ResponseEntity.ok(bookingRepository.findByApartment_Resident_User_Id(userId));
    }

    // API lấy lịch đã đặt trong ngày để hiển thị cho user
    @GetMapping("/schedule")
    public ResponseEntity<List<ServiceBooking>> getSchedule(
            @RequestParam Long serviceId,
            @RequestParam String date) { // date format: 2023-10-27
        
        LocalDateTime startOfDay = java.time.LocalDate.parse(date).atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);

        return ResponseEntity.ok(bookingRepository.findConfirmedByDate(serviceId, startOfDay, endOfDay));
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

        // 2. Validate Availability (Capacity Check)
        List<ServiceBooking> conflicts = bookingRepository.findConflictingBookings(req.serviceId, req.startTime, req.endTime);
        
        int currentUsage = conflicts.stream().mapToInt(ServiceBooking::getQuantity).sum();
        int requestedQty = req.quantity != null ? req.quantity : 1;

        if (currentUsage + requestedQty > service.getCapacity()) {
            int remaining = Math.max(0, service.getCapacity() - currentUsage);
            return ResponseEntity.badRequest().body("Không thể đặt chỗ: Chỉ còn " + remaining + " chỗ trống trong khung giờ này.");
        }

        // 3. Validate Apartment (Resident)
        Apartment apartment = apartmentRepository.findByResidentUserId(userId)
                .orElseThrow(() -> new RuntimeException("No apartment associated with this user"));

        // 4. Create Booking
        ServiceBooking booking = ServiceBooking.builder()
                .service(service)
                .apartment(apartment)
                .startTime(req.startTime)
                .endTime(req.endTime)
                .quantity(requestedQty)
                .note(req.note)
                .status(ServiceBooking.BookingStatus.PENDING) // Mặc định chờ duyệt hoặc Confirm luôn tùy logic
                .build();

        return ResponseEntity.ok(bookingRepository.save(booking));
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