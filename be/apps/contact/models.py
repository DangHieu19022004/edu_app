# --- Bảng Parents ---
import uuid
from datetime import datetime

from mongoengine import DateTimeField, Document, StringField

class Parent(Document):
    parent_id = StringField(required=True, unique=True, default=lambda: str(uuid.uuid4()), max_length=36)
    student_id = StringField(required=True, max_length=36)  # Liên kết với StudentInfo.student_id
    teacher_id = StringField(required=True, max_length=36)

    full_name = StringField(required=True, max_length=100)
    email = StringField(required=True, max_length=100)
    phone = StringField(required=True, max_length=20)
    created_at = DateTimeField(default=datetime.utcnow)

    meta = {
        "collection": "parents",
        "indexes": ["parent_id", "student_id", "teacher_id", "email"],
    }

    def __str__(self):
        return f"{self.full_name} - {self.email} - {self.phone}"

class EmailSchedule(Document):

    subject = StringField(required=True, max_length=255)
    recipients = StringField(required=True)  # nhiều email, cách nhau bởi dấu phẩy
    message = StringField(required=True)

    scheduled_date = DateTimeField(required=True)
    status = StringField(
        max_length=20,
        choices=[('pending', 'Pending'), ('sent', 'Sent')],
        default='pending'
    )

    teacher_id = StringField(required=True, max_length=36)  # để lọc email theo giáo viên
    created_at = DateTimeField(default=datetime.utcnow)

    meta = {
        "collection": "email_schedules",
        "indexes": ["teacher_id", "scheduled_date", "status"],
    }

    def __str__(self):
        return f"{self.subject} -> {self.recipients} ({self.status})"
