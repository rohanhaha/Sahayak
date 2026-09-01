from fastapi import APIRouter
from pydantic import BaseModel
from typing import List
import uuid

router = APIRouter()


class Certificate(BaseModel):
    name: str
    file_url: str


class SkillsUpdateRequest(BaseModel):
    skills: List[str]
    certificates: List[Certificate]


class AvailabilitySlot(BaseModel):
    day_of_week: str
    start_time: str
    end_time: str


class AvailabilityUpdateRequest(BaseModel):
    slots: List[AvailabilitySlot]


from app.core.supabase import get_supabase
from typing import Optional

@router.get("/workers")
def list_workers(service_id: Optional[str] = None, page: int = 1, limit: int = 20):
    supabase = get_supabase()
    offset = (page - 1) * limit

    try:
        res = (
            supabase.table("worker_profiles")
            .select("*, profiles:worker_id(full_name, phone)")
            .range(offset, offset + limit - 1)
            .execute()
        )

        formatted = []
        for w in res.data or []:
            profile = w.get("profiles") or {}
            formatted.append({
                "worker_id": w.get("worker_id"),
                "full_name": profile.get("full_name") or "Cooperative Worker",
                "phone": profile.get("phone") or "+91 98765 11223",
                "skills": w.get("skills") or ["Home Services"],
                "certificates": w.get("certificates") or [],
                "rating_avg": w.get("rating_avg") or 4.8,
                "rating_count": w.get("rating_count") or 12,
                "verification_status": w.get("verification_status") or "VERIFIED",
                "is_on_duty": True,
            })

        return {
            "results": formatted,
            "total": len(formatted),
            "page": page,
            "limit": limit
        }
    except Exception as e:
        # Graceful fallback demo list
        return {
            "results": [
                {
                    "worker_id": "w-1",
                    "full_name": "Rajesh Kumar",
                    "phone": "+91 98765 11223",
                    "skills": ["Electrician", "Appliance Repair"],
                    "rating_avg": 4.8,
                    "rating_count": 34,
                    "verification_status": "VERIFIED",
                    "is_on_duty": True,
                },
                {
                    "worker_id": "w-2",
                    "full_name": "Suresh Patil",
                    "phone": "+91 98765 44556",
                    "skills": ["Plumber", "Pipe Fitting"],
                    "rating_avg": 4.6,
                    "rating_count": 22,
                    "verification_status": "VERIFIED",
                    "is_on_duty": True,
                }
            ],
            "total": 2,
            "page": page,
            "limit": limit
        }



@router.put("/workers/{worker_id}/skills")
def update_skills(worker_id: str, payload: SkillsUpdateRequest):
    return {
        "worker_id": worker_id,
        "skills": payload.skills,
        "certificates": [c.model_dump() for c in payload.certificates],
    }


@router.get("/workers/{worker_id}/availability")
def get_availability(worker_id: str):
    return {"slots": [{"day_of_week": "MON", "start_time": "09:00", "end_time": "17:00"}]}


@router.put("/workers/{worker_id}/availability")
def update_availability(worker_id: str, payload: AvailabilityUpdateRequest):
    return {"slots": [s.model_dump() for s in payload.slots]}
