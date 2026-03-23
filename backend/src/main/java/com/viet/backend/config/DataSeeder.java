package com.viet.backend.config;

import com.viet.backend.model.*;
import com.viet.backend.model.Service.ServiceType;
import com.viet.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final ServiceRepository serviceRepository;
    private final JdbcTemplate jdbcTemplate;
    
    private final BlockRepository blockRepository;
    private final ApartmentRepository apartmentRepository;
    private final UserRepository userRepository;
    private final ResidentRepository residentRepository;
    private final ServiceBookingRepository serviceBookingRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        try {
            jdbcTemplate.execute("ALTER TABLE services MODIFY service_type ENUM('METERED','FIXED','PARKING','AMENITY') NOT NULL");
        } catch (Exception e) {
            System.out.println(">> DataSeeder: Skipped schema update (Error or not MySQL: " + e.getMessage() + ")");
        }

        seedServices();
        seedAdvancedData();
    }

    private void seedAdvancedData() {
        if (userRepository.count() > 2) {
            System.out.println(">> DataSeeder: Advanced Data already seeded. Skipping.");
            return;
        }

        System.out.println(">> DataSeeder: Generating Massive Test Data...");

        // 1. Blocks
        String[] blockCodes = {"VIN", "BXX", "BYY"};
        String[] blockDescs = {"Vinhomes Grand Park", "Premium Block X", "Studio Block Y"};
        List<Block> blocks = new ArrayList<>();
        
        for (int i = 0; i < 3; i++) {
            final String bc = blockCodes[i];
            Optional<Block> optBlock = blockRepository.findAll().stream().filter(b -> b.getBlockCode().equals(bc)).findFirst();
            Block block;
            if (optBlock.isPresent()) {
                block = optBlock.get();
            } else {
                try {
                    block = blockRepository.save(Block.builder().blockCode(bc).description(blockDescs[i]).build());
                } catch(Exception e) {
                    block = blockRepository.findAll().stream().filter(b -> b.getBlockCode().equals(bc)).findFirst().get();
                }
            }
            blocks.add(block);
        }

        // 2. Apartments (5 floors, 3 per floor = 15 per block = 45 total)
        List<Apartment> apartments = new ArrayList<>();
        for (Block b : blocks) {
            for (int f = 1; f <= 5; f++) {
                for (int r = 1; r <= 3; r++) {
                    String floorStr = String.format("%02d", f);
                    String unitStr = String.format("%02d", r);
                    String ac = String.format("%s-%s-%s", b.getBlockCode(), floorStr, unitStr);
                    
                    final int flr = f;
                    Optional<Apartment> optApt = apartmentRepository.findAll().stream().filter(a -> a.getApartmentCode().equals(ac)).findFirst();
                    Apartment apt;
                    if (optApt.isPresent()) {
                        apt = optApt.get();
                    } else {
                        try {
                            apt = apartmentRepository.save(Apartment.builder()
                                .apartmentCode(ac)
                                .floor(flr)
                                .area(50.0 + (r * 15.5))
                                .status("AVAILABLE")
                                .block(b)
                                .build());
                        } catch(Exception e) {
                            apt = apartmentRepository.findAll().stream().filter(a -> a.getApartmentCode().equals(ac)).findFirst().get();
                        }
                    }
                    apartments.add(apt);
                }
            }
        }

        // 3. Residents & Users (Let's create 15 distinct residents)
        String[] firstNames = {"John", "Jane", "Alice", "Bob", "Charlie", "David", "Eva", "Frank", "Grace", "Henry", "Ivy", "Jack", "Kathy", "Leo", "Mia"};
        String[] lastNames = {"Doe", "Smith", "Johnson", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin"};
        List<Resident> residents = new ArrayList<>();
        
        for (int i = 0; i < 15; i++) {
            String email = firstNames[i].toLowerCase() + "_" + lastNames[i].toLowerCase() + "@example.com";
            
            final String e = email;
            Optional<User> optUser = userRepository.findByEmail(e);
            User user;
            if (optUser.isPresent()) {
                user = optUser.get();
            } else {
                user = userRepository.save(User.builder()
                    .firstname(firstNames[i])
                    .lastname(lastNames[i])
                    .email(e)
                    .password(passwordEncoder.encode("Password123!"))
                    .role(Role.RESIDENT)
                    .build());
            }

            final Integer uid = user.getId();
            Optional<Resident> optResident = residentRepository.findByUserId(uid);
            Resident resident;
            if (optResident.isPresent()) {
                resident = optResident.get();
            } else {
                resident = residentRepository.save(Resident.builder()
                    .user(user)
                    .identityCard("000" + i + "88889999")
                    .emergencyContact("091234567" + i)
                    .build());
            }
            
            // Assign one unique apartment per resident
            Apartment assignApt = apartments.get(i);
            assignApt.setResident(resident);
            assignApt.setUsed(true);
            assignApt.setStatus("OCCUPIED");
            apartmentRepository.save(assignApt);
            
            residents.add(resident);
        }

        // 4. Bookings for AMENITIES
        List<Service> amenities = serviceRepository.findAll().stream()
            .filter(s -> s.getServiceType() == ServiceType.AMENITY)
            .toList();
            
        if (!amenities.isEmpty()) {
            System.out.println(">> DataSeeder: Generating Service Bookings...");
            int dayOffset = 1;
            for (int i = 0; i < residents.size(); i++) {
                Resident r = residents.get(i);
                Apartment apt = apartments.get(i);
                
                // Generate 2 random bookings per resident
                for (int b = 0; b < 2; b++) {
                    int svcIndex = (r.getId().intValue() + b) % amenities.size();
                    Service svc = amenities.get(svcIndex);
                    
                    LocalDateTime start = LocalDateTime.now().plusDays(dayOffset).withHour(10 + b * 4).withMinute(0);
                    LocalDateTime end = start.plusHours(2);
                    
                    ServiceBooking booking = ServiceBooking.builder()
                        .service(svc)
                        .apartment(apt)
                        .startTime(start)
                        .endTime(end)
                        .quantity(1 + (b % 2))
                        .note((b == 0 ? "Morning" : "Afternoon") + " session booking - System Seeded")
                        .totalPrice(svc.getUnitPrice().multiply(new BigDecimal(1 + (b % 2))))
                        .status(ServiceBooking.BookingStatus.PENDING)
                        .build();
                    serviceBookingRepository.save(booking);
                }
                dayOffset++;
            }
        }
        
        System.out.println(">> DataSeeder: Massive data generation completed successfully!");
    }

    private void seedServices() {
        List<Service> seeds = new ArrayList<>();

        seeds.add(build("Electricity", "kWh", "3500", "Tiền điện sinh hoạt", ServiceType.METERED, null, null));
        seeds.add(build("Water Usage", "m3", "18000", "Tiền nước sạch", ServiceType.METERED, null, null));
        seeds.add(build("Management Fee", "Month", "500000", "Phí quản lý vận hành tòa nhà", ServiceType.FIXED, null, null));
        seeds.add(build("Trash Collection", "Month", "30000", "Phí thu gom rác thải", ServiceType.FIXED, null, null));
        seeds.add(build("Internet Package A", "Month", "220000", "Internet tốc độ cao 100Mbps", ServiceType.FIXED, null, null));
        seeds.add(build("Internet Package B", "Month", "350000", "Internet siêu tốc 300Mbps", ServiceType.FIXED, null, null));
        seeds.add(build("Cable TV", "Month", "110000", "Truyền hình cáp HD", ServiceType.FIXED, null, null));
        seeds.add(build("Car Parking Slot", "Slot", "1200000", "Chỗ đậu xe ô tô định danh", ServiceType.PARKING, null, null));
        seeds.add(build("Motorbike Parking", "Slot", "120000", "Chỗ đậu xe máy", ServiceType.PARKING, null, null));
        seeds.add(build("Bicycle Parking", "Slot", "50000", "Chỗ đậu xe đạp", ServiceType.PARKING, null, null));
        seeds.add(build("Tennis Court", "Hour", "150000", "Sân Tennis tiêu chuẩn", ServiceType.AMENITY, LocalTime.of(6, 0), LocalTime.of(22, 0)));
        seeds.add(build("BBQ Area", "Session", "300000", "Khu vực nướng BBQ sân thượng (4h)", ServiceType.AMENITY, LocalTime.of(9, 0), LocalTime.of(23, 0)));
        seeds.add(build("Swimming Pool", "Visit", "50000", "Vé bơi cho khách vãng lai", ServiceType.AMENITY, LocalTime.of(6, 0), LocalTime.of(20, 0)));
        seeds.add(build("Gym Day Pass", "Day", "80000", "Vé phòng Gym theo ngày", ServiceType.AMENITY, LocalTime.of(5, 0), LocalTime.of(22, 0)));
        seeds.add(build("Yoga Studio", "Hour", "100000", "Phòng tập Yoga riêng", ServiceType.AMENITY, LocalTime.of(6, 0), LocalTime.of(21, 0)));
        seeds.add(build("Karaoke Room M", "Hour", "120000", "Phòng Karaoke 5-10 người", ServiceType.AMENITY, LocalTime.of(10, 0), LocalTime.of(23, 0)));
        seeds.add(build("Karaoke Room L", "Hour", "200000", "Phòng Karaoke 10-20 người", ServiceType.AMENITY, LocalTime.of(10, 0), LocalTime.of(23, 0)));
        seeds.add(build("Community Hall", "Hour", "250000", "Phòng sinh hoạt cộng đồng", ServiceType.AMENITY, LocalTime.of(8, 0), LocalTime.of(22, 0)));
        seeds.add(build("Cleaning Service", "Hour", "80000", "Dịch vụ dọn dẹp căn hộ", ServiceType.AMENITY, LocalTime.of(8, 0), LocalTime.of(18, 0)));
        seeds.add(build("Laundry Service", "Basket", "60000", "Giặt sấy (tối đa 5kg)", ServiceType.AMENITY, LocalTime.of(7, 0), LocalTime.of(21, 0)));
        seeds.add(build("Printing Service", "Page", "2000", "In ấn tài liệu tại sảnh", ServiceType.AMENITY, LocalTime.of(8, 0), LocalTime.of(20, 0)));

        List<Service> existingServices = serviceRepository.findAll();

        for (Service s : seeds) {
            Optional<Service> existing = existingServices.stream()
                    .filter(db -> db.getServiceName().equalsIgnoreCase(s.getServiceName()))
                    .findFirst();

            if (existing.isPresent()) {
                Service dbService = existing.get();
                dbService.setServiceType(s.getServiceType());
                dbService.setUnit(s.getUnit());
                dbService.setUnitPrice(s.getUnitPrice());
                dbService.setMetered(s.isMetered());
                dbService.setCapacity(s.getCapacity());
                dbService.setOpeningTime(s.getOpeningTime());
                dbService.setClosingTime(s.getClosingTime());
                serviceRepository.save(dbService);
            } else {
                serviceRepository.save(s);
            }
        }
        System.out.println(">> DataSeeder: Updated/Seeded services. Total count: " + serviceRepository.count());
    }

    private Service build(String name, String unit, String price, String desc, ServiceType type, LocalTime open, LocalTime close) {
        return Service.builder()
                .serviceName(name)
                .unit(unit)
                .unitPrice(new BigDecimal(price))
                .description(desc)
                .serviceType(type)
                .metered(type == ServiceType.METERED)
                .active(true)
                .capacity(10)
                .openingTime(open)
                .closingTime(close)
                .build();
    }
}