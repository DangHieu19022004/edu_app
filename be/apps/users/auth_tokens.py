import os
from datetime import datetime, timedelta

import jwt
from django.conf import settings

JWT_ALGORITHM = "HS256"
JWT_ACCESS_TOKEN_EXPIRES_HOURS = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRES_HOURS", 24))


def create_access_token(user) -> str:
    now = datetime.utcnow()
    payload = {
        "sub": user.uid,
        "email": user.email,
        "full_name": user.full_name,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(hours=JWT_ACCESS_TOKEN_EXPIRES_HOURS),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=JWT_ALGORITHM)
