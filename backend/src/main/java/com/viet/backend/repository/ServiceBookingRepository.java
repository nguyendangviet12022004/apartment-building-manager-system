package com.viet.backend.repository;

import com.viet.backend.model.ServiceBooking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServiceBookingRepository extends JpaRepository<ServiceBooking, Long> {
    List<ServiceBooking> findByApartmentId(Long apartmentId);
    List<ServiceBooking> findByApartment_Resident_User_Id(Integer userId);
    List<ServiceBooking> findByServiceId(Long serviceId);
}