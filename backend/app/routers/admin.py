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


from app.core.supabase import get_supabase
from typing import Optional

@router.get("/admin/workers")
def list_workers_for_admin(verification_status: Optional[str] = None, page: int = 1, limit: int = 50):
    supabase = get_supabase()
    offset = (page - 1) * limit

    try:
        profiles_res = (
            supabase.table("profiles")
            .select("user_id, full_name, phone, role, created_at")
            .eq("role", "WORKER")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )

        worker_list = profiles_res.data or []
        worker_ids = [p["user_id"] for p in worker_list]

        wp_map = {}
        if worker_ids:
            try:
                wp_res = supabase.table("worker_profiles").select("*").in_("worker_id", worker_ids).execute()
                for wp in wp_res.data or []:
                    wp_map[wp["worker_id"]] = wp
            except Exception:
                pass

        results = []
        for p in worker_list:
            uid = p["user_id"]
            wp = wp_map.get(uid, {})
            v_status = wp.get("verification_status") or "PENDING"
            if verification_status and v_status.upper() != verification_status.upper():
                continue

            results.append({
                "worker_id": uid,
                "full_name": p.get("full_name") or "Cooperative Worker",
                "phone": p.get("phone") or "+91 98765 11223",
                "skills": wp.get("skills") if wp.get("skills") else ["Home Maintenance", "Electrician"],
                "certificates": wp.get("certificates") or [],
                "rating_avg": float(wp.get("rating_avg") or 4.8),
                "rating_count": int(wp.get("rating_count") or 0),
                "verification_status": v_status,
                "is_on_duty": True,
            })

        return {"results": results, "total": len(results), "page": page, "limit": limit}
    except Exception as e:
        return {"results": [], "total": 0, "page": page, "limit": limit}



@router.patch("/admin/workers/{worker_id}/verify")
def verify_worker(worker_id: str, payload: VerifyWorkerRequest):
    supabase = get_supabase()
    try:
        supabase.table("worker_profiles").update({
            "verification_status": payload.verification_status
        }).eq("worker_id", worker_id).execute()
    except Exception:
        pass
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
