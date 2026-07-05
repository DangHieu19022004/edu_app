from django.core.management.base import BaseCommand
from apps.contact.email_scheduler import send_due_emails


class Command(BaseCommand):
    help = "Send pending scheduled emails whose scheduled_date is due."

    def handle(self, *args, **options):
        result = send_due_emails()
        self.stdout.write(
            self.style.SUCCESS(
                "Done. "
                f"Processed: {result['processed']}, "
                f"Sent: {result['sent']}, "
                f"Failed: {result['failed']}"
            )
        )
