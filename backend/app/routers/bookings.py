from fastapi import APIRouter
from pydantic import BaseModel
import uuid
from datetime import datetime, timezone

router = APIRouter()


class CreateBookingRequest(BaseModel):
    service_id: str
    worker_id: str
    scheduled_at: str
    address: str
    lat: float
    lng: float
    notes: str = ""


class UpdateStatusRequest(BaseModel):
    status: str  # ACCEPTED | IN_PROGRESS | COMPLETED | CANCELLED


@router.post("/bookings", status_code=201)
def create_booking(payload: CreateBookingRequest):
    return {
        "booking_id": str(uuid.uuid4()),
        "status": "PENDING",
        "service_id": payload.service_id,
        "worker_id": payload.worker_id,
        "customer_id": str(uuid.uuid4()),
        "scheduled_at": payload.scheduled_at,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/bookings/{booking_id}")
def get_booking(booking_id: str):
    return {
        "booking_id": booking_id,
        "status": "PENDING",
        "payment_status": "UNPAID",
        "service_id": str(uuid.uuid4()),
        "worker_id": str(uuid.uuid4()),
        "customer_id": str(uuid.uuid4()),
        "scheduled_at": datetime.now(timezone.utc).isoformat(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/bookings")
def list_bookings(status: str = None, page: int = 1, limit: int = 20):
    fake_booking = {
        "booking_id": str(uuid.uuid4()),
        "status": status or "PENDING",
        "service_id": str(uuid.uuid4()),
        "worker_id": str(uuid.uuid4()),
        "customer_id": str(uuid.uuid4()),
        "scheduled_at": datetime.now(timezone.utc).isoformat(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return {"results": [fake_booking], "total": 1, "page": page, "limit": limit}


@router.patch("/bookings/{booking_id}/status")
def update_status(booking_id: str, payload: UpdateStatusRequest):
    return {
        "booking_id": booking_id,
        "status": payload.status,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
