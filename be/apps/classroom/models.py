import uuid
from mongoengine import Document, StringField


class Class(Document):
    id = StringField(primary_key=True, default=lambda: str(uuid.uuid4()), max_length=36)
    name = StringField(required=True, max_length=100)  # VD: 10A1
    teacher_id = StringField(required=True, max_length=100)  # Liên kết đến bảng Teachers
    school_name = StringField(required=True, max_length=255)
    class_year = StringField(required=True, max_length=50)  # VD: K64, 2022-2025

    meta = {
        "collection": "classes",
        "indexes": ["teacher_id", "class_year", "school_name"],
    }

    def __str__(self):
        return f"{self.name} - {self.class_year}"
