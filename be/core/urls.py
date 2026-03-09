from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()

# Register your viewsets here
# router.register(r'example', ExampleViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('health/', views.health_check, name='health-check'),
]
