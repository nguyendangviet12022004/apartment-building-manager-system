package com.viet.backend.controller;

import com.viet.backend.dto.AmenityDTO;
import com.viet.backend.model.Amenity;
import com.viet.backend.model.AmenityBooking;
import com.viet.backend.service.AmenityBookingService;
import com.viet.backend.service.AmenityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/amenities")
@RequiredArgsConstructor
public class AmenityController {

    private final AmenityService amenityService;
    private final AmenityBookingService bookingService;

    // ────────────────────────────────────────────────────
    // AMENITY ENDPOINTS (CRUD)
    // ────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<List<Amenity>> getAll(@RequestParam(defaultValue = "false") boolean onlyAvailable) {
        return ResponseEntity.ok(amenityService.getAllAmenities(onlyAvailable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Amenity> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(amenityService.getById(id));
    }

    @PostMapping
    public ResponseEntity<Amenity> create(@RequestBody Amenity amenity) {
        return ResponseEntity.ok(amenityService.create(amenity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Amenity> update(@PathVariable Integer id, @RequestBody Amenity amenity) {
        return ResponseEntity.ok(amenityService.update(id, amenity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        amenityService.delete(id);
        return ResponseEntity.ok().build();
    }

    // ────────────────────────────────────────────────────
    // BOOKING ENDPOINTS
    // ────────────────────────────────────────────────────

    @PostMapping("/bookings")
    public ResponseEntity<AmenityDTO.BookingResponse> createBooking(@RequestBody AmenityDTO.BookingRequest request) {
        AmenityBooking booking = bookingService.createBooking(request);
        return ResponseEntity.ok(bookingService.toDTO(booking));
    }

    @GetMapping("/bookings/user/{userId}")
    public ResponseEntity<List<AmenityDTO.BookingResponse>> getUserBookings(@PathVariable Integer userId) {
        List<AmenityBooking> bookings = bookingService.getBookingsByUser(userId);
        return ResponseEntity.ok(bookings.stream()
                .map(bookingService::toDTO)
                .collect(Collectors.toList()));
    }

    @GetMapping("/bookings/all")
    public ResponseEntity<List<AmenityDTO.BookingResponse>> getAllBookings() {
        return ResponseEntity.ok(bookingService.getAllBookings().stream()
                .map(bookingService::toDTO)
                .collect(Collectors.toList()));
    }

    @PatchMapping("/bookings/{id}/status")
    public ResponseEntity<AmenityDTO.BookingResponse> updateBookingStatus(
            @PathVariable Integer id,
            @RequestBody AmenityDTO.StatusUpdate request) {
        AmenityBooking booking = bookingService.updateStatus(id, request.getStatus());
        return ResponseEntity.ok(bookingService.toDTO(booking));
    }
}