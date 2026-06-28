"""FCM push notification service."""
import logging
from typing import Optional
logger = logging.getLogger(__name__)


class NotificationService:
    def __init__(self):
        self.fcm_app = None
        self._init_firebase()

    def _init_firebase(self):
        try:
            import firebase_admin
            from firebase_admin import credentials
            from app.core.config import settings
            import os
            if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                self.fcm_app = firebase_admin.initialize_app(cred)
                logger.info("Firebase initialized")
        except Exception as e:
            logger.warning(f"Firebase not available: {e}")

    async def send_push(self, fcm_token: str, title: str, body: str, data: dict = None):
        if not self.fcm_app or not fcm_token:
            logger.info(f"[MOCK PUSH] To: {fcm_token} | {title}: {body}")
            return
        try:
            from firebase_admin import messaging
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                token=fcm_token,
            )
            messaging.send(message)
        except Exception as e:
            logger.error(f"FCM send failed: {e}")

    async def notify_status_update(self, fcm_token: str, ticket: str, new_status: str):
        status_messages = {
            "verified": ("✅ Report Verified", f"Ticket {ticket} has been verified by authorities."),
            "in_progress": ("🔧 Work Started", f"Team is working on your report {ticket}."),
            "resolved": ("🎉 Issue Resolved!", f"Your report {ticket} has been resolved. +25 points awarded!"),
            "rejected": ("❌ Report Rejected", f"Ticket {ticket} could not be verified. Trust score updated."),
        }
        title, body = status_messages.get(new_status, ("Update", f"Ticket {ticket} status changed to {new_status}"))
        await self.send_push(fcm_token, title, body, {"ticket": ticket, "status": new_status})


notification_service = NotificationService()
