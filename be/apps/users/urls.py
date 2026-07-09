from django.urls import path
from .views import (
    change_password,
    delete_user,
    facebook_login,
    form_login,
    form_register,
    google_login,
    list_users,
    refresh_token,
    send_otp,
    verify_otp,
    verify_token,
)

urlpatterns = [
    path('googlelogin/', google_login, name='google_login'),
    path('facebooklogin/', facebook_login, name='facebook_login'),
    path('formregister/', form_register, name='form_register'),
    path('formlogin/', form_login, name='form_login'),
    path('verify-token/', verify_token, name='verify_token'),
    path("send-otp/", send_otp, name="send_otp"),
    path("verify-otp/", verify_otp, name="verify_otp"),
    path("change-password/", change_password, name="change_password"),
    path("refresh-token/", refresh_token, name="refresh_token"),
    path("list-users/", list_users, name="list_users"),
    path("delete-user/", delete_user, name="delete_user"),
]
