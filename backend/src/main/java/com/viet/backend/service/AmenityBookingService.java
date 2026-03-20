package com.viet.backend.service;

import com.viet.backend.dto.AmenityDTO;
import com.viet.backend.model.Amenity;
import com.viet.backend.model.AmenityBooking;
import com.viet.backend.model.User;
import com.viet.backend.repository.AmenityBookingRepository;
import com.viet.backend.repository.AmenityRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AmenityBookingService {

    private final AmenityBookingRepository bookingRepository;
    private final AmenityRepository amenityRepository;
    private final UserRepository userRepository;

    @Transactional
    public AmenityBooking createBooking(AmenityDTO.BookingRequest request) {
        Amenity amenity = amenityRepository.findById(request.getAmenityId())
                .orElseThrow(() -> new RuntimeException("Amenity not found"));

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!amenity.isAvailable()) {
            throw new RuntimeException("This amenity is currently unavailable");
        }

        if (request.getStartTime().isAfter(request.getEndTime())) {
            throw new RuntimeException("Start time must be before end time");
        }
        
        if (request.getStartTime().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Cannot book amenities in the past");
        }

        // Check open hours if defined
        if (amenity.getOpenTime() != null && amenity.getCloseTime() != null) {
             // Simple check: logic could be more complex for overnight bookings
             // Here we assume single day usage or just check against open/close
        }

        // Check overlap
        boolean isOverlap = bookingRepository.existsByAmenityIdAndOverlap(
                amenity.getId(), request.getStartTime(), request.getEndTime());
        
        if (isOverlap) {
            throw new RuntimeException("The selected time slot is already booked.");
        }

        // Calculate Price
        BigDecimal totalPrice = BigDecimal.ZERO;
        BigDecimal unitPrice = amenity.getPricePerDuration();

        if (unitPrice != null && unitPrice.compareTo(BigDecimal.ZERO) > 0) {
            Amenity.PricingType type = amenity.getPricingType() != null ? amenity.getPricingType() : Amenity.PricingType.PER_HOUR;
            long minutes = Duration.between(request.getStartTime(), request.getEndTime()).toMinutes();
            
            switch (type) {
                case PER_HOUR:
                    BigDecimal hours = BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(60), 2, java.math.RoundingMode.HALF_UP);
                    totalPrice = unitPrice.multiply(hours);
                    break;
                case PER_DAY:
                    // 1 day = 1440 minutes
                    BigDecimal days = BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(1440), 2, java.math.RoundingMode.HALF_UP);
                    totalPrice = unitPrice.multiply(days);
                    break;
                case PER_MONTH:
                    // Assume 30 days = 43200 minutes
                    BigDecimal months = BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(43200), 2, java.math.RoundingMode.HALF_UP);
                    totalPrice = unitPrice.multiply(months);
                    break;
                case FREE:
                default:
                    totalPrice = BigDecimal.ZERO;
            }
        }

        AmenityBooking booking = AmenityBooking.builder()
                .user(user)
                .amenity(amenity)
                .startTime(request.getStartTime())
                .endTime(request.getEndTime())
                .status(AmenityBooking.BookingStatus.BOOKED)
                .totalPrice(totalPrice)
                .isPaid(totalPrice.compareTo(BigDecimal.ZERO) == 0) // Auto paid if free
                .note(request.getNote())
                .build();

        return bookingRepository.save(booking);
    }

    public List<AmenityBooking> getBookingsByUser(Integer userId) {
        return bookingRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
    
    public List<AmenityBooking> getAllBookings() {
        return bookingRepository.findAll();
    }

    @Transactional
    public AmenityBooking updateStatus(Integer bookingId, AmenityBooking.BookingStatus status) {
        AmenityBooking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        
        booking.setStatus(status);
        return bookingRepository.save(booking);
    }

    public AmenityDTO.BookingResponse toDTO(AmenityBooking b) {
        String userName = (b.getUser() != null) 
                ? b.getUser().getFirstname() + " " + b.getUser().getLastname() 
                : "Unknown";
        
        return AmenityDTO.BookingResponse.builder()
                .id(b.getId())
                .amenityId(b.getAmenity().getId())
                .amenityName(b.getAmenity().getName())
                .userId(b.getUser().getId())
                .userName(userName)
                .startTime(b.getStartTime())
                .endTime(b.getEndTime())
                .status(b.getStatus())
                .totalPrice(b.getTotalPrice())
                .isPaid(b.isPaid())
                .note(b.getNote())
                .createdAt(b.getCreatedAt())
                .build();
    }
}