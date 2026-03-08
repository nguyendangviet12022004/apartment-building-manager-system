package com.viet.backend.controller;

import com.viet.backend.model.Service;
import com.viet.backend.repository.ServiceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/services")
@RequiredArgsConstructor
public class ServiceController {

    private final ServiceRepository serviceRepository;

    // GET /api/v1/services — lấy danh sách active services (cho dropdown khi tạo invoice)
    @GetMapping
    public List<Service> getActiveServices() {
        return serviceRepository.findByActiveTrue();
    }

    // GET /api/v1/services/all — tất cả kể cả inactive (admin)
    @GetMapping("/all")
    public List<Service> getAllServices() {
        return serviceRepository.findAll();
    }

    @PostMapping
    public Service create(@RequestBody Service service) {
        return serviceRepository.save(service);
    }

    @PutMapping("/{id}")
    public Service update(@PathVariable Long id, @RequestBody Service req) {
        Service svc = serviceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service not found: " + id));
        svc.setServiceName(req.getServiceName());
        svc.setUnit(req.getUnit());
        svc.setUnitPrice(req.getUnitPrice());
        svc.setDescription(req.getDescription());
        svc.setServiceType(req.getServiceType());
        svc.setMetered(req.isMetered());
        svc.setActive(req.isActive());
        return serviceRepository.save(svc);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        Service svc = serviceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service not found: " + id));
        svc.setActive(false); // soft delete
        serviceRepository.save(svc);
        return ResponseEntity.ok().build();
    }
}