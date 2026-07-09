import uuid
from datetime import datetime

from mongoengine import Document, EmailField, IntField, StringField


class User(Document):
	uid = StringField(required=True, unique=True, default=lambda: str(uuid.uuid4()))
	full_name = StringField(required=True, max_length=255)
	email = EmailField(unique=True, sparse=True)
	phone = StringField(max_length=20)
	avatar = StringField()
	password_hash = StringField(required=True)
	fingerprint = StringField(max_length=500)
	role = StringField(default="user")
	created_at = IntField(default=lambda: int(datetime.now().timestamp()))
	last_sign_in_time = IntField(default=lambda: int(datetime.now().timestamp()))

	meta = {
		"collection": "users",
		"indexes": ["uid", "email", "phone", "role"],
	}
