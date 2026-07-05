from django.apps import AppConfig


class ContactConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.contact"

    def ready(self):
        from apps.contact.email_scheduler import start_email_scheduler

        start_email_scheduler()
