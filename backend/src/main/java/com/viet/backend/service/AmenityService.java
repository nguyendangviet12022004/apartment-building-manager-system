package com.viet.backend.service;

import com.viet.backend.model.Amenity;
import com.viet.backend.repository.AmenityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AmenityService {

    private final AmenityRepository amenityRepository;

    public List<Amenity> getAllAmenities(boolean onlyAvailable) {
        if (onlyAvailable) {
            return amenityRepository.findByIsAvailableTrue();
        }
        return amenityRepository.findAll();
    }

    public Amenity getById(Integer id) {
        return amenityRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Amenity not found: " + id));
    }

    @Transactional
    public Amenity create(Amenity amenity) {
        return amenityRepository.save(amenity);
    }

    @Transactional
    public Amenity update(Integer id, Amenity request) {
        Amenity amenity = getById(id);
        amenity.setName(request.getName());
        amenity.setType(request.getType());
        amenity.setDescription(request.getDescription());
        amenity.setPricePerDuration(request.getPricePerDuration());
        amenity.setPricingType(request.getPricingType());
        amenity.setCapacity(request.getCapacity());
        amenity.setRequiresBooking(request.isRequiresBooking());
        amenity.setAvailable(request.isAvailable());
        amenity.setOpenTime(request.getOpenTime());
        amenity.setCloseTime(request.getCloseTime());
        return amenityRepository.save(amenity);
    }

    @Transactional
    public void delete(Integer id) {
        Amenity amenity = getById(id);
        // Soft delete logic usually preferred, but hard delete for now
        // Or just set available = false
        amenity.setAvailable(false);
        amenityRepository.save(amenity);
    }
}