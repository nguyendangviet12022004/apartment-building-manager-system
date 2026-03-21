package com.viet.backend.controller;

import com.viet.backend.model.*;
import com.viet.backend.repository.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
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

    @PostMapping
    public ResponseEntity<?> createBooking(@RequestBody BookingRequest req, @RequestHeader("X-User-ID") Integer userId) {
        // 1. Validate Service
        Service service = serviceRepository.findById(req.serviceId)
                .orElseThrow(() -> new RuntimeException("Service not found"));

        if (service.getServiceType() != Service.ServiceType.AMENITY) {
            return ResponseEntity.badRequest().body("Only AMENITY services can be booked via this API.");
        }

        // 2. Validate Apartment (Resident)
        Apartment apartment = apartmentRepository.findByResidentUserId(userId)
                .orElseThrow(() -> new RuntimeException("No apartment associated with this user"));

        // 3. Create Booking
        ServiceBooking booking = ServiceBooking.builder()
                .service(service)
                .apartment(apartment)
                .startTime(req.startTime)
                .endTime(req.endTime)
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
        private String note;
    }
}