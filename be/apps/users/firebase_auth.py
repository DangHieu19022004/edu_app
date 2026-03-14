import os
from pathlib import Path

import firebase_admin
from firebase_admin import auth, credentials


def _get_credentials_path() -> Path:
    env_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
    if env_path:
        candidate = Path(env_path).expanduser()
        if not candidate.is_absolute():
            candidate = Path(__file__).resolve().parents[2] / candidate
        return candidate

    return Path(__file__).resolve().parents[2] / "config" / "eduteacher-19063-firebase-adminsdk-fbsvc-4a469228b4.json"


def _ensure_initialized() -> None:
    if firebase_admin._apps:
        return

    cred_path = _get_credentials_path()
    if not cred_path.exists():
        raise FileNotFoundError(f"Firebase credentials file not found: {cred_path}")

    cred = credentials.Certificate(str(cred_path))
    firebase_admin.initialize_app(cred)


def verify_id_token(id_token: str) -> dict:
    _ensure_initialized()
    return auth.verify_id_token(id_token)
