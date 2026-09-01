from fastapi import APIRouter
from pydantic import BaseModel
import uuid
from datetime import datetime, timezone

router = APIRouter()


class VerifyWorkerRequest(BaseModel):
    verification_status: str  # VERIFIED | REJECTED
    notes: str = ""


class UpdateComplaintRequest(BaseModel):
    status: str  # OPEN | IN_REVIEW | RESOLVED
    resolution_notes: str = ""


@router.get("/admin/workers")
def list_workers_for_admin(verification_status: str = None, page: int = 1, limit: int = 20):
    fake_worker = {
        "worker_id": str(uuid.uuid4()),
        "full_name": "Test Worker",
        "verification_status": verification_status or "PENDING",
    }
    return {"results": [fake_worker], "total": 1, "page": page, "limit": limit}


@router.patch("/admin/workers/{worker_id}/verify")
def verify_worker(worker_id: str, payload: VerifyWorkerRequest):
    return {"worker_id": worker_id, "verification_status": payload.verification_status}


@router.get("/admin/customers")
def list_customers(page: int = 1, limit: int = 20):
    fake_customer = {"user_id": str(uuid.uuid4()), "full_name": "Test Customer"}
    return {"results": [fake_customer], "total": 1, "page": page, "limit": limit}


@router.get("/admin/bookings")
def list_all_bookings(page: int = 1, limit: int = 20):
    fake_booking = {
        "booking_id": str(uuid.uuid4()),
        "status": "PENDING",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return {"results": [fake_booking], "total": 1, "page": page, "limit": limit}


@router.get("/admin/complaints")
def list_complaints(page: int = 1, limit: int = 20):
    fake_complaint = {
        "complaint_id": str(uuid.uuid4()),
        "booking_id": str(uuid.uuid4()),
        "raised_by": str(uuid.uuid4()),
        "description": "Worker arrived late",
        "status": "OPEN",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return {"results": [fake_complaint], "total": 1, "page": page, "limit": limit}


@router.patch("/admin/complaints/{complaint_id}")
def update_complaint(complaint_id: str, payload: UpdateComplaintRequest):
    return {"complaint_id": complaint_id, "status": payload.status,
            "resolution_notes": payload.resolution_notes}


@router.get("/admin/analytics/summary")
def analytics_summary():
    return {
        "total_bookings": 42,
        "total_revenue_amount": 2100000,
        "active_workers": 8,
        "active_customers": 30,
        "bookings_by_status": {"PENDING": 5, "COMPLETED": 30},
    }
