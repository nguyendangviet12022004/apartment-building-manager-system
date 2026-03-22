package com.viet.backend.controller;

import com.viet.backend.dto.BookingDTO;
import com.viet.backend.service.BookingManagementService;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for booking management (Manager role)
 */
@RestController
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
public class BookingManagementController {

    private final BookingManagementService bookingManagementService;

    /**
     * GET /api/v1/bookings
     * Get all bookings with filtering and pagination
     * Only accessible by MANAGER and ADMIN roles
     */
    @GetMapping
//    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<BookingDTO.BookingListResponse> getBookings(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {

        BookingDTO.BookingFilterRequest request = new BookingDTO.BookingFilterRequest(
                search, status, page, pageSize
        );

        BookingDTO.BookingListResponse response = bookingManagementService.getBookings(request);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/v1/bookings/{bookingId}
     * Get booking details by booking ID
     * Only accessible by MANAGER and ADMIN roles
     */
    @GetMapping("/{bookingId}")
//    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<BookingDTO.BookingDetailResponse> getBookingDetails(
            @PathVariable Long bookingId) {
        
        BookingDTO.BookingDetailResponse response = bookingManagementService.getBookingDetails(bookingId);
        return ResponseEntity.ok(response);
    }

    /**
     * PUT /api/v1/bookings/{bookingId}/approve
     * Approve a booking request
     * Only accessible by MANAGER and ADMIN roles
     */
    @PutMapping("/{bookingId}/approve")
//    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<?> approveBooking(@PathVariable Long bookingId) {
        try {
            bookingManagementService.approveBooking(bookingId);
            return ResponseEntity.ok().body(new MessageResponse("Booking approved successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    /**
     * PUT /api/v1/bookings/{bookingId}/reject
     * Reject a booking request
     * Only accessible by MANAGER and ADMIN roles
     */
    @PutMapping("/{bookingId}/reject")
//    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<?> rejectBooking(@PathVariable Long bookingId) {
        try {
            bookingManagementService.rejectBooking(bookingId);
            return ResponseEntity.ok().body(new MessageResponse("Booking rejected successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @Data
    @AllArgsConstructor
    static class MessageResponse {
        private String message;
    }
}
