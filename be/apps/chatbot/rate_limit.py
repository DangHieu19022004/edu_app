import time

from .models import ChatbotRateLimit, ChatbotSpamLog


RATE_LIMIT_ERROR_MESSAGE = "Bạn đang gửi tin nhắn quá nhanh. Vui lòng thử lại sau."
SHORT_TERM_WINDOW_SECONDS = 60
GENERAL_SHORT_TERM_LIMIT = 5
RESULT_ANALYSIS_SHORT_TERM_LIMIT = 3
MEDIUM_TERM_LIMIT = 20
MEDIUM_TERM_WINDOW_SECONDS = 10 * 60
MEDIUM_TERM_BLOCK_SECONDS = 5 * 60

GENERAL_CONTEXT = "general"
RESULT_ANALYSIS_CONTEXT = "result_analysis"

SHORT_TERM_FIELDS = {
    GENERAL_CONTEXT: (
        "general_short_term_count",
        "general_short_term_window_start",
        GENERAL_SHORT_TERM_LIMIT,
    ),
    RESULT_ANALYSIS_CONTEXT: (
        "result_analysis_short_term_count",
        "result_analysis_short_term_window_start",
        RESULT_ANALYSIS_SHORT_TERM_LIMIT,
    ),
}


def _log_spam(user_id, action, message_count, window):
    try:
        ChatbotSpamLog(
            user_id=user_id,
            action=action,
            message_count=message_count,
            window=window,
        ).save()
    except Exception as exc:
        print(f"Chatbot spam log error: {exc}")


def _get_or_create_rate_limit(user_id, now_ts):
    rate_limit = ChatbotRateLimit.objects(user_id=user_id).first()
    if rate_limit is not None:
        return rate_limit

    rate_limit = ChatbotRateLimit(
        user_id=user_id,
        short_term_window_start=now_ts,
        general_short_term_window_start=now_ts,
        result_analysis_short_term_window_start=now_ts,
        medium_term_window_start=now_ts,
        created_at=now_ts,
        updated_at=now_ts,
    )
    rate_limit.save()
    return rate_limit


def check_chatbot_rate_limit(user_id, context_mode=GENERAL_CONTEXT):
    now_ts = int(time.time())
    rate_limit = _get_or_create_rate_limit(user_id, now_ts)
    context_mode = (
        context_mode if context_mode in SHORT_TERM_FIELDS else GENERAL_CONTEXT
    )
    count_field, window_start_field, short_term_limit = SHORT_TERM_FIELDS[context_mode]

    if rate_limit.blocked_until and rate_limit.blocked_until > now_ts:
        retry_after = rate_limit.blocked_until - now_ts
        _log_spam(
            user_id=user_id,
            action="CHATBOT_BLOCKED",
            message_count=rate_limit.medium_term_count,
            window="5m_block",
        )
        return False, RATE_LIMIT_ERROR_MESSAGE, retry_after

    short_term_window_start = getattr(rate_limit, window_start_field, 0)
    if now_ts - short_term_window_start >= SHORT_TERM_WINDOW_SECONDS:
        setattr(rate_limit, count_field, 0)
        setattr(rate_limit, window_start_field, now_ts)

    if now_ts - rate_limit.medium_term_window_start >= MEDIUM_TERM_WINDOW_SECONDS:
        rate_limit.medium_term_count = 0
        rate_limit.medium_term_window_start = now_ts

    if rate_limit.medium_term_count >= MEDIUM_TERM_LIMIT:
        rate_limit.blocked_until = now_ts + MEDIUM_TERM_BLOCK_SECONDS
        rate_limit.updated_at = now_ts
        rate_limit.save()
        _log_spam(
            user_id=user_id,
            action="CHATBOT_MEDIUM_LIMIT",
            message_count=rate_limit.medium_term_count,
            window="10m",
        )
        return False, RATE_LIMIT_ERROR_MESSAGE, MEDIUM_TERM_BLOCK_SECONDS

    short_term_count = getattr(rate_limit, count_field, 0)
    if short_term_count >= short_term_limit:
        rate_limit.updated_at = now_ts
        rate_limit.save()
        retry_after = max(
            1,
            SHORT_TERM_WINDOW_SECONDS - (now_ts - getattr(rate_limit, window_start_field)),
        )
        _log_spam(
            user_id=user_id,
            action=f"CHATBOT_SHORT_LIMIT_{context_mode.upper()}",
            message_count=short_term_count,
            window=f"{context_mode}_60s",
        )
        return False, RATE_LIMIT_ERROR_MESSAGE, retry_after

    setattr(rate_limit, count_field, short_term_count + 1)
    rate_limit.medium_term_count += 1
    rate_limit.updated_at = now_ts
    rate_limit.save()
    return True, "", 0
