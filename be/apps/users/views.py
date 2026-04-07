import json
import logging
import random
from datetime import datetime, timedelta

import jwt
from django.core.cache import cache
from django.contrib.auth.hashers import check_password, make_password
from django.core.mail import send_mail
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.users.auth_tokens import create_access_token, create_refresh_token, decode_token
from apps.users.firebase_auth import verify_id_token as verify_firebase_id_token
from apps.users.models import User
from config import settings

# Configure logger
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)
SECRET_KEY = settings.SECRET_KEY

FORGOT_PASSWORD_SEND_OTP_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["phone"],
    properties={
        "phone": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

FORGOT_PASSWORD_RESET_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["phone", "otp", "new_password"],
    properties={
        "phone": openapi.Schema(type=openapi.TYPE_STRING),
        "otp": openapi.Schema(type=openapi.TYPE_STRING),
        "new_password": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

CHANGE_PASSWORD_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["old_password", "new_password"],
    properties={
        "old_password": openapi.Schema(type=openapi.TYPE_STRING),
        "new_password": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

SEND_OTP_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["email"],
    properties={
        "email": openapi.Schema(type=openapi.TYPE_STRING, format=openapi.FORMAT_EMAIL),
    },
)

VERIFY_OTP_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["email", "otp", "phone", "password"],
    properties={
        "email": openapi.Schema(type=openapi.TYPE_STRING, format=openapi.FORMAT_EMAIL),
        "otp": openapi.Schema(type=openapi.TYPE_STRING),
        "phone": openapi.Schema(type=openapi.TYPE_STRING),
        "password": openapi.Schema(type=openapi.TYPE_STRING),
        "full_name": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

FACEBOOK_LOGIN_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["uid", "displayName", "photoURL"],
    properties={
        "uid": openapi.Schema(type=openapi.TYPE_STRING),
        "displayName": openapi.Schema(type=openapi.TYPE_STRING),
        "photoURL": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

GOOGLE_LOGIN_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["token"],
    properties={
        "token": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

FORM_REGISTER_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["full_name", "email", "phone", "password"],
    properties={
        "full_name": openapi.Schema(type=openapi.TYPE_STRING),
        "email": openapi.Schema(type=openapi.TYPE_STRING, format=openapi.FORMAT_EMAIL),
        "phone": openapi.Schema(type=openapi.TYPE_STRING),
        "password": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

FORM_LOGIN_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["email_or_phone", "password"],
    properties={
        "email_or_phone": openapi.Schema(type=openapi.TYPE_STRING),
        "id": openapi.Schema(type=openapi.TYPE_STRING, description="Deprecated: use email_or_phone"),
        "password": openapi.Schema(type=openapi.TYPE_STRING),
    },
)

REFRESH_TOKEN_BODY = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    required=["refresh_token"],
    properties={
        "refresh_token": openapi.Schema(type=openapi.TYPE_STRING),
    },
)


def _upsert_user_by_uid(uid, defaults):
    user = User.objects(uid=uid).first()
    created = user is None

    if created:
        user = User(uid=uid)

    for field, value in defaults.items():
        setattr(user, field, value)

    user.save()
    return user, created


def _hash_password(raw_password):
    return make_password(raw_password)


def _normalize_email(value):
    if value is None:
        return None
    normalized = str(value).strip()
    return normalized or None


def _verify_and_upgrade_password(user, raw_password):
    stored_password = user.password_hash or ""

    if not stored_password:
        return False

    if check_password(raw_password, stored_password):
        return True

    # Backward compatibility: accept legacy plain-text passwords once,
    # then upgrade to hashed value.
    if stored_password == raw_password:
        user.password_hash = _hash_password(raw_password)
        user.save()
        return True

    return False


def _build_user_payload(user):
    return {
        "uid": user.uid,
        "full_name": user.full_name,
        "email": user.email,
        "phone": user.phone,
        "avatar": user.avatar,
    }


def _issue_token_pair(user):
    return {
        "access_token": create_access_token(user),
        "refresh_token": create_refresh_token(user),
    }

@swagger_auto_schema(method='post', request_body=FORGOT_PASSWORD_SEND_OTP_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password_send_otp(request):
    try:
        data = request.data
        phone = data.get("phone")

        if not phone:
            return Response({"error": "Số điện thoại không được để trống"}, status=400)

        try:
            user = User.objects.get(phone=phone)
        except User.DoesNotExist:
            return Response({"error": "Không tìm thấy người dùng với số điện thoại này"}, status=404)

        otp_code = str(random.randint(100000, 999999))
        cache.set(f"otp_reset:{phone}", otp_code, timeout=300)  # 5 phút

        # Gửi OTP: demo bằng log
        logger.info(f"OTP đặt lại mật khẩu cho {phone} là {otp_code}")

        # Thực tế nên tích hợp SMS API như Twilio/Viettel/VnTelecom ở đây

        return Response({"message": "Đã gửi mã OTP đến số điện thoại"})

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@swagger_auto_schema(method='post', request_body=FORGOT_PASSWORD_RESET_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password_reset(request):
    try:
        data = request.data
        phone = data.get("phone")
        otp = data.get("otp")
        new_password = data.get("new_password")

        if not phone or not otp or not new_password:
            return Response({"error": "Thiếu thông tin"}, status=400)

        cached_otp = cache.get(f"otp_reset:{phone}")
        if not cached_otp or cached_otp != otp:
            return Response({"error": "Mã OTP không hợp lệ hoặc đã hết hạn"}, status=400)

        try:
            user = User.objects.get(phone=phone)
        except User.DoesNotExist:
            return Response({"error": "Không tìm thấy người dùng"}, status=404)

        user.password_hash = _hash_password(new_password)
        user.save()
        cache.delete(f"otp_reset:{phone}")

        return Response({"message": "Đặt lại mật khẩu thành công"})

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@swagger_auto_schema(method='post', request_body=CHANGE_PASSWORD_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def change_password(request):
    try:
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return Response({"error": "Thiếu token hoặc định dạng sai"}, status=401)

        token = auth_header.split(" ")[1]
        try:
            decoded_token = decode_token(token, expected_type="access")
            user_id = decoded_token["user_id"]
        except jwt.ExpiredSignatureError:
            return Response({"error": "Token đã hết hạn"}, status=401)
        except jwt.InvalidTokenError:
            return Response({"error": "Token không hợp lệ"}, status=401)

        old_password = request.data.get("old_password", "").strip()
        new_password = request.data.get("new_password", "").strip()

        if not old_password or not new_password:
            return Response({"error": "Thiếu mật khẩu cũ hoặc mới"}, status=400)

        # Tìm user trong database
        try:
            user = User.objects.get(uid=user_id)
        except User.DoesNotExist:
            return Response({"error": "Không tìm thấy người dùng"}, status=404)

        # Kiểm tra mật khẩu cũ
        if not _verify_and_upgrade_password(user, old_password):
            return Response({"error": "Mật khẩu cũ không đúng"}, status=401)

        # Cập nhật mật khẩu mới
        user.password_hash = _hash_password(new_password)
        user.save()

        return Response({"message": "Đổi mật khẩu thành công"})

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@swagger_auto_schema(method='post', request_body=SEND_OTP_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def send_otp(request):
    try:
        email = request.data.get("email")

        if not email:
            return Response({"error": "Email không hợp lệ"}, status=400)

        otp_code = str(random.randint(100000, 999999))

        # Lưu OTP vào cache, hết hạn sau 5 phút
        cache.set(f"otp:{email}", otp_code, timeout=300)

        # Gửi email
        send_mail(
            subject="Mã xác thực OTP",
            message=f"Mã OTP của bạn là: {otp_code}",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )

        return Response({"message": "OTP đã được gửi tới email"})

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@swagger_auto_schema(method='post', request_body=VERIFY_OTP_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    try:
        data = request.data
        email = data.get("email")
        otp = data.get("otp")
        phone = data.get("phone")
        password = data.get("password")
        full_name = data.get("full_name", "")

        if not email or not otp or not phone or not password:
            return Response({"error": "Thiếu thông tin"}, status=400)

        cached_otp = cache.get(f"otp:{email}")

        if cached_otp and cached_otp == otp:
            cache.delete(f"otp:{email}")  # Xóa OTP sau khi dùng

            if User.objects.filter(email=email).first() is not None:
                return Response({"error": "Email đã tồn tại"}, status=409)
            if User.objects.filter(phone=phone).first() is not None:
                return Response({"error": "Số điện thoại đã tồn tại"}, status=409)

            uid = f"user_{int(datetime.utcnow().timestamp())}"
            current_timestamp = int(datetime.utcnow().timestamp())

            user = User.objects.create(
                uid=uid,
                full_name=full_name,
                email=email,
                phone=phone,
                password_hash=_hash_password(password),
                avatar="",
                fingerprint="",
                created_at=current_timestamp,
                last_sign_in_time=current_timestamp,
            )
            token_pair = _issue_token_pair(user)

            return Response({
                "message": "Xác minh OTP và đăng ký thành công",
                **token_pair,
                "user": _build_user_payload(user),
            })
        else:
            return Response({"success": False, "error": "Mã OTP không đúng hoặc đã hết hạn"}, status=400)

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@swagger_auto_schema(method='post', request_body=FACEBOOK_LOGIN_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def facebook_login(request):
    try:
        data = request.data
        uid = data.get("uid")
        full_name = data.get("displayName", "")
        avatar = data.get("photoURL", "")

        if not uid or not full_name or not avatar:
            return Response({"error": "Missing user data"}, status=400)

        # Chuyển đổi datetime thành timestamp (số nguyên)
        current_timestamp = int(datetime.utcnow().timestamp())

        # Lưu vào MongoDB (MongoEngine không có update_or_create)
        user, created = _upsert_user_by_uid(
            uid=uid,
            defaults={
                "full_name": full_name,
                "avatar": avatar,
                "email": None,
                "phone": "",
                "password_hash": "",
                "fingerprint": "",
                "created_at": current_timestamp,  # Dùng timestamp thay vì datetime
                "last_sign_in_time": current_timestamp,
            },
        )
        token_pair = _issue_token_pair(user)

        return Response({
            "message": "Facebook user authenticated successfully",
            **token_pair,
            "user": {
                "uid": user.uid,
                "full_name": user.full_name,
                "avatar": user.avatar,
            }
        }, status=200)

    except Exception as e:
        return Response({"error": str(e)}, status=400)

@swagger_auto_schema(method='post', request_body=GOOGLE_LOGIN_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    try:
        data = request.data
        firebase_id_token = data.get("token")

        # Xác thực token với Firebase
        decoded_token = verify_firebase_id_token(firebase_id_token)
        uid = decoded_token["uid"]
        email = _normalize_email(decoded_token.get("email"))
        full_name = decoded_token.get("name")
        avatar = decoded_token.get("picture")
        metadata = decoded_token.get("firebase", {}).get("sign_in_attributes", {})

        # Tạo hoặc cập nhật user trong MongoDB (MongoEngine không có update_or_create)
        user, created = _upsert_user_by_uid(
            uid=uid,
            defaults={
                "full_name": full_name,
                "email": email,
                "phone": "",
                "avatar": avatar,
                "password_hash": "",
                "fingerprint": "",
                "created_at": metadata.get("createdAt", 0),
                "last_sign_in_time": metadata.get("lastLoginAt", 0),
            },
        )
        token_pair = _issue_token_pair(user)

        return Response({
            "message": "User authenticated successfully",
            **token_pair,
            "user": _build_user_payload(user),
        }, status=200)

    except Exception as e:
        return Response({"error": str(e)}, status=400)

@swagger_auto_schema(method='post', request_body=FORM_REGISTER_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def form_register(request):
    try:
        data = request.data
        full_name = data.get("full_name", "")
        email = data.get("email", "")
        phone = data.get("phone", "")
        password = data.get("password", "")

        if not email or not phone or not password:
            return Response({"error": "Thiếu thông tin đăng ký"}, status=400)

        if User.objects.filter(email=email).first() is not None:
            return Response({"error": "Email đã được sử dụng"}, status=409)
        if User.objects.filter(phone=phone).first() is not None:
            return Response({"error": "Số điện thoại đã được sử dụng"}, status=409)

        uid = f"user_{int(datetime.utcnow().timestamp())}"

        current_timestamp = int(datetime.utcnow().timestamp())

        user = User.objects.create(
            uid=uid,
            full_name=full_name,
            email=email,
            phone=phone,
            password_hash=_hash_password(password),
            avatar="",
            fingerprint="",
            created_at=current_timestamp,
            last_sign_in_time=current_timestamp,
        )
        token_pair = _issue_token_pair(user)

        return Response({
            "message": "Đăng ký thành công",
            **token_pair,
            "user": _build_user_payload(user),
        })

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@swagger_auto_schema(method='post', request_body=FORM_LOGIN_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def form_login(request):
    try:
        data = request.data
        email_or_phone = data.get("email_or_phone") or data.get("id")
        password = data.get("password")

        if not email_or_phone or not password:
            return Response({"error": "Thiếu thông tin đăng nhập"}, status=400)

        # Tìm user bằng email hoặc SĐT
        try:
            user = User.objects.get(email=email_or_phone)
        except User.DoesNotExist:
            try:
                user = User.objects.get(phone=email_or_phone)
            except User.DoesNotExist:
                return Response({"error": "Không tìm thấy người dùng"}, status=404)

        # So sánh password (giả định đang lưu plain text hoặc hash đã biết)
        if not _verify_and_upgrade_password(user, password):
            return Response({"error": "Sai mật khẩu"}, status=401)
        token_pair = _issue_token_pair(user)

        return Response({
            "message": "Đăng nhập thành công",
            **token_pair,
            "user": _build_user_payload(user),
        })

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_token(request):
    try:
        auth_header = request.headers.get("Authorization", "")

        if auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
            try:
                decoded_token = decode_token(token, expected_type="access")
                user = User.objects.get(uid=decoded_token["user_id"])
                return Response({
                    "message": "Google User authenticated",
                    "user": _build_user_payload(user),
                })
            except jwt.ExpiredSignatureError:
                return Response({"error": "Token expired"}, status=401)
            except jwt.InvalidTokenError:
                return Response({"error": "Invalid token"}, status=401)

        elif auth_header.startswith("Facebook "):
            fb_uid = auth_header.split(" ")[1]
            try:
                decoded_token = decode_token(fb_uid, expected_type="access")
                user = User.objects.get(uid=decoded_token["user_id"])
                return Response({
                    "message": "Facebook User authenticated",
                    "user": _build_user_payload(user),
                })
            except jwt.ExpiredSignatureError:
                return Response({"error": "Token expired"}, status=401)
            except jwt.InvalidTokenError:
                return Response({"error": "Invalid token"}, status=401)

        return Response({"error": "Invalid request"}, status=400)

    except Exception as e:
        logger.error(f"Error in verify_token: {str(e)}")
        return Response({"error": str(e)}, status=500)


@swagger_auto_schema(method='post', request_body=REFRESH_TOKEN_BODY)
@api_view(['POST'])
@permission_classes([AllowAny])
def refresh_token(request):
    try:
        refresh_token_value = request.data.get("refresh_token", "").strip()
        if not refresh_token_value:
            return Response({"error": "Thiếu refresh token"}, status=400)

        try:
            decoded_token = decode_token(refresh_token_value, expected_type="refresh")
        except jwt.ExpiredSignatureError:
            return Response({"error": "Refresh token đã hết hạn"}, status=401)
        except jwt.InvalidTokenError:
            return Response({"error": "Refresh token không hợp lệ"}, status=401)

        user_id = decoded_token.get("user_id")
        if not user_id:
            return Response({"error": "Refresh token không hợp lệ"}, status=401)

        try:
            user = User.objects.get(uid=user_id)
        except User.DoesNotExist:
            return Response({"error": "Không tìm thấy người dùng"}, status=404)

        token_pair = _issue_token_pair(user)
        return Response({
            "message": "Làm mới token thành công",
            **token_pair,
            "user": _build_user_payload(user),
        })

    except Exception as e:
        return Response({"error": str(e)}, status=500)
