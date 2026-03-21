package com.viet.backend.repository;

import com.viet.backend.model.ServiceBooking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ServiceBookingRepository extends JpaRepository<ServiceBooking, Long> {
    List<ServiceBooking> findByApartmentId(Long apartmentId);
    List<ServiceBooking> findByApartment_Resident_User_Id(Integer userId);
    List<ServiceBooking> findByServiceId(Long serviceId);

    // Tìm các booking đã confirm có khoảng thời gian trùng với khoảng [start, end]
    @Query("SELECT b FROM ServiceBooking b WHERE b.service.id = :serviceId AND (b.status = 'CONFIRMED' OR b.status = 'PENDING') " +
           "AND (b.startTime < :endTime AND b.endTime > :startTime)")
    List<ServiceBooking> findConflictingBookings(@Param("serviceId") Long serviceId, 
                                                 @Param("startTime") LocalDateTime startTime, 
                                                 @Param("endTime") LocalDateTime endTime);
                                                 
    // Lấy booking trong ngày để hiển thị lịch biểu
    // Logic: Tìm các booking có thời gian giao nhau với ngày [startOfDay, endOfDay]
    @Query("SELECT b FROM ServiceBooking b WHERE b.service.id = :serviceId AND (b.status = 'CONFIRMED' OR b.status = 'PENDING') " +
           "AND (b.startTime < :endOfDay AND b.endTime > :startOfDay) ORDER BY b.startTime ASC")
    List<ServiceBooking> findConfirmedByDate(@Param("serviceId") Long serviceId,
                                             @Param("startOfDay") LocalDateTime startOfDay,
                                             @Param("endOfDay") LocalDateTime endOfDay);
}