# EduSmart

EduSmart là ứng dụng hỗ trợ hoạt động học tập và quản lý thông tin giáo dục. Dự án được tổ chức theo mô hình client–server, gồm ứng dụng Flutter đa nền tảng và REST API xây dựng bằng Django.

## Chức năng chính

- Đăng ký, đăng nhập và quản lý phiên người dùng.
- Đăng nhập qua Google/Facebook và tích hợp Firebase Authentication.
- Quản lý lớp học, học sinh và thông tin liên hệ phụ huynh.
- Quét, nhận diện và xử lý bảng điểm bằng OCR.
- Theo dõi báo cáo học tập, thống kê và hồ sơ người dùng.
- Chatbot hỗ trợ tương tác trong ứng dụng.

## Cấu trúc dự án

```text
edu_app/
├── edu_app_flutter/    # Frontend Flutter: Android, iOS, Web và Desktop
├── be/                 # Backend Django REST Framework
└── README.md           # Tài liệu tổng quan này
```

## Công nghệ sử dụng

| Thành phần | Công nghệ |
| --- | --- |
| Frontend | Flutter, Dart |
| Backend | Python, Django, Django REST Framework |
| Xác thực | Firebase Authentication |
| Cơ sở dữ liệu | SQLite (Django) và MongoDB (MongoEngine) |
| OCR / AI | PaddleOCR, Gemini và dịch vụ hiệu chỉnh OCR |
| Chatbot | Dịch vụ Dify qua REST API |

## Yêu cầu môi trường

- Flutter SDK tương thích Dart `^3.8.1`.
- Python 3.8 trở lên và `pip`.
- MongoDB đang chạy nếu sử dụng các chức năng lưu trữ MongoEngine.
- Firebase project đã được cấu hình nếu sử dụng xác thực Firebase.

## Chạy dự án ở môi trường phát triển

### 1. Backend

```powershell
cd be
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
python manage.py migrate
python manage.py runserver
```

Backend mặc định chạy tại `http://127.0.0.1:8000`.

- Admin: `http://127.0.0.1:8000/admin/`
- Health check: `http://127.0.0.1:8000/api/health/`

### 2. Frontend

```powershell
cd edu_app_flutter
flutter pub get
flutter run
```

Để chạy web:

```powershell
flutter run -d chrome
```

Cấu hình URL API trong `edu_app_flutter/.env` bằng biến `API_BASE_URL`, ví dụ khi chạy Android emulator:

```env
API_BASE_URL=http://10.0.2.2:8000
```

## Cấu hình biến môi trường

- `be/.env`: cấu hình Django, MongoDB, Firebase, email, Dify, Gemini và các dịch vụ Backend khác. Khởi tạo từ `be/.env.example`.
- `edu_app_flutter/.env`: cấu hình `API_BASE_URL` cho ứng dụng Flutter.

## Kiểm tra nhanh

```powershell
# Backend
cd be
python manage.py test

# Frontend
cd edu_app_flutter
flutter analyze
flutter test
```
