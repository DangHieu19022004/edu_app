from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.http import JsonResponse
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
import os
import uuid
import cv2
import numpy as np
from ultralytics import YOLO
from paddleocr import PaddleOCR
import json
from django.conf import settings
import requests
from .models import StudentInfo, ReportCard, Subject, ReportCardSubject
from apps.users.models import User
import base64
import google.generativeai as genai
from PIL import Image
from apps.classroom.models import Class
import base64
import os, time
import traceback

BART_SERVER_URL = os.getenv("BART_SERVER_URL", "http://127.0.0.1:8001/correct")
OCR_APP_DIR = os.path.dirname(os.path.abspath(__file__))
YOLO_REPORT_CARD_WEIGHTS = os.path.join(OCR_APP_DIR, "runs", "detect", "train10", "weights", "best.pt")

yolo_model = YOLO(YOLO_REPORT_CARD_WEIGHTS)
OCR_DEVICE = os.getenv("OCR_DEVICE", "cpu")
# Try to disable extra doc preprocessing to keep OCR behavior closer to legacy flow.
try:
    ocr_model = PaddleOCR(
        lang='vi',
        device=OCR_DEVICE,
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
    )
except TypeError as e:
    print(f"⚠️ PaddleOCR init without doc preprocessing is not supported: {e}")
    ocr_model = PaddleOCR(lang='vi', device=OCR_DEVICE)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
# GEMINI_API_KEY =  ""

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel("models/gemini-2.5-flash")

CROPPED_ROOT_DIR = os.path.join(settings.MEDIA_ROOT, "cropped")

def cleanup_cropped_dir(base_dir, max_age_minutes=15):
    if not os.path.exists(base_dir):
        return

    now = time.time()
    for folder in os.listdir(base_dir):
        folder_path = os.path.join(base_dir, folder)
        if os.path.isdir(folder_path):
            if now - os.path.getmtime(folder_path) > max_age_minutes * 60:
                try:
                    for file in os.listdir(folder_path):
                        os.remove(os.path.join(folder_path, file))
                    os.rmdir(folder_path)
                    print(f"🧹 Đã xoá thư mục cũ: {folder_path}")
                except Exception as e:
                    print(f"⚠️ Không thể xoá {folder_path}: {e}")

def _subject_value(subject, field_name, default=None):
    if isinstance(subject, dict):
        return subject.get(field_name, default)
    return getattr(subject, field_name, default)


def _upsert_student_info(student_id, defaults):
    student = StudentInfo.objects(student_id=student_id).first()
    created = student is None

    if created:
        student = StudentInfo(student_id=student_id)

    for field, value in defaults.items():
        setattr(student, field, value)

    student.save()
    return student, created

#chuyển score sang float, nếu không hợp lệ thì trả về None
def _parse_score(value):
    if value is None:
        return None

    normalized = str(value).strip().replace(",", ".")
    if not normalized:
        return None

    try:
        score = float(normalized)
    except (TypeError, ValueError):
        return None

    if score < 0 or score > 10:
        return None
    return score

#chuyển score sang int nếu là số nguyên, hoặc float nếu có phần thập phân
def _format_score(value):
    if value is None:
        return 0
    rounded = round(value, 1)
    return int(rounded) if rounded.is_integer() else rounded

#chuyển GPA sang xếp loại học lực
def _academic_performance_from_gpa(gpa):
    if gpa is None or gpa <= 0:
        return ""
    if gpa >= 8:
        return "Giỏi"
    if gpa >= 6.5:
        return "Khá"
    if gpa >= 5:
        return "Trung bình"
    return "Yếu"

# tính điểm cuối năm của môn học, ưu tiên final_score, nếu không có thì lấy trung bình 2 học kỳ
def _subject_final_score(subject, year):
    final_score = _parse_score(_subject_value(subject, f"year{year}_final_score"))
    if final_score is not None:
        return final_score

    sem1_score = _parse_score(_subject_value(subject, f"year{year}_sem1_score"))
    sem2_score = _parse_score(_subject_value(subject, f"year{year}_sem2_score"))
    if sem1_score is not None and sem2_score is not None:
        return (sem1_score + sem2_score) / 2

    return sem1_score if sem1_score is not None else sem2_score

# Tính toán GPA trung bình và xếp loại học lực cho từng năm học dựa trên danh sách môn học
def _computed_report_card_defaults(subjects):
    defaults = {}

    for year in (1, 2, 3):
        summary_score = None
        scores = []

        for subject in subjects or []:
            subject_year = _subject_value(subject, "year")
            try:
                subject_year = int(subject_year)
            except (TypeError, ValueError):
                continue

            if subject_year != year:
                continue

            name = str(_subject_value(subject, "name", "") or "").strip().lower()
            final_score = _subject_final_score(subject, year)
            if final_score is None:
                continue

            if "dtb" in name or "trung bình" in name or "cac mon" in name or "các môn" in name:
                summary_score = final_score
                continue

            scores.append(final_score)

        gpa = summary_score
        if gpa is None and scores:
            gpa = sum(scores) / len(scores)

        defaults[f"gpa_avg_year{year}"] = _format_score(gpa)
        defaults[f"academic_perform_year{year}"] = _academic_performance_from_gpa(gpa)

    return defaults


@csrf_exempt
@require_http_methods(["GET"])
def get_all_student_data(request):
    try:
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return JsonResponse({'error': 'Thiếu Authorization'}, status=401)

        uid = auth_header.split(" ")[1]
        try:
            teacher = User.objects.get(uid=uid)
        except User.DoesNotExist:
            return JsonResponse({'error': 'Người dùng không tồn tại'}, status=404)

        all_data = []

        # Lấy tất cả lớp của giáo viên
        classes = Class.objects.filter(teacher_id=uid)
        for cls in classes:
            # Lấy tất cả học sinh trong lớp đó
            students = StudentInfo.objects.filter(class_id=cls.id)
            for student in students:
                student_entry = {
                    "student": {
                        "id": student.student_id,
                        "name": student.name,
                        "gender": student.gender or '',
                        "dob": str(student.dob) if student.dob else '',
                        "school": cls.school_name,
                        "class": cls.name,
                        "class_year": cls.class_year,
                    },
                    "report_card": {},
                    "subjects": []
                }

                # Lấy học bạ gần nhất
                report = ReportCard.objects.filter(student_id=student.student_id).order_by('-school_year').first()
                if report:
                    student_entry["report_card"] = {
                        "school_year": report.school_year,
                        "teacher_comment": report.teacher_comment or '',
                        "conduct": report.conduct_year3_final or '',
                        "gpa": {
                            "10": report.gpa_avg_year1,
                            "11": report.gpa_avg_year2,
                            "12": report.gpa_avg_year3
                        }
                    }

                    # Lấy danh sách điểm môn học từ ReportCardSubject
                    subjects_entry = ReportCardSubject.objects.filter(report_card_id=str(report.id)).first()
                    if subjects_entry:
                        for subject in subjects_entry.subjects:
                            year = _subject_value(subject, "year")
                            year_str = str(year)
                            subject_obj = {
                                "name": _subject_value(subject, "name", ""),
                                "year": year_str,
                                "hk1": str(_subject_value(subject, f"year{year}_sem1_score", "")),
                                "hk2": str(_subject_value(subject, f"year{year}_sem2_score", "")),
                                "cn": str(_subject_value(subject, f"year{year}_final_score", "")),
                            }
                            student_entry["subjects"].append(subject_obj)

                all_data.append(student_entry)

        return JsonResponse({"students": all_data}, json_dumps_params={'ensure_ascii': False}, status=200)

    except Exception as e:
        print(f"❌ Exception get_all_student_data: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
@require_http_methods(["DELETE"])
def delete_full_report_card(request):
    try:
        report_card_id = request.GET.get("id")
        if not report_card_id:
            return JsonResponse({'error': 'Thiếu report_card_id'}, status=400)

        # 1. Xác thực người dùng
        authorization_header = request.headers.get('Authorization')
        if not authorization_header or not authorization_header.startswith("Bearer "):
            return JsonResponse({'error': 'Thiếu hoặc sai định dạng Authorization'}, status=401)

        uid = authorization_header.split(' ')[1]
        try:
            User.objects.get(uid=uid)
        except User.DoesNotExist:
            return JsonResponse({'error': 'Người dùng không tồn tại'}, status=404)

        # 2. Tìm và xoá học bạ
        try:
            report_card = ReportCard.objects.get(id=report_card_id)
        except ReportCard.DoesNotExist:
            return JsonResponse({'error': 'Không tìm thấy học bạ'}, status=404)

        student_id = report_card.student_id

        # Xoá học bạ
        report_card.delete()

        # Xoá bảng điểm
        ReportCardSubject.objects.filter(report_card_id=report_card_id).delete()

        # Xoá thông tin sinh viên (nếu không còn học bạ nào khác)
        if ReportCard.objects.filter(student_id=student_id).first() is None:
            StudentInfo.objects.filter(student_id=student_id).delete()


        return JsonResponse({'message': 'Xoá học bạ và sinh viên thành công'}, status=200)

    except Exception as e:
        print(f"❌ Exception delete_full_report_card: {e}")
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
@require_http_methods(["PUT"])
def update_report_card(request):
    try:
        report_card_id = request.GET.get("id")
        if not report_card_id:
            return JsonResponse({'error': 'Thiếu report_card_id'}, status=400)

        data = json.loads(request.body)
        authorization_header = request.headers.get('Authorization')
        if not authorization_header or not authorization_header.startswith("Bearer "):
            return JsonResponse({'error': 'Thiếu hoặc sai định dạng Authorization'}, status=401)

        uid = authorization_header.split(' ')[1]
        try:
            user = User.objects.get(uid=uid)
        except User.DoesNotExist:
            return JsonResponse({'error': 'Người dùng không tồn tại'}, status=404)

        # 1. Tìm và cập nhật ReportCard
        try:
            report_card = ReportCard.objects.get(id=report_card_id)
        except ReportCard.DoesNotExist:
            return JsonResponse({'error': 'Không tìm thấy report card'}, status=404)

        report_data = data.get('report_card', {})
        class_id = report_data.get('class_id')
        print("🧪 class_id nhận từ frontend:", class_id)
        if not class_id:
            return JsonResponse({'error': 'class_id không được để trống'}, status=400)

        try:
            class_instance = Class.objects.get(id=class_id)
        except Class.DoesNotExist:
            return JsonResponse({'error': f'Không tìm thấy class_id: {class_id}'}, status=404)

        subjects = data.get('subjects', [])
        computed_report_data = _computed_report_card_defaults(subjects)
        merged_report_data = {
            **computed_report_data,
            **{
                field: value
                for field, value in report_data.items()
                if value not in (None, '')
            },
        }

        for field, value in merged_report_data.items():
            if field == 'class_id':
                continue  # ✅ bỏ qua vì đã gán riêng ở dưới
            setattr(report_card, field, value)

        report_card.class_id = str(class_instance.id)

        report_card.user_id = user.uid
        report_card.save()

        # 2. Cập nhật thông tin sinh viên
        student_data = data.get('student', {})
        student_id = student_data.get('id')
        student_defaults = {k: v for k, v in student_data.items() if k != 'id'}
        _upsert_student_info(student_id, student_defaults)

        # 3. Cập nhật ReportCardSubject
        ReportCardSubject.objects.filter(report_card_id=str(report_card.id)).delete()
        ReportCardSubject.objects.create(
            report_card_id=str(report_card.id),
            subjects=subjects
        )

        return JsonResponse({'message': 'Cập nhật học bạ thành công'}, status=200)

    except Exception as e:
        print(f"❌ Exception update_report_card: {e}")
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def get_full_report_card(request):
    student_id = request.GET.get('student_id')
    if not student_id:
        return JsonResponse({'error': 'Missing student_id'}, status=400)

    try:
        # 1. Lấy thông tin sinh viên
        student_info = StudentInfo.objects.get(student_id=student_id)

        # 1.1 Truy xuất thông tin lớp từ class_id
        class_name = ''
        school_name = ''
        if student_info.class_id:
            try:
                class_obj = Class.objects.get(id=str(student_info.class_id))
                class_name = class_obj.name
                school_name = class_obj.school_name
            except Exception as e:
                print(f"❌ Không tìm được lớp từ class_id: {e}")

        # 2. Gán thông tin cơ bản
        student_data = {
            'id': student_info.student_id,
            'name': student_info.name,
            'dob': student_info.dob or '',
            'gender': student_info.gender or '',
            'phone': student_info.phone or '',
            'school': school_name,
            'class_id': str(student_info.class_id) if student_info.class_id else '',
            'academicPerformance': '',
            'conduct': '',
        }

        # 3. Lấy học bạ gần nhất
        report_card = ReportCard.objects.filter(student_id=student_id).order_by('-school_year').first()
        if not report_card:
            return JsonResponse({
                'student': student_data,
                'report_card': None,
                'classList': [],
                'class_name': class_name,
                'school_name': school_name
            }, status=200)

        student_data['academicPerformance'] = report_card.academic_perform_year1 or ''
        student_data['conduct'] = report_card.conduct_year1_final or ''

        # 4. Lấy danh sách điểm môn học
        print("🧪 Dạng string dùng để filter:", str(report_card.id))
        subjects_entries = ReportCardSubject.objects.filter(report_card_id=str(report_card.id))
        print("🔍 Số entries tìm được:", subjects_entries.count())
        print("🧪 report_card id dùng để tìm:", str(report_card.id))
        year_map = {1: "10", 2: "11", 3: "12"}
        class_subjects = { "10": [], "11": [], "12": [] }

        for entry in subjects_entries:
            for sub in entry.subjects:
                year = _subject_value(sub, 'year')
                class_label = year_map.get(year)
                if not class_label:
                    continue

                name = str(_subject_value(sub, 'name', '')).strip()
                if name.lower() in ['học', 'các môn', 'dtb các môn']:
                    print(f"⚠️ Bỏ qua môn không hợp lệ: {name}")
                    continue


                subject_obj = {
                    'name': name,
                    'hk1': str(_subject_value(sub, f'year{year}_sem1_score', '') or ''),
                    'hk2': str(_subject_value(sub, f'year{year}_sem2_score', '') or ''),
                    'cn':  str(_subject_value(sub, f'year{year}_final_score', '') or '')
                }

                class_subjects[class_label].append(subject_obj)

        # 5. Ghép thành classList
        class_list = []
        for class_name_, subjects in class_subjects.items():
            if subjects:
                class_list.append({
                    'class': class_name_,
                    'subjects': subjects
                })
        print("✅ Tổng số entry ReportCardSubject:", subjects_entries.count())
        print("🔍 class_subjects build xong:", json.dumps(class_subjects, ensure_ascii=False))
        print("📦 classList trả về:", json.dumps(class_list, ensure_ascii=False))

        # 6. Trả dữ liệu
        return JsonResponse({
            'student': student_data,
            'report_card': {
                'id': str(report_card.id),
                'school_year': report_card.school_year,
                'teacher_signed': report_card.teacher_signed,
                'principal_signed': report_card.principal_signed,
                'teacher_comment': report_card.teacher_comment,
                'approval_date': str(report_card.approval_date) if report_card.approval_date else None,
            },
            'classList': class_list,
            'class_name': class_name,
            'school_name': school_name,
        }, json_dumps_params={'ensure_ascii': False}, status=200)

    except StudentInfo.DoesNotExist:
        return JsonResponse({'error': 'Student not found'}, status=404)
    except Exception as e:
        print("❌ detect() error:")
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)



@csrf_exempt
@require_http_methods(["POST"])
def save_full_report_card(request):
    try:
        print("🔵 Nhận request save_full_report_card")

        body_unicode = request.body.decode('utf-8')
        print("📦 Payload raw nhận được:", body_unicode)
        data = json.loads(request.body)
        print("📋 Dữ liệu parse xong:", data)
  # 0. Lấy UID từ Authorization Header
        authorization_header = request.headers.get('Authorization')
        if not authorization_header:
            print("🔴 Lỗi: Thiếu Authorization Header (UID)")
            return JsonResponse({'error': 'Missing Authorization header (UID)'}, status=401)

        # Extract UID từ header 'Bearer user_xxx'
        if not authorization_header.startswith("Bearer "):
            print("🔴 Lỗi: Authorization Header không đúng định dạng Bearer")
            return JsonResponse({'error': 'Invalid Authorization header format'}, status=400)

        uid = authorization_header.split(' ')[1]
        print(f"🔹 UID nhận được: {uid}")

        try:
            user = User.objects.get(uid=uid)
        except User.DoesNotExist:
            print(f"🔴 Lỗi: Không tìm thấy user với UID: {uid}")
            return JsonResponse({'error': 'User not found'}, status=404)

        # 1. Lưu StudentInfo
        student_id = data.get('student', {}).get('id')
        if not student_id:
            print("🔴 Lỗi: Không có student_id")
            return JsonResponse({'error': 'Missing student ID'}, status=400)

        _upsert_student_info(
            student_id,
            {
                'name': data['student'].get('name', ''),
                'dob': data['student'].get('dob', ''),
                'gender': data['student'].get('gender', ''),
                'address': data['student'].get('address', ''),
                'father_name': data['student'].get('father_name', ''),
                'mother_name': data['student'].get('mother_name', ''),
                'phone': data['student'].get('phone', ''),
                'parents_email': data['student'].get('parents_email', ''),
                'class_id': data['student'].get('class_id', ''),
                'ethnicity': data['student'].get('ethnicity', ''),
                'birthplace': data['student'].get('birthplace', ''),
            }
        )

        # 2. Lưu ReportCard
        report_data = data.get('report_card', {})
        class_uuid = report_data.get('class_id', '')
        try:
            class_instance = Class.objects.get(id=class_uuid)
        except Class.DoesNotExist:
            return JsonResponse({'error': f'Class with id {class_uuid} not found'}, status=404)
        subjects = data.get('subjects', [])
        computed_report_data = _computed_report_card_defaults(subjects)

        def report_value(field_name, default=''):
            value = report_data.get(field_name)
            if value not in (None, ''):
                return value
            return computed_report_data.get(field_name, default)

        report_card = ReportCard.objects.create(
            student_id=student_id,
            class_id=str(class_instance.id),
            school_year=report_value('school_year', ''),
            conduct_year1_sem1=report_value('conduct_year1_sem1', ''),
            conduct_year1_sem2=report_value('conduct_year1_sem2', ''),
            conduct_year1_final=report_value('conduct_year1_final', ''),
            conduct_year2_sem1=report_value('conduct_year2_sem1', ''),
            conduct_year2_sem2=report_value('conduct_year2_sem2', ''),
            conduct_year2_final=report_value('conduct_year2_final', ''),
            conduct_year3_sem1=report_value('conduct_year3_sem1', ''),
            conduct_year3_sem2=report_value('conduct_year3_sem2', ''),
            conduct_year3_final=report_value('conduct_year3_final', ''),
            academic_perform_year1=report_value('academic_perform_year1', ''),
            academic_perform_year2=report_value('academic_perform_year2', ''),
            academic_perform_year3=report_value('academic_perform_year3', ''),
            gpa_avg_year1=report_value('gpa_avg_year1', 0),
            gpa_avg_year2=report_value('gpa_avg_year2', 0),
            gpa_avg_year3=report_value('gpa_avg_year3', 0),
            promotion_status=report_value('promotion_status', ''),
            teacher_comment=report_value('teacher_comment', ''),
            teacher_signed=report_data.get('teacher_signed', False),
            principal_signed=report_data.get('principal_signed', False),
            user_id=user.uid
        )
        print("🟩 Tạo ReportCard thành công, id =", report_card.id)

        # 3. Lưu ReportCardSubject
        ReportCardSubject.objects.create(
            report_card_id=str(report_card.id),
            subjects=subjects
        )


        return JsonResponse({'message': 'Lưu học bạ thành công'}, status=201)

    except Exception as e:
        print(f"🔴 Exception trong save_full_report_card: {e}")
        return JsonResponse({'error': str(e)}, status=400)



def correct_text_with_bart(text):
    endpoints = [BART_SERVER_URL]
    if not BART_SERVER_URL.rstrip("/").endswith("/correct"):
        endpoints.append(BART_SERVER_URL.rstrip("/") + "/correct")

    try:
        last_status = None
        for endpoint in endpoints:
            response = requests.post(endpoint, json={"text": text}, timeout=10)
            last_status = response.status_code
            if response.status_code == 200:
                result = response.json().get("corrected", text)
                print(f"✅ BART sửa: '{text}' ➜ '{result}'")
                return result
            if response.status_code != 404:
                print(f"⚠️ BART HTTP error: {response.status_code} ({endpoint})")
                return text
        print(f"⚠️ BART HTTP error: {last_status}")
        return text
    except Exception as e:
        print(f"⚠️ BART connection error: {e}")
        return text


def run_ocr(crop_path):
    """Run OCR in PaddleOCR-new compatible mode without forcing legacy kwargs."""
    started_at = time.perf_counter()
    print(f"⏱️ [OCR] start: {crop_path}")
    try:
        result = ocr_model.ocr(crop_path)
        print(f"⏱️ [OCR] ocr() done in {time.perf_counter() - started_at:.3f}s: {crop_path}")
        return result
    except Exception as e:
        print(f"⚠️ OCR default mode failed: {e}")
        try:
            result = ocr_model.predict(crop_path)
            print(f"⏱️ [OCR] predict() done in {time.perf_counter() - started_at:.3f}s: {crop_path}")
            return result
        except Exception as e2:
            print(f"⚠️ OCR predict mode failed: {e2}")
            print(f"⏱️ [OCR] failed after {time.perf_counter() - started_at:.3f}s: {crop_path}")
            return []


def _normalize_ocr_lines(ocr_result):
    """Normalize OCR output to legacy shape: [[box, [text, score]], ...]."""
    if not ocr_result:
        return []

    if isinstance(ocr_result, dict):
        rec_texts = ocr_result.get("rec_texts") or []
        rec_scores = ocr_result.get("rec_scores") or []
        dt_polys = ocr_result.get("dt_polys") or []
        return [
            [box, [text, rec_scores[idx] if idx < len(rec_scores) else 1.0]]
            for idx, (box, text) in enumerate(zip(dt_polys, rec_texts))
        ]

    first = ocr_result[0]
    if isinstance(first, list):
        return first

    if isinstance(first, dict):
        rec_texts = first.get("rec_texts") or []
        rec_scores = first.get("rec_scores") or []
        dt_polys = first.get("dt_polys") or []

        lines = []
        for idx, (box, text) in enumerate(zip(dt_polys, rec_texts)):
            score = rec_scores[idx] if idx < len(rec_scores) else 1.0
            lines.append([box, [text, score]])
        return lines

    return []



@csrf_exempt
def detect(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST method allowed'}, status=405)

    if 'image' not in request.FILES:
        return JsonResponse({'error': 'Missing image file'}, status=400)

    image_type = request.POST.get('image_type', 'report_card')
    model = yolo_model
    print(f"📥 detect image_type='{image_type}'")
    pipeline_started_at = time.perf_counter()
    image_file = request.FILES['image']
    unique_filename = str(uuid.uuid4()) + ".jpg"
    temp_image_path = os.path.join(settings.MEDIA_ROOT, "temp", unique_filename)
    os.makedirs(os.path.dirname(temp_image_path), exist_ok=True)
    with open(temp_image_path, 'wb+') as f:
        f.write(image_file.read())
    print(f"⏱️ [detect] saved temp image in {time.perf_counter() - pipeline_started_at:.3f}s: {temp_image_path}")

    try:
        cleanup_started_at = time.perf_counter()
        os.makedirs(CROPPED_ROOT_DIR, exist_ok=True)
        cleanup_cropped_dir(CROPPED_ROOT_DIR)
        print(f"⏱️ [detect] cleanup_cropped_dir done in {time.perf_counter() - cleanup_started_at:.3f}s")

        cropped_dir_started_at = time.perf_counter()
        cropped_dir = os.path.join(CROPPED_ROOT_DIR, uuid.uuid4().hex[:6])
        os.makedirs(cropped_dir, exist_ok=True)
        print(f"⏱️ [detect] create cropped dir done in {time.perf_counter() - cropped_dir_started_at:.3f}s: {cropped_dir}")

        # Info pineline:
        if image_type != 'report_card':
            info_started_at = time.perf_counter()
            info_filename = f"info_{uuid.uuid4().hex[:8]}.jpg"
            info_path = os.path.join(cropped_dir, info_filename)
            image_read_started_at = time.perf_counter()
            temp_image = cv2.imread(temp_image_path)
            print(f"⏱️ [detect] cv2.imread(temp) done in {time.perf_counter() - image_read_started_at:.3f}s")

            write_started_at = time.perf_counter()
            cv2.imwrite(info_path, temp_image)
            print(f"⏱️ [detect] cv2.imwrite(info image) done in {time.perf_counter() - write_started_at:.3f}s: {info_path}")

            gemini_started_at = time.perf_counter()
            info_data = extract_student_info_from_image(info_path)
            print(f"⏱️ [detect] Gemini student info done in {time.perf_counter() - gemini_started_at:.3f}s")
            print(f"✅ Gemini parsed student_info direct image: {json.dumps(info_data, ensure_ascii=False)}")

            response_data = [{
                "image_url": settings.MEDIA_URL + os.path.relpath(info_path, settings.MEDIA_ROOT).replace("\\", "/"),
                "ocr_data": [],
                "student_info": info_data
            }]
            print(f"⏱️ [detect] total non-report_card pipeline done in {time.perf_counter() - pipeline_started_at:.3f}s")
            return JsonResponse({'results': response_data}, json_dumps_params={'ensure_ascii': False})

        yolo_started_at = time.perf_counter()
        results = model(temp_image_path)[0]
        print(f"⏱️ [detect] YOLO inference done in {time.perf_counter() - yolo_started_at:.3f}s")

        image_load_started_at = time.perf_counter()
        img = cv2.imread(temp_image_path)
        print(f"⏱️ [detect] cv2.imread(report image) done in {time.perf_counter() - image_load_started_at:.3f}s")

        response_data = []
        boxes = results.boxes.xyxy.cpu().numpy()
        print(f"⏱️ [detect] YOLO detected {len(boxes)} boxes")
        for i, box in enumerate(boxes):
            crop_started_at = time.perf_counter()
            x1, y1, x2, y2 = map(int, box)
            crop = img[y1:y2, x1:x2]
            if crop.size == 0:
                print(f"⚠️ Empty crop at index {i}, box={box}")
                continue

            crop_filename = f"crop_{i}.jpg"
            crop_path = os.path.join(cropped_dir, crop_filename)

            write_crop_started_at = time.perf_counter()
            cv2.imwrite(crop_path, crop)
            print(f"⏱️ [detect] crop {i} cv2.imwrite done in {time.perf_counter() - write_crop_started_at:.3f}s: {crop_path}")

            ocr_started_at = time.perf_counter()
            ocr_result = run_ocr(crop_path)
            print(f"⏱️ [detect] crop {i} OCR wrapper finished in {time.perf_counter() - ocr_started_at:.3f}s")

            parse_started_at = time.perf_counter()
            text_data = extract_table_from_ocr_result_new_paddle(ocr_result)
            print(f"⏱️ [detect] crop {i} parse finished in {time.perf_counter() - parse_started_at:.3f}s")
            print(f"✅ OCR parsed report_card crop_{i}: {json.dumps(text_data, ensure_ascii=False)}")
            result_entry = {
                "image_url": settings.MEDIA_URL + os.path.relpath(crop_path, settings.MEDIA_ROOT).replace("\\", "/"),
                "ocr_data": text_data,
                "student_info": {}
            }

            response_data.append(result_entry)
            print(f"⏱️ [detect] crop {i} total done in {time.perf_counter() - crop_started_at:.3f}s")

        print(f"⏱️ [detect] total report_card pipeline done in {time.perf_counter() - pipeline_started_at:.3f}s")
        return JsonResponse({'results': response_data}, json_dumps_params={'ensure_ascii': False})

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

    finally:
        if os.path.exists(temp_image_path):
            os.remove(temp_image_path)



def extract_table_from_ocr_result_new_paddle(ocr_result):
    rows = []
    ocr_lines = _normalize_ocr_lines(ocr_result)
    if not ocr_lines:
        return []

    def normalize_text(s: str) -> str:
        return " ".join(str(s).strip().split())

    def norm_token(s: str) -> str:
        return normalize_text(s).lower().replace(" ", "")

    def is_score_token(s: str) -> bool:
        s = normalize_text(s).replace(",", ".")
        if not s:
            return False

        try:
            val = float(s)
            return 0 <= val <= 10
        except Exception:
            pass

        low = s.lower()
        if low in {"dat", "đạt", "dt", "dạt", "đt"}:
            return True

        return False

    def score_value(s: str) -> str:
        s = normalize_text(s).replace(",", ".")
        low = s.lower()
        if low in {"dat", "đạt", "dt", "dạt", "đt"}:
            return "Dat"
        return s

    def recompute_ca_nam(hk1: str, hk2: str, current_cn: str) -> str:
        hk1_v = normalize_text(hk1)
        hk2_v = normalize_text(hk2)

        if hk1_v == "Dat" and hk2_v == "Dat":
            return "Dat"

        try:
            a = float(hk1_v)
            b = float(hk2_v)
        except Exception:
            return current_cn

        avg = round((a + b) / 2, 1)
        if float(int(avg)) == avg:
            return str(int(avg))
        return str(avg)

    # ---- build rows from OCR tokens ----
    for line in ocr_lines:
        if not line or len(line) < 2:
            continue

        box = line[0]
        text_info = line[1]

        if box is None or not isinstance(text_info, (list, tuple)) or len(text_info) == 0:
            continue

        try:
            pts = np.array(box, dtype=np.float32).reshape(-1, 2)
        except Exception:
            continue

        if pts.shape[0] < 4:
            continue

        text = normalize_text(text_info[0])
        if not text:
            continue

        x_center = float(pts[:, 0].mean())
        y_center = float(pts[:, 1].mean())
        height = float(pts[:, 1].max() - pts[:, 1].min())

        rows.append([y_center, x_center, text, box, height])

    if not rows:
        print("⚠️ bbox parser rows=0")
        return []

    print(f"🧪 bbox parser rows: {len(rows)}")

    rows.sort(key=lambda r: r[0])
    avg_height = np.mean([r[4] for r in rows]) if rows else 10
    if avg_height <= 0:
        avg_height = 10

    # ---- group by visual row ----
    grouped_rows = []
    current_group = []

    for r in rows:
        if not current_group or abs(r[0] - current_group[-1][0]) < avg_height * 0.72:
            current_group.append(r)
        else:
            grouped_rows.append(current_group)
            current_group = [r]

    if current_group:
        grouped_rows.append(current_group)

    print(f"🧪 bbox grouped rows: {len(grouped_rows)}")

    # ---- find header anchors from header row ----
    header_group = None
    hk1_x = hk2_x = cn_x = None

    for group in grouped_rows:
        g = sorted(group, key=lambda r: r[1])
        tokens = [norm_token(item[2]) for item in g]

        has_hk1 = any(t in {"hkyi", "hki", "hk1"} for t in tokens)
        has_hk2 = any(t in {"hkyii", "hkii", "hk2"} for t in tokens)
        has_cn = any(t in {"cn", "canam"} for t in tokens)

        if has_hk1 and has_hk2:
            header_group = g
            break

    if header_group:
        for item in header_group:
            token = norm_token(item[2])
            x = item[1]

            if token in {"hkyi", "hki", "hk1"} and hk1_x is None:
                hk1_x = x
            elif token in {"hkyii", "hkii", "hk2"} and hk2_x is None:
                hk2_x = x
            elif token in {"cn", "canam"} and cn_x is None:
                cn_x = x

    if hk1_x is None or hk2_x is None or cn_x is None:
        # fallback an toàn hơn
        score_xs = sorted([r[1] for r in rows if is_score_token(r[2])])
        if len(score_xs) >= 6:
            hk1_x = float(np.percentile(score_xs, 20))
            hk2_x = float(np.percentile(score_xs, 55))
            cn_x = float(np.percentile(score_xs, 85))
        else:
            hk1_x, hk2_x, cn_x = 360.0, 540.0, 710.0

    print(f"🧪 column anchors: hk1_x={hk1_x}, hk2_x={hk2_x}, cn_x={cn_x}")

    extracted = []

    for group in grouped_rows:
        group = sorted(group, key=lambda r: r[1])
        raw_texts = [normalize_text(item[2]) for item in group if normalize_text(item[2])]
        raw_join = " ".join(raw_texts).lower()
        if not raw_texts:
            continue

        # ---- header row ----
        token_set = {norm_token(t) for t in raw_texts}
        if any(t in token_set for t in {"hkyi", "hki", "hk1"}) and any(t in token_set for t in {"hkyii", "hkii", "hk2"}):
            continue

        # ---- summary row ----
        if "dtb" in raw_join or "đtb" in raw_join or "các môn" in raw_join or "cac mon" in raw_join:
            score_tokens = [score_value(t) for t in raw_texts if is_score_token(t)]
            extracted.append({
                "ten_mon": "DTB cac mon",
                "hky1": score_tokens[0] if len(score_tokens) > 0 else "",
                "hky2": score_tokens[1] if len(score_tokens) > 1 else "",
                "ca_nam": score_tokens[2] if len(score_tokens) > 2 else ""
            })
            continue

        # ---- parse normal row ----
        text_tokens = []
        score_candidates = []

        for item in group:
            x = item[1]
            text = normalize_text(item[2])

            if is_score_token(text):
                score_candidates.append((x, score_value(text), text))
            else:
                text_tokens.append((x, text))

        if not text_tokens and not score_candidates:
            continue

        # tên môn = ghép toàn bộ token chữ, KHÔNG lấy token điểm
        subject_parts = [t[1] for t in sorted(text_tokens, key=lambda z: z[0])]
        subject_name = " ".join(subject_parts).strip()

        replacements = {
            "Vt lí": "Vatli",
            "Vật lí": "Vatli",
            "Vat li": "Vatli",
            "Hóa hc": "Hoa hoc",
            "Hóa học": "Hoa hoc",
            "Sinh hc": "Sinh hoc",
            "Sinh học": "Sinh hoc",
            "Tin hc": "Tin hoc",
            "Tin học": "Tin hoc",
            "Ng văn": "Ngu van",
            "Ngữ văn": "Ngu van",
            "Lịch sửu": "Lich su",
            "Lịch sử": "Lich su",
            "Đa lí": "Diali",
            "Địa lí": "Diali",
            "Ngoi ng": "Ngoai ngu",
            "Ngoại ngữ": "Ngoai ngu",
            "Công ngh": "Cong nghe",
            "Công nghệ": "Cong nghe",
            "Th dc": "Theduc",
            "Thể dục": "Theduc",
            "Giáo dc công dân": "Giáo dục công dân",
            "Giáo dc cong dan": "Giáo dục công dân",
            "Giao duc cong dan": "Giáo dục công dân",
            "công dân Giáo dc": "Giáo dục công dân",
            "chn Ngh PT": "",
            "T NN2": "",
        }
        subject_name = replacements.get(subject_name, subject_name)

        # Apply BART correction to subject name
        bart_started_at = time.perf_counter()
        print(f"⏱️ [parse] BART start: {subject_name}")
        subject_name = correct_text_with_bart(subject_name)
        print(f"⏱️ [parse] BART done in {time.perf_counter() - bart_started_at:.3f}s: {subject_name}")

        if not subject_name:
            continue

        # =========================
        # ƯU TIÊN MAP ĐIỂM THEO THỨ TỰ TRÁI -> PHẢI
        # =========================
        ordered_scores = [
            normalized_score
            for x, normalized_score, _raw_score in sorted(score_candidates, key=lambda z: z[0])
        ]

        hk1_val = ""
        hk2_val = ""
        cn_val = ""

        if len(ordered_scores) >= 3 and all(s == "Dat" for s in ordered_scores[:3]):
            hk1_val, hk2_val, cn_val = "Dat", "Dat", "Dat"
        elif len(ordered_scores) >= 3:
            hk1_val = ordered_scores[0]
            hk2_val = ordered_scores[1]
            cn_val = ordered_scores[2]
        elif len(ordered_scores) == 2:
            hk1_val = ordered_scores[0]
            hk2_val = ordered_scores[1]
            cn_val = ""
        elif len(ordered_scores) == 1:
            hk1_val = ordered_scores[0]

        if len(ordered_scores) > 3:
            hk1_val = ordered_scores[0]
            hk2_val = ordered_scores[1]
            cn_val = ordered_scores[2]

        # Recompute yearly average to replace noisy OCR CN when HK1/HK2 are valid.
        cn_val = recompute_ca_nam(hk1_val, hk2_val, cn_val)

        extracted.append({
            "ten_mon": subject_name,
            "hky1": hk1_val,
            "hky2": hk2_val,
            "ca_nam": cn_val,
        })

    # bỏ các dòng rác hoàn toàn
    cleaned = []
    for item in extracted:
        name = item["ten_mon"].strip()
        if not name:
            continue
        if name in {"T NN2", "chn Ngh PT"}:
            continue
        cleaned.append(item)

    return cleaned


def extract_student_info_from_image(image_path):
    try:
        with open(image_path, "rb") as img_file:
            image_bytes = img_file.read()
            base64_image = base64.b64encode(image_bytes).decode("utf-8")

        return extract_student_info_from_base64(base64_image)

    except Exception as e:
        print("❌ Lỗi khi xử lý ảnh bằng Gemini:", str(e))

    return {
        "name": "",
        "gender": "",
        "dob": ""
    }


def extract_student_info_from_crop(crop_image):
    try:
        ok, encoded = cv2.imencode('.jpg', crop_image)
        if not ok:
            raise ValueError('Không thể encode ảnh crop sang JPEG')

        base64_image = base64.b64encode(encoded.tobytes()).decode("utf-8")
        return extract_student_info_from_base64(base64_image)

    except Exception as e:
        print("❌ Lỗi khi xử lý crop bằng Gemini:", str(e))

    return {
        "name": "",
        "gender": "",
        "dob": ""
    }


def extract_student_info_from_base64(base64_image):
    try:

        prompt = """
        Hãy trích xuất thông tin sau từ ảnh thông tin sinh viên:

        - Họ và tên
        - Giới tính
        - Ngày sinh

        Trả về kết quả JSON với các trường: name, gender, dob
        """

        response = gemini_model.generate_content([
            {"text": prompt},
            {
                "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64_image,
                }
            }
        ])

        output_text = response.text.strip()
        print("📄 Gemini raw response:", output_text)

        # Loại bỏ ```json hoặc ``` nếu tồn tại
        if output_text.startswith("```json"):
            output_text = output_text[7:]
        elif output_text.startswith("```"):
            output_text = output_text[3:]

        if output_text.endswith("```"):
            output_text = output_text[:-3]

        output_text = output_text.strip()

        return json.loads(output_text)

    except Exception as e:
        print("❌ Lỗi khi xử lý ảnh bằng Gemini:", str(e))

    return {
        "name": "",
        "gender": "",
        "dob": ""
    }

