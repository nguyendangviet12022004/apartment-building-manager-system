# Dummy Data Seeder cho Apartment Building System

Tập lệnh `seed_all_data.ps1` được tạo ra để tự động nạp lượng lớn dữ liệu giả lập (mock data) đầy đủ cho hệ thống **Apartment Building Manager System** thông qua các RESTful APIs của Spring Boot Backend. Quá trình chia thành 7 bước và đảm bảo các validation rules của Backend (như form `BR-01` code căn hộ) hoạt động mượt mà.

## Yêu cầu trước khi chạy
1. Đảm bảo ứng dụng **Spring Boot Backend** của bạn đang chạy ở địa chỉ: `http://localhost:8080`.
2. Dữ liệu này dùng `POST/PATCH` thẳng vào API, nên Database của bạn cũng phải chạy bình thường.

## Tự động gửi những dữ liệu sau
1. **Khởi tạo Super Admin:** (`superadmin_master@example.com` / `Password1!`).  
2. **Đăng ký Cư dân (Residents):** `johndoe_seed@example.com`, `janesmith_seed@example.com`...  
3. **Tạo Toà nhà (Blocks):** 2 Blocks mẫu (`SDA`, `SDB`).  
4. **Tạo Căn hộ (Apartments):** Tạo ra các phòng có định dạng `[BlockCode]-0101-A1B` tương ứng số tầng 1,2,3... liên kết với các Block tìm thấy (Pass validation `BR-01`).  
5. **Gửi File yêu cầu (Resident Requests):** Các khiếu nại của cư dân cùng với trạng thái đã được Admin xác nhận (Set Timeline, Status = Approved).  
6. **Tạo Dịch vụ (Services):** Quản lý, Điện, Nước, Phí gửi xe (với loại `METERED` hoặc `FIXED`).  
7. **Tạo Hoá đơn (Invoices):** Tự động phát sinh hóa đơn **Đã Thanh Toán (PAID)** tháng trước và hóa đơn **Chưa Thanh Toán (UNPAID)** số nước/điện tháng này cho **TẤT CẢ** các căn hộ có trong hệ thống hiện tại.

---

## Cách chạy Script (Dành cho Windows)

1. Mở thư mục gốc của dự án chứa file `seed_all_data.ps1`.
   *(VD: `d:\FPT\8\PRM\Project\apartment-building-manager-system`)*
2. Có thể bật Terminal trực tiếp bằng Visual Studio Code, thay vì dùng `cmd`, hãy chọn `PowerShell`.  
3. Chạy lệnh sau trong PowerShell để thi hành script:
```powershell
powershell -ExecutionPolicy Bypass -File .\seed_all_data.ps1
```

Script sẽ tự động vượt qua các lỗi Validation Conflict (nếu dữ liệu đã tồn tại sẵn) để chèn tiếp vào các dữ liệu còn thiếu. Bạn có thể thoải mái chạy lại file này bao nhiêu lần tuỳ ý để làm đầy form UI trên Flutter.
