from mongoengine.errors import NotUniqueError, ValidationError
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

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
