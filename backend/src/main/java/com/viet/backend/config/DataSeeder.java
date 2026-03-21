package com.viet.backend.config;

import com.viet.backend.model.Service;
import com.viet.backend.model.Service.ServiceType;
import com.viet.backend.repository.ServiceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final ServiceRepository serviceRepository;
    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        // Tự động update schema ENUM cho MySQL để tránh lỗi khi insert loại PARKING
        try {
            jdbcTemplate.execute("ALTER TABLE services MODIFY service_type ENUM('METERED','FIXED','PARKING','AMENITY') NOT NULL");
        } catch (Exception e) {
            System.out.println(">> DataSeeder: Skipped schema update (Error or not MySQL: " + e.getMessage() + ")");
        }

        // Seed thêm nếu dữ liệu còn ít (< 25 service) hoặc để update lại type cho đúng
        if (serviceRepository.count() < 25) {
            seedServices();
        }
    }

    private void seedServices() {
        List<Service> seeds = new ArrayList<>();

        // 1. METERED (Điện, Nước - Đo đếm theo chỉ số)
        seeds.add(build("Electricity", "kWh", "3500", "Tiền điện sinh hoạt", ServiceType.METERED));
        seeds.add(build("Water Usage", "m3", "18000", "Tiền nước sạch", ServiceType.METERED));

        // 2. FIXED (Phí cố định hàng tháng)
        seeds.add(build("Management Fee", "Month", "500000", "Phí quản lý vận hành tòa nhà", ServiceType.FIXED));
        seeds.add(build("Trash Collection", "Month", "30000", "Phí thu gom rác thải", ServiceType.FIXED));
        seeds.add(build("Internet Package A", "Month", "220000", "Internet tốc độ cao 100Mbps", ServiceType.FIXED));
        seeds.add(build("Internet Package B", "Month", "350000", "Internet siêu tốc 300Mbps", ServiceType.FIXED));
        seeds.add(build("Cable TV", "Month", "110000", "Truyền hình cáp HD", ServiceType.FIXED));

        // 3. PARKING (Gửi xe - Tính theo slot/tháng)
        seeds.add(build("Car Parking Slot", "Slot", "1200000", "Chỗ đậu xe ô tô định danh", ServiceType.PARKING));
        seeds.add(build("Motorbike Parking", "Slot", "120000", "Chỗ đậu xe máy", ServiceType.PARKING));
        seeds.add(build("Bicycle Parking", "Slot", "50000", "Chỗ đậu xe đạp", ServiceType.PARKING));

        // 4. AMENITY (Tiện ích đặt chỗ - Tính theo lượt/giờ)
        seeds.add(build("Tennis Court", "Hour", "150000", "Sân Tennis tiêu chuẩn", ServiceType.AMENITY));
        seeds.add(build("BBQ Area", "Session", "300000", "Khu vực nướng BBQ sân thượng (4h)", ServiceType.AMENITY));
        seeds.add(build("Swimming Pool", "Visit", "50000", "Vé bơi cho khách vãng lai", ServiceType.AMENITY));
        seeds.add(build("Gym Day Pass", "Day", "80000", "Vé phòng Gym theo ngày", ServiceType.AMENITY));
        seeds.add(build("Yoga Studio", "Hour", "100000", "Phòng tập Yoga riêng", ServiceType.AMENITY));
        seeds.add(build("Karaoke Room M", "Hour", "120000", "Phòng Karaoke 5-10 người", ServiceType.AMENITY));
        seeds.add(build("Karaoke Room L", "Hour", "200000", "Phòng Karaoke 10-20 người", ServiceType.AMENITY));
        seeds.add(build("Community Hall", "Hour", "250000", "Phòng sinh hoạt cộng đồng", ServiceType.AMENITY));
        seeds.add(build("Cleaning Service", "Hour", "80000", "Dịch vụ dọn dẹp căn hộ", ServiceType.AMENITY));
        seeds.add(build("Laundry Service", "Basket", "60000", "Giặt sấy (tối đa 5kg)", ServiceType.AMENITY));
        seeds.add(build("Printing Service", "Page", "2000", "In ấn tài liệu tại sảnh", ServiceType.AMENITY));

        // Lưu hoặc cập nhật
        List<Service> existingServices = serviceRepository.findAll();

        for (Service s : seeds) {
            Optional<Service> existing = existingServices.stream()
                    .filter(db -> db.getServiceName().equalsIgnoreCase(s.getServiceName()))
                    .findFirst();

            if (existing.isPresent()) {
                // Update type và giá nếu đã có (để fix data cũ bị sai type)
                Service dbService = existing.get();
                dbService.setServiceType(s.getServiceType());
                dbService.setUnit(s.getUnit());
                dbService.setUnitPrice(s.getUnitPrice());
                dbService.setMetered(s.isMetered());
                dbService.setCapacity(s.getCapacity());
                serviceRepository.save(dbService);
            } else {
                serviceRepository.save(s);
            }
        }
        System.out.println(">> DataSeeder: Updated/Seeded services. Total count: " + serviceRepository.count());
    }

    private Service build(String name, String unit, String price, String desc, ServiceType type) {
        return Service.builder()
                .serviceName(name)
                .unit(unit)
                .unitPrice(new BigDecimal(price))
                .description(desc)
                .serviceType(type)
                .metered(type == ServiceType.METERED)
                .active(true)
                .capacity(10)
                .build();
    }
}