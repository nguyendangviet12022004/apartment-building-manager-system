# Chi Tiết Dữ Liệu Chạy Mặc Định (Mock Data Seeder)

Mỗi khi bạn khởi động Backend trên một Database trắng, `DataSeeder.java` sẽ tự động đổ vào toàn bộ lượng dữ liệu dưới đây. Tất cả đều đã vượt qua chuẩn Validate của API.

## 1. Tài Khoản Quản Trị (Admin Account)
Được cấp phát bởi quá trình khởi tạo Hệ thống:
- **Email:** `admin@example.com`
- **Mật khẩu (Raw):** `admin123`
- **Role:** Administrator
- **Công dụng:** Dùng để đăng nhập vào Web/App Dashboard của Ban quản trị.

---

## 2. Toà Nhà (Blocks)
Gồm 3 Block lớn đại diện cho các khu chung cư:
1. **VIN** - Vinhomes Grand Park
2. **BXX** - Premium Block X
3. **BYY** - Studio Block Y

---

## 3. Căn Hộ (Apartments)
Tổng cộng: **45 Căn hộ**. (Mỗi Block có 5 tầng, mỗi tầng 3 phòng: Căn góc C, góc B và phòng giữa C).
Dựa trên form thiết kế chuẩn (VD: `[BlockCode]-[FloorNum][FloorNum]-A[Floor][RoomLetter]`):
- **Block VIN (15 phòng):** `VIN-0101-A1C`, `VIN-0101-A1B`, `VIN-0202-A2C`, `VIN-0505-A5B`...
- **Block BXX (15 phòng):** `BXX-0101-A1C`, `BXX-0303-A3B`...
- **Block BYY (15 phòng):** `BYY-0404-A4C`, `BYY-0505-A5B`...

**Đặc điểm Diện tích:** Tự động trải dài từ `65.5m2`, `81.0m2` lên tới `96.5m2`.

---

## 4. Cư Dân (Residents / Users)
Hệ thống tự động sinh 15 Cư dân (User) khác nhau và đưa luôn vào trạng thái **OCCUPIED** ở 15 Căn hộ đầu tiên của hệ thống (Toàn bộ cư dân này ở toà `VIN`).

| STT | Họ & Tên | Email (Dùng để Đăng nhập) | Mật khẩu chung | CCCD / ID Card | SĐT Khẩn |
|-----|-------------------|--------------------------|----------------|----------------|-----------|
| 1   | John Doe | `john_doe@example.com` | `Password123!` | 000088889999 | 0912345670|
| 2   | Jane Smith | `jane_smith@example.com` | `Password123!` | 000188889999 | 0912345671|
| 3   | Alice Johnson | `alice_johnson@example.com` | `Password123!` | 000288889999 | 0912345672|
| 4   | Bob Brown | `bob_brown@example.com` | `Password123!` | 000388889999 | 0912345673|
| 5   | Charlie Davis | `charlie_davis@example.com` | `Password123!` | 000488889999 | 0912345674|
| 6   | David Miller | `david_miller@example.com` | `Password123!` | 000588889999 | 0912345675|
| 7   | Eva Wilson | `eva_wilson@example.com` | `Password123!` | 000688889999 | 0912345676|
| 8   | Frank Moore | `frank_moore@example.com` | `Password123!` | 000788889999 | 0912345677|
| 9   | Grace Taylor | `grace_taylor@example.com` | `Password123!` | 000888889999 | 0912345678|
| 10  | Henry Anderson | `henry_anderson@example.com` | `Password123!` | 000988889999 | 0912345679|
| 11  | Ivy Thomas | `ivy_thomas@example.com` | `Password123!` | 0001088889999 | 09123456710|
| 12  | Jack Jackson | `jack_jackson@example.com` | `Password123!` | 0001188889999 | 09123456711|
| 13  | Kathy White | `kathy_white@example.com` | `Password123!` | 0001288889999 | 09123456712|
| 14  | Leo Harris | `leo_harris@example.com` | `Password123!` | 0001388889999 | 09123456713|
| 15  | Mia Martin | `mia_martin@example.com` | `Password123!` | 0001488889999 | 09123456714|

Lưu ý: Mật khẩu `Password123!` của Residents khi vào Database đều đã được Spring Security băm (Hash) an toàn bằng chuỗi BCrypt (VD: `$2a$10$Xb7/O...`). Nhưng ở phía Flutter bạn chỉ cần điền chuỗi Text thô trên.

---

## 5. Dịch Vụ Đặc Điểm (Services & Amenities)
Khởi tạo ngay **21 dịch vụ** từ Gửi xe, Internet, Truyền hình, Quản lý phí đến:
- `Tennis Court` (150.000đ/H)
- `BBQ Area` (300.000đ/Lượt)
- `Swimming Pool` (50.000đ/Vé)
- `Gym Day Pass`, `Yoga Studio`, `Karaoke Room M/L`, và `Community Hall`.

Hầu hết các "Amenity" đều có Opening Time lúc `06:00` và Closing Time lúc `22:00`. Sức chứa (Capacity) tối đa từ `10` -> `50`.

---

## 6. Đơn Đặt Chỗ (Service Bookings)
Hệ thống duyệt qua danh sách 15 Residents ở trên và sinh ra tự động **30 Đơn đặt chỗ (Bookings)** (Tương ứng 2 Bookings/Người). 
- Các Booking được xáo trộn xoay vòng giữa các Amenity hiện có. (Có người đặt Tennis, có người dùng Bể Bơi, nướng BBQ...).
- **Lịch trình (Timeline):** Được băm rải đều theo chuỗi ngày bắt đầu từ ngày hôm sau cho tới 15 ngày tiếp theo, xoay quanh các ca `10:00 Sáng` và `14:00 Chiều`, thời lượng mỗi ca là **2 Tiếng/Lượt**.
- **Tiền mặt (Total Price):** Backend đã tự động tính sẵn và cộng Total Price lưu vào trong DB.
- Trạng thái chung: `PENDING`.
