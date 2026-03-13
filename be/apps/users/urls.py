from django.urls import path

from . import views

urlpatterns = [
    path("", views.users_collection, name="users-collection"),
    path("health/", views.health_check, name="users-health"),
    path("<str:uid>/", views.user_detail, name="user-detail"),
]
