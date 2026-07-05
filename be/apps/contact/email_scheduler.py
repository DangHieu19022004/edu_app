import logging
import os
import sys
import threading
import time

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone

from apps.contact.models import EmailSchedule


logger = logging.getLogger(__name__)

_scheduler_lock = threading.Lock()
_scheduler_started = False


def _scheduler_enabled():
    return os.getenv("CONTACT_EMAIL_SCHEDULER_ENABLED", "True") == "True"


def _poll_seconds():
    raw_value = os.getenv("CONTACT_EMAIL_SCHEDULER_POLL_SECONDS", "30").strip()
    try:
        return max(5, int(raw_value))
    except ValueError:
        return 30


def _batch_size():
    raw_value = os.getenv("CONTACT_EMAIL_SCHEDULER_BATCH_SIZE", "20").strip()
    try:
        return max(1, int(raw_value))
    except ValueError:
        return 20


def _should_start_in_this_process():
    if not _scheduler_enabled():
        return False

    argv = sys.argv[1:]
    command = argv[0] if argv else ""

    skipped_commands = {
        "makemigrations",
        "migrate",
        "collectstatic",
        "shell",
        "dbshell",
        "test",
        "send_pending_emails",
    }
    if command in skipped_commands:
        return False

    if command == "runserver" and os.environ.get("RUN_MAIN") != "true":
        return False

    return True


def _claim_due_email():
    now = timezone.now()
    candidates = (
        EmailSchedule.objects(status="pending", scheduled_date__lte=now)
        .order_by("scheduled_date")
        .only("id")
    )

    for candidate in candidates:
        claimed = EmailSchedule.objects(id=candidate.id, status="pending").modify(
            new=True,
            set__status="sending",
        )
        if claimed:
            return claimed

    return None


def send_due_emails(batch_size=None):
    processed = 0
    sent_count = 0
    failed_count = 0
    limit = batch_size

    while limit is None or processed < limit:
        email = _claim_due_email()
        if email is None:
            break

        processed += 1
        recipient_list = [
            recipient.strip()
            for recipient in (email.recipients or "").split(",")
            if recipient.strip()
        ]

        if not recipient_list:
            failed_count += 1
            EmailSchedule.objects(id=email.id).update_one(set__status="pending")
            logger.warning("Skip email %s: empty recipients", email.id)
            continue

        try:
            send_mail(
                subject=email.subject,
                message=email.message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=recipient_list,
                fail_silently=False,
            )
            EmailSchedule.objects(id=email.id).update_one(set__status="sent")
            sent_count += 1
        except Exception:
            failed_count += 1
            EmailSchedule.objects(id=email.id).update_one(set__status="pending")
            logger.exception("Failed to send scheduled email %s", email.id)

    return {
        "processed": processed,
        "sent": sent_count,
        "failed": failed_count,
    }


def _scheduler_loop():
    poll_seconds = _poll_seconds()
    logger.info("Contact email scheduler started with poll interval %ss", poll_seconds)

    while True:
        try:
            result = send_due_emails(batch_size=_batch_size())
            if result["processed"] > 0:
                logger.info(
                    "Contact email scheduler processed=%s sent=%s failed=%s",
                    result["processed"],
                    result["sent"],
                    result["failed"],
                )
        except Exception:
            logger.exception("Contact email scheduler loop crashed")

        time.sleep(poll_seconds)


def start_email_scheduler():
    global _scheduler_started

    if not _should_start_in_this_process():
        return

    with _scheduler_lock:
        if _scheduler_started:
            return

        worker = threading.Thread(
            target=_scheduler_loop,
            name="contact-email-scheduler",
            daemon=True,
        )
        worker.start()
        _scheduler_started = True
