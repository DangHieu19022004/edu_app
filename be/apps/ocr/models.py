import uuid

from mongoengine import (BooleanField, DateField, Document, EmbeddedDocument,
                         EmbeddedDocumentListField, FloatField, IntField,
                         StringField)


# --- Bảng Students ---
class StudentInfo(Document):
    student_id = StringField(required=True, unique=True, default=lambda: str(uuid.uuid4()), max_length=36)
    name = StringField(required=True, max_length=100)
    dob = StringField(default='', max_length=20)
    gender = StringField(default='Nam', max_length=10)  # Nam, Nữ, Khác
    school = StringField(default='', max_length=255)
    birthplace = StringField(default='', max_length=100)
    ethnicity = StringField(default='Kinh', max_length=50)
    address = StringField(default='')
    phone = StringField(default='', max_length=20)
    father_name = StringField(default='', max_length=100)
    father_job = StringField(default='', max_length=100)
    mother_name = StringField(default='', max_length=100)
    mother_job = StringField(default='', max_length=100)
    guardian_name = StringField(default='', max_length=100)
    guardian_job = StringField(default='', max_length=100)
    class_id = StringField(default='', max_length=36)  # Liên kết với bảng Classes
    parents_email = StringField(default='', max_length=100)

    meta = {
        "collection": "student_info",
        "indexes": ["student_id", "class_id", "parents_email"],
    }

    def __str__(self):
        return self.name

# --- Bảng ReportCards ---
class ReportCard(Document):
    student_id = StringField(required=True, max_length=36)  # FK -> Students
    class_id = StringField(default='', max_length=36)

    school_year = StringField(required=True, max_length=50)

    # Hạnh kiểm từng năm
    conduct_year1_sem1 = StringField(default='', max_length=20)
    conduct_year1_sem2 = StringField(default='', max_length=20)
    conduct_year1_final = StringField(default='', max_length=20)
    conduct_year2_sem1 = StringField(default='', max_length=20)
    conduct_year2_sem2 = StringField(default='', max_length=20)
    conduct_year2_final = StringField(default='', max_length=20)
    conduct_year3_sem1 = StringField(default='', max_length=20)
    conduct_year3_sem2 = StringField(default='', max_length=20)
    conduct_year3_final = StringField(default='', max_length=20)

    # Điểm trung bình từng năm
    gpa_avg_year1 = FloatField(default=0)
    gpa_avg_year2 = FloatField(default=0)
    gpa_avg_year3 = FloatField(default=0)

    # Học lực từng năm
    academic_perform_year1 = StringField(default='', max_length=20)
    academic_perform_year2 = StringField(default='', max_length=20)
    academic_perform_year3 = StringField(default='', max_length=20)

    # Thông tin khác
    promotion_status = StringField(default='', max_length=20)  # Lên lớp, Thi lại, Lưu ban
    teacher_comment = StringField(default='')
    teacher_signed = BooleanField(default=False)
    principal_signed = BooleanField(default=False)
    approval_date = DateField(null=True)
    user_id = StringField(required=True, max_length=100)

    meta = {
        "collection": "report_cards",
        "indexes": ["student_id", "class_id", "school_year", "user_id"],
    }

    def __str__(self):
        return f"ReportCard of {self.student_id} ({self.school_year})"

# --- Bảng ReportCard_Subject ---
class Subject(EmbeddedDocument):
    name = StringField(required=True, max_length=100)
    year = IntField(required=True)  # 1 = lớp 10, 2 = lớp 11, 3 = lớp 12
    # Store subject scores as string to support both numeric scores and pass/fail text.
    year1_sem1_score = StringField(default='', max_length=20)
    year1_sem2_score = StringField(default='', max_length=20)
    year1_final_score = StringField(default='', max_length=20)
    year2_sem1_score = StringField(default='', max_length=20)
    year2_sem2_score = StringField(default='', max_length=20)
    year2_final_score = StringField(default='', max_length=20)
    year3_sem1_score = StringField(default='', max_length=20)
    year3_sem2_score = StringField(default='', max_length=20)
    year3_final_score = StringField(default='', max_length=20)


class ReportCardSubject(Document):
    report_card_id = StringField(required=True, max_length=36)  # FK -> ReportCard
    subjects = EmbeddedDocumentListField(Subject, default=list)

    meta = {
        "collection": "report_card_subjects",
        "indexes": ["report_card_id"],
    }

    def __str__(self):
        return f"Subjects of {self.report_card_id}"
