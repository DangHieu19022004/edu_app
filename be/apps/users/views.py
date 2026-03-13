from datetime import datetime

from mongoengine.errors import NotUniqueError, ValidationError
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .firebase_auth import verify_id_token
from .models import User


@api_view(["GET"])
@permission_classes([AllowAny])
def health_check(request):
	return Response({"module": "users", "status": "ok"})


@api_view(["GET", "POST"])
@permission_classes([AllowAny])
def users_collection(request):
	if request.method == "GET":
		users = User.objects.order_by("-created_at")[:50]
		return Response(
			[
				{
					"uid": user.uid,
					"full_name": user.full_name,
					"email": user.email,
					"phone": user.phone,
				}
				for user in users
			]
		)

	payload = request.data
	full_name = payload.get("full_name")
	password_hash = payload.get("password_hash")

	if not full_name or not password_hash:
		return Response(
			{"detail": "full_name and password_hash are required"},
			status=400,
		)

	try:
		user = User(
			uid=payload.get("uid"),
			full_name=full_name,
			email=payload.get("email"),
			phone=payload.get("phone"),
			avatar=payload.get("avatar"),
			password_hash=password_hash,
			fingerprint=payload.get("fingerprint"),
		)
		user.save()
	except (ValidationError, NotUniqueError) as exc:
		return Response({"detail": str(exc)}, status=400)

	return Response(
		{
			"uid": user.uid,
			"full_name": user.full_name,
			"email": user.email,
			"phone": user.phone,
		},
		status=201,
	)


@api_view(["GET"])
@permission_classes([AllowAny])
def user_detail(request, uid):
	user = User.objects(uid=uid).first()
	if user is None:
		return Response({"detail": "user not found"}, status=404)

	return Response(
		{
			"uid": user.uid,
			"full_name": user.full_name,
			"email": user.email,
			"phone": user.phone,
			"avatar": user.avatar,
			"fingerprint": user.fingerprint,
			"created_at": user.created_at,
			"last_sign_in_time": user.last_sign_in_time,
		}
	)


@api_view(["POST"])
@permission_classes([AllowAny])
def firebase_login(request):
	payload = request.data
	id_token = payload.get("id_token")
	provider = payload.get("provider", "firebase")

	if not id_token:
		return Response({"detail": "id_token is required"}, status=400)

	try:
		decoded = verify_id_token(id_token)
	except Exception as exc:
		return Response({"detail": f"invalid firebase token: {exc}"}, status=401)

	fb_uid = decoded.get("uid")
	email = decoded.get("email")
	full_name = decoded.get("name") or "Firebase User"
	avatar = decoded.get("picture")
	now_ts = int(datetime.now().timestamp())

	user = User.objects(uid=fb_uid).first()
	if user is None and email:
		user = User.objects(email=email).first()

	if user is None:
		user = User(
			uid=fb_uid,
			full_name=full_name,
			email=email,
			avatar=avatar,
			password_hash="__firebase__",
			created_at=now_ts,
			last_sign_in_time=now_ts,
		)
	else:
		user.uid = fb_uid or user.uid
		user.full_name = full_name or user.full_name
		user.email = email or user.email
		user.avatar = avatar or user.avatar
		user.last_sign_in_time = now_ts

	try:
		user.save()
	except (ValidationError, NotUniqueError) as exc:
		return Response({"detail": str(exc)}, status=400)

	return Response(
		{
			"uid": user.uid,
			"full_name": user.full_name,
			"email": user.email,
			"avatar": user.avatar,
			"provider": provider,
			"firebase_uid": fb_uid,
		},
		status=200,
	)
