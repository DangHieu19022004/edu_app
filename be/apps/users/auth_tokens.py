import os
from datetime import datetime, timedelta

import jwt
from django.conf import settings

JWT_ALGORITHM = "HS256"
JWT_ACCESS_TOKEN_EXPIRES_HOURS = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRES_HOURS", 24))
JWT_REFRESH_TOKEN_EXPIRES_DAYS = int(os.getenv("JWT_REFRESH_TOKEN_EXPIRES_DAYS", 30))


def _build_payload(user, token_type: str, expires_delta: timedelta) -> dict:
    now = datetime.utcnow()
    return {
        "user_id": user.uid,
        "email": user.email,
        "full_name": user.full_name,
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
    }


def create_access_token(user) -> str:
    payload = _build_payload(
        user=user,
        token_type="access",
        expires_delta=timedelta(hours=JWT_ACCESS_TOKEN_EXPIRES_HOURS),
    )
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=JWT_ALGORITHM)


def create_refresh_token(user) -> str:
    payload = _build_payload(
        user=user,
        token_type="refresh",
        expires_delta=timedelta(days=JWT_REFRESH_TOKEN_EXPIRES_DAYS),
    )
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_token(token: str, expected_type: str | None = None) -> dict:
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[JWT_ALGORITHM])
    token_type = payload.get("type")
    if expected_type == "access":
        if token_type not in (None, "access"):
            raise jwt.InvalidTokenError("Invalid token type")
    elif expected_type and token_type != expected_type:
        raise jwt.InvalidTokenError("Invalid token type")
    return payload
