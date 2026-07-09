import hashlib
import os
import json
import uuid
import time

import requests
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.http import JsonResponse
from apps.users.models import User

from .rate_limit import check_chatbot_rate_limit

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMP_DIR = os.getenv('CHATBOT_TEMP_DIR', os.path.join(BASE_DIR, 'media', 'temp_files'))

DIFY_API_URL = os.getenv('DIFY_API_URL')
DIFY_UPLOAD_URL = os.getenv('DIFY_UPLOAD_URL')
DIFY_API_KEY = os.getenv('DIFY_API_KEY')


def _dify_error_response(response):
    """Return a useful error without mislabelling every Dify failure as a quota error."""
    status_code = response.status_code
    if status_code == 429:
        message = "Chatbot đang đạt giới hạn tạm thời. Vui lòng thử lại sau ít phút."
    elif status_code in (401, 403):
        message = "Cấu hình kết nối chatbot không hợp lệ. Vui lòng liên hệ quản trị viên."
    elif status_code == 400:
        message = "Dữ liệu gửi tới chatbot không hợp lệ hoặc tệp đính kèm không thể xử lý."
    else:
        message = "Chatbot không thể xử lý yêu cầu lúc này. Vui lòng thử lại sau."

    print(f"Dify request failed ({status_code}): {response.text}")
    return JsonResponse(
        {
            "error": message,
            "status": status_code,
            "detail": response.text,
        },
        status=status_code if 400 <= status_code < 600 else 502,
    )


def health_check(request):
    return JsonResponse({"module": "chatbot", "status": "ok"})

def clean_temp_files(folder_path=TEMP_DIR, expire_seconds= 24 * 60 * 60):
    """
    Xóa các file trong thư mục temp_files cũ hơn expire_seconds (mặc định: 1 ngày).
    """
    now = time.time()
    deleted = 0

    if not os.path.exists(folder_path):
        return

    for filename in os.listdir(folder_path):
        filepath = os.path.join(folder_path, filename)
        if os.path.isfile(filepath):
            last_modified = os.path.getmtime(filepath)
            if now - last_modified > expire_seconds:
                try:
                    os.remove(filepath)
                    deleted += 1
                except Exception as e:
                    print(f"❌ Lỗi khi xóa file {filename}: {e}")

    if deleted > 0:
        print(f" Đã xóa {deleted} file cũ trong {folder_path}")


def _map_subject_years_for_chatbot(student_list):
    year_map = {
        "1": "10",
        "2": "11",
        "3": "12",
        1: "10",
        2: "11",
        3: "12",
    }

    mapped_students = []
    for student in student_list:
        if not isinstance(student, dict):
            mapped_students.append(student)
            continue

        student_copy = dict(student)
        subjects = student_copy.get("subjects", [])

        if isinstance(subjects, list):
            mapped_subjects = []
            for subject in subjects:
                if not isinstance(subject, dict):
                    mapped_subjects.append(subject)
                    continue

                subject_copy = dict(subject)
                original_year = subject_copy.get("year")
                if original_year in year_map:
                    subject_copy["year"] = year_map[original_year]
                mapped_subjects.append(subject_copy)

            student_copy["subjects"] = mapped_subjects

        mapped_students.append(student_copy)

    return mapped_students


@csrf_exempt
@require_http_methods(["POST"])
def ask_chatbot(request):
    try:
        if not DIFY_API_KEY:
            return JsonResponse({'error': 'Thiếu cấu hình DIFY_API_KEY trên server'}, status=500)

        data = json.loads(request.body)
        question = data.get("question", "").strip()
        student_list = data.get("students", [])
        requested_context_mode = data.get("context_mode", "").strip()
        context_mode = (
            "result_analysis"
            if requested_context_mode == "result_analysis" or student_list
            else "general"
        )
        mapped_student_list = _map_subject_years_for_chatbot(student_list)

        # 🔐 Check token
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return JsonResponse({'error': 'Thiếu hoặc sai định dạng Authorization'}, status=401)
        uid = auth_header.split(" ")[1]

        if User.objects.filter(uid=uid).first() is None:
            return JsonResponse({'error': 'Người dùng không tồn tại'}, status=404)

        is_allowed, rate_limit_message, _retry_after = check_chatbot_rate_limit(
            uid,
            context_mode=context_mode,
        )
        if not is_allowed:
            return JsonResponse({'error': rate_limit_message}, status=429)

        if not student_list:
            payload = {
                "query": question,
                "inputs": {},
                "response_mode": "blocking",
                "user": uid,
                "conversation_id": ""
            }

            headers = {
                "Authorization": f"Bearer {DIFY_API_KEY}",
                "Content-Type": "application/json"
            }

            response = requests.post(DIFY_API_URL, headers=headers, json=payload, timeout=300)

            if response.status_code == 200:
                result = response.json()
                return JsonResponse({
                    "answer": result.get("answer", ""),
                    "conversation_id": result.get("conversation_id", ""),
                    "metadata": result.get("metadata", {})
                })
            else:
                return _dify_error_response(response)

        # ✅ Bước 1: Ghi file txt vào thư mục media/temp_files/
        os.makedirs(TEMP_DIR, exist_ok=True)
        clean_temp_files()
        # 🔑 Tính hash danh sách học sinh để tránh upload lại khi giống nhau
        student_str = json.dumps(mapped_student_list, ensure_ascii=False, sort_keys=True)
        hash_key = hashlib.md5(student_str.encode("utf-8")).hexdigest()
        cache_file = os.path.join(TEMP_DIR, f"{uid}_{hash_key}.json")
        txt_file_name = f"student_{hash_key}.txt"
        txt_file_path = os.path.join(TEMP_DIR, txt_file_name)

        # 🔁 Nếu đã từng upload file này, lấy lại upload_file_id
        if os.path.exists(cache_file):
            with open(cache_file, "r", encoding="utf-8") as cf:
                cache_data = json.load(cf)
                file_id = cache_data.get("upload_file_id")
                if file_id:
                    print("✅ Dùng lại file_id đã cache:", file_id)
        else:
            # ✅ Nếu chưa có file txt thì tạo
            if not os.path.exists(txt_file_path):
                with open(txt_file_path, "w", encoding="utf-8") as f:
                    for student in mapped_student_list:
                        f.write(json.dumps(student, ensure_ascii=False, indent=2) + "\n\n")
                print("✅ File đã ghi vào:", txt_file_path)
            else:
                print("Dùng lại file txt:", txt_file_path)

            # ✅ Upload lên Dify
            with open(txt_file_path, "rb") as f:
                multipart_data = {
                    "file": (txt_file_name, f, "text/plain"),
                    "user": (None, uid)
                }
                upload_resp = requests.post(
                    DIFY_UPLOAD_URL,
                    headers={"Authorization": f"Bearer {DIFY_API_KEY}"},
                    files=multipart_data
                )

            print("upload_resp.status_code:", upload_resp.status_code)
            print("upload_resp.text:", upload_resp.text)

            if upload_resp.status_code not in [200, 201]:
                return JsonResponse({
                    'error': 'Lỗi upload file lên Dify',
                    'status': upload_resp.status_code,
                    'detail': upload_resp.text
                }, status=500)

            file_id = upload_resp.json().get("id")
            if not file_id:
                return JsonResponse({'error': 'Không nhận được file_id từ Dify'}, status=500)

            # ✅ Ghi cache
            with open(cache_file, "w", encoding="utf-8") as cf:
                json.dump({"upload_file_id": file_id}, cf)
            print("✅ Đã cache upload_file_id:", file_id)

        # ✅ Bước 3: Ghi file payload.json và gửi lên Dify
        payload = {
            "query": question,
            "inputs": {},
            "response_mode": "blocking",
            "user": uid,
            "conversation_id": "",
            "files": [
                {
                    "type": "document",
                    "transfer_method": "local_file",
                    "upload_file_id": file_id
                }
            ]
        }

        # Lưu payload thành file giống như bạn đã dùng curl -d @payload.json
        payload_path = os.path.join(TEMP_DIR, "payload.json")
        with open(payload_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)

        # Gửi payload như lệnh curl đã test thành công
        with open(payload_path, "r", encoding="utf-8") as f:
            payload_data = json.load(f)

        headers = {
            "Authorization": f"Bearer {DIFY_API_KEY}",
            "Content-Type": "application/json"
        }

        response = requests.post(DIFY_API_URL, headers=headers, json=payload_data, timeout=300)

        if response.status_code == 200:
            result = response.json()
            return JsonResponse({
                "answer": result.get("answer", ""),
                "conversation_id": result.get("conversation_id", ""),
                "metadata": result.get("metadata", {})
            })
        else:
            return _dify_error_response(response)

    except Exception as e:
        import traceback
        return JsonResponse({'error': str(e), 'trace': traceback.format_exc()}, status=500)
