from datetime import datetime

from mongoengine import Document, IntField, StringField


class ChatbotRateLimit(Document):
    user_id = StringField(required=True, unique=True)
    short_term_count = IntField(default=0)
    short_term_window_start = IntField(default=0)
    medium_term_count = IntField(default=0)
    medium_term_window_start = IntField(default=0)
    blocked_until = IntField(default=0)
    created_at = IntField(default=lambda: int(datetime.now().timestamp()))
    updated_at = IntField(default=lambda: int(datetime.now().timestamp()))

    meta = {
        "collection": "chatbot_rate_limits",
        "indexes": ["user_id", "blocked_until"],
    }


class ChatbotSpamLog(Document):
    user_id = StringField(required=True)
    action = StringField(required=True)
    message_count = IntField(default=0)
    window = StringField(default="")
    created_at = IntField(default=lambda: int(datetime.now().timestamp()))

    meta = {
        "collection": "chatbot_spam_logs",
        "indexes": ["user_id", "action", "created_at"],
    }
