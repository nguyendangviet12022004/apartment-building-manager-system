# Cloudinary Setup Guide

## Bước 1: Tạo Cloudinary Account

1. Truy cập https://cloudinary.com/
2. Đăng ký tài khoản miễn phí
3. Xác nhận email

## Bước 2: Lấy thông tin cấu hình

1. Đăng nhập vào Cloudinary Dashboard
2. Vào **Settings** → **Upload**
3. Tìm phần **Upload presets**
4. Click **Add upload preset**
5. Cấu hình:
   - **Preset name**: `apartment_profiles`
   - **Signing mode**: `Unsigned`
   - **Folder**: `profiles`
   - **Allowed formats**: `jpg, png, jpeg`
   - **Max file size**: `5 MB`
   - Click **Save**

## Bước 3: Cập nhật cấu hình

### Backend (application.yaml)
```yaml
cloudinary:
  cloud-name: ${CLOUDINARY_CLOUD_NAME:your_cloud_name}
  api-key: ${CLOUDINARY_API_KEY:your_api_key}
  api-secret: ${CLOUDINARY_API_SECRET:your_api_secret}
```

### Frontend (cloudinary_service.dart)
```dart
static const String cloudName = 'your_cloud_name';
static const String uploadPreset = 'apartment_profiles';
```

## Bước 4: Test Upload

1. Chạy Flutter app
2. Vào Profile → Edit Profile
3. Click vào avatar → Choose from Gallery
4. Chọn ảnh và Save Changes
5. Kiểm tra ảnh đã upload trên Cloudinary Dashboard

## Lưu ý

- Upload preset phải là **Unsigned** để Flutter có thể upload trực tiếp
- Nếu gặp lỗi CORS, enable CORS trong Cloudinary Settings
- Free tier có giới hạn 25 GB storage và 25 GB bandwidth/tháng
