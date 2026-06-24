from django.conf import settings
from django.core.mail import send_mail
from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.contact.models import EmailSchedule


class Command(BaseCommand):
    help = "Send pending scheduled emails whose scheduled_date is due."

    def handle(self, *args, **options):
        now = timezone.now()
        pending_emails = EmailSchedule.objects.filter(status="pending", scheduled_date__lte=now)
        total_due = pending_emails.count()

        sent_count = 0
        failed_count = 0

        for email in pending_emails:
            recipient_list = [recipient.strip() for recipient in (email.recipients or "").split(",") if recipient.strip()]
            if not recipient_list:
                failed_count += 1
                self.stderr.write(
                    self.style.ERROR(f"Skip email {email.id}: empty recipients")
                )
                continue

            try:
                send_mail(
                    subject=email.subject,
                    message=email.message,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=recipient_list,
                    fail_silently=False,
                )
                email.status = "sent"
                email.save()
                sent_count += 1
            except Exception as exc:
                failed_count += 1
                self.stderr.write(
                    self.style.ERROR(f"Failed to send email {email.id}: {exc}")
                )

        self.stdout.write(
            self.style.SUCCESS(
                f"Done. Sent: {sent_count}, Failed: {failed_count}, Total due: {total_due}"
            )
        )
