import json
from django.http import JsonResponse
from apps.classroom.models import Class
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from apps.users.models import User


def health_check(request):
    return JsonResponse({"module": "classroom", "status": "ok"})


def _get_ocr_models():
    """Load OCR models lazily to avoid breaking classroom module import."""
    try:
        from apps.ocr.models import ReportCard, ReportCardSubject, StudentInfo
    except Exception as exc:
        raise RuntimeError(f"OCR models are not available yet: {exc}")

    return ReportCard, ReportCardSubject, StudentInfo

@csrf_exempt
@require_http_methods(["DELETE"])
def delete_classroom(request):
    try:
        ReportCard, ReportCardSubject, StudentInfo = _get_ocr_models()

        class_id = request.GET.get("id")
        print(f"🧪 DELETE request class_id = {class_id}")
        if not class_id:
            return JsonResponse({'error': 'Thiếu class_id'}, status=400)

        # Xác thực người dùng
        authorization_header = request.headers.get('Authorization')
        if not authorization_header or not authorization_header.startswith("Bearer "):
            return JsonResponse({'error': 'Thiếu hoặc sai định dạng Authorization'}, status=401)
        uid = authorization_header.split(' ')[1]
        try:
            User.objects.get(uid=uid)
        except User.DoesNotExist:
            return JsonResponse({'error': 'Người dùng không tồn tại'}, status=404)

        # Tìm tất cả học bạ của lớp
        class_instance = Class.objects.get(id=class_id)
        if class_instance.teacher_id != uid:
            return JsonResponse({'error': 'Bạn không có quyền xoá lớp này'}, status=403)

        report_cards = list(ReportCard.objects.filter(class_id=class_id))
        student_ids = [rc.student_id for rc in report_cards]

        if student_ids:
            return JsonResponse(
                {
                    'error': 'Không thể xóa lớp đang có học sinh',
                    'student_count': len(set(student_ids)),
                },
                status=409,
            )

        # 1. Xoá ReportCardSubject trước
        for rc in report_cards:
            report_card_id = str(rc.id)
            deleted = ReportCardSubject.objects.filter(report_card_id=report_card_id).delete()
            print(f"🗑️ Deleted ReportCardSubject for report_card_id={report_card_id}: {deleted}")

        # 2. Xoá ReportCard tiếp theo
        deleted_rc = ReportCard.objects.filter(class_id=class_id).delete()
        print(f"🗑️ Deleted ReportCards: {deleted_rc}")

        # 3. Xoá StudentInfo nếu không còn report card nào khác
        for student_id in student_ids:
            if ReportCard.objects.filter(student_id=student_id).first() is None:
                deleted_st = StudentInfo.objects.filter(student_id=student_id).delete()
                print(f"🗑️ Deleted StudentInfo for student_id={student_id}: {deleted_st}")

        # 4. Xoá class cuối cùng
        deleted_class = class_instance.delete()
        print(f"🗑️ Deleted Class: {deleted_class}")

        return JsonResponse({'message': 'Xoá lớp và toàn bộ học sinh liên quan thành công'}, status=200)

    except Class.DoesNotExist:
        return JsonResponse({'error': 'Không tìm thấy lớp'}, status=404)
    except Exception as e:
        print("❌ Exception delete_classroom:", str(e))
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def save_classroom(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)

            authorization_header = request.headers.get('Authorization', '')
            if not authorization_header.startswith('Bearer '):
                return JsonResponse({'error': 'Thiếu hoặc sai định dạng Authorization'}, status=401)
            uid = authorization_header.split(' ')[1].strip()
            if not uid:
                return JsonResponse({'error': 'User not authenticated or uid missing'}, status=401)

            try:
                User.objects.get(uid=uid)
            except User.DoesNotExist:
                return JsonResponse({'error': 'Người dùng không tồn tại'}, status=404)

            # Lấy các trường từ frontend
            name = data.get('name')
            school_name = data.get('school_name')
            class_year = data.get('class_year')

            if not all([name, school_name, class_year]):
                return JsonResponse({'error': 'Missing class information'}, status=400)

            # Tạo lớp mới
            new_class = Class.objects.create(
                name=name,
                teacher_id=uid,
                school_name=school_name  or "",
                class_year=class_year  or ""
            )

            return JsonResponse({'message': 'Lưu lớp thành công', 'class_id': str(new_class.id)})

        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=405)


def get_classroom(request):
    return JsonResponse({'status': 'get_classroom working'})

@csrf_exempt
def get_classrooms(request):
    teacher_id = request.GET.get('teacher_id')
    if not teacher_id:
        return JsonResponse({'error': 'Missing teacher_id'}, status=400)

    classrooms = Class.objects.filter(teacher_id=teacher_id)
    data = [
        {
            'id': str(c.id),
            'name': c.name,
            'school_name': c.school_name,
            'class_year': c.class_year,
        }
        for c in classrooms
    ]
    return JsonResponse(data, safe=False)

@csrf_exempt
def get_students_by_class(request):
    class_id = request.GET.get('class_id')
    if not class_id:
        return JsonResponse({'error': 'Missing class_id'}, status=400)

    try:
        ReportCard, _, StudentInfo = _get_ocr_models()
    except RuntimeError as e:
        return JsonResponse({'error': str(e)}, status=500)

    report_cards = ReportCard.objects.filter(class_id=class_id)
    student_ids = [rc.student_id for rc in report_cards]
    students = StudentInfo.objects.filter(student_id__in=student_ids)

    results = [
        {
            'id': student.student_id,
            'name': student.name,
            'gender': student.gender,
            'dob': student.dob,
            'phone': student.phone,
            'school': student.school,
            'academicPerformance': '',
            'conduct': '',
            'transcript': ''
        } for student in students
    ]
    return JsonResponse(results, safe=False)

def update_classroom(request):
    return JsonResponse({'status': 'update_classroom working'})
