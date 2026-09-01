from fastapi import APIRouter
import uuid
from datetime import datetime, timezone

router = APIRouter()


@router.get("/notifications")
def list_notifications(page: int = 1, limit: int = 20):
    fake_notification = {
        "notification_id": str(uuid.uuid4()),
        "title": "Booking Accepted",
        "body": "Your worker has accepted the booking.",
        "read": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return {"results": [fake_notification], "total": 1, "page": page, "limit": limit}


@router.patch("/notifications/{notification_id}/read")
def mark_read(notification_id: str):
    return {"notification_id": notification_id, "read": True}
