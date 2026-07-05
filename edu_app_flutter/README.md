# Hướng Dẫn Dự Án EduSmart

## 1. Giới thiệu

`EduSmart` là một ứng dụng Flutter dành cho môi trường giáo dục, sử dụng Firebase cho xác thực và lưu trữ phiên đăng nhập. Ứng dụng khởi động từ `lib/main.dart`, tải biến môi trường từ `.env`, khởi tạo Firebase, khôi phục phiên đăng nhập và điều hướng vào màn hình splash.

## 2. Yêu Cầu Cài Đặt

- Flutter SDK tương thích với Dart `^3.8.1`
- Android Studio hoặc VS Code kèm Flutter/Dart extension
- Xcode nếu chạy trên iOS/macOS
- Firebase project đã cấu hình cho Android/iOS nếu dùng các chức năng đăng nhập

## 3. Cấu Hình Trước Khi Chạy

1. Cài dependencies:

```bash
flutter pub get
```

2. Kiểm tra file `.env` ở thư mục gốc nếu dự án có dùng API base URL hoặc biến cấu hình khác. File này được khai báo trong `pubspec.yaml` nên phải tồn tại nếu ứng dụng cần đọc giá trị từ đó.

3. Kiểm tra cấu hình Firebase:
- Android: file `android/app/google-services.json`
- iOS: cấu hình Firebase tương ứng trong project Xcode

4. Nếu thay đổi icon ứng dụng, package `flutter_launcher_icons` đã được cấu hình sẵn trong `pubspec.yaml`.

## 4. Cách Chạy Dự Án

### Chạy trên thiết bị / emulator mặc định

```bash
flutter run
```

### Chạy trên Android emulator hoặc máy thật

```bash
flutter devices
flutter run -d <device_id>
```

### Chạy trên web

```bash
flutter run -d chrome
```

### Build release

Android:

```bash
flutter build apk
```

Web:

```bash
flutter build web
```

iOS:

```bash
flutter build ios
```

## 5. Điểm Khởi Động Ứng Dụng

Luồng khởi động chính nằm trong [`lib/main.dart`](lib/main.dart). Tại đây ứng dụng:

- tải `.env`
- khởi tạo Firebase
- cấu hình `AuthSession`
- khôi phục trạng thái đăng nhập
- mở [`SplashScreen`](lib/views/screens/splash_screen.dart)

## 6. Cấu Trúc Thư Mục

### Thư mục gốc

- [`android/`](android/): mã nguồn Android, Gradle, cấu hình Firebase Android
- [`ios/`](ios/): mã nguồn iOS, Xcode project, plist và plugin registrant
- [`web/`](web/): cấu hình chạy web, `index.html`, `manifest.json`, icon
- [`linux/`](linux/), [`macos/`](macos/), [`windows/`](windows/): cấu hình desktop
- [`test/`](test/): test tự động
- [`lib/`](lib/): mã nguồn Flutter chính
- [`build/`](build/): artefact sinh ra khi build, không chỉnh sửa thủ công

### Bên trong `lib/`

- [`lib/main.dart`](lib/main.dart): entry point của app
- [`lib/constants/`](lib/constants/): hằng số giao diện, API, spacing, màu sắc, text
- [`lib/controllers/`](lib/controllers/): logic điều khiển luồng đăng nhập/đăng ký
- [`lib/models/`](lib/models/): các model dữ liệu như session user, form, chatbot, OCR
- [`lib/services/`](lib/services/): tầng gọi API, auth, lưu phiên, OCR, chatbot, contact, classroom
- [`lib/views/screens/`](lib/views/screens/): các màn hình chính của ứng dụng
- [`lib/views/widgets/`](lib/views/widgets/): widget tái sử dụng cho UI
- [`lib/assets/`](lib/assets/): hình ảnh, icon, tài nguyên tĩnh của app

## 7. Các Chức Năng Chính

- Đăng nhập/đăng ký bằng email và mật khẩu
- Đăng nhập Google/Facebook
- Lưu phiên đăng nhập bằng secure storage
- OCR và xử lý bảng điểm
- Chatbot / hỗ trợ tương tác
- Quản lý lớp học, liên hệ phụ huynh, báo cáo học tập, thống kê

## 8. Ghi Chú Khi Phát Triển

- Không sửa trực tiếp các file trong `build/`
- Nếu thêm asset mới, nhớ khai báo lại trong `pubspec.yaml`
- Nếu thêm biến môi trường mới, cập nhật `.env` và phần đọc cấu hình tương ứng
- Khi thay đổi luồng auth, cần kiểm tra lại `AuthSession` và màn `SplashScreen` để tránh lỗi trạng thái đăng nhập

## 9. Gợi Ý Kiểm Tra Nhanh

- Chạy `flutter analyze` để kiểm tra lỗi tĩnh
- Chạy `flutter test` để kiểm tra test cơ bản
- Chạy app trên ít nhất một thiết bị Android trước khi phát hành
