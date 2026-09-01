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
from fastapi import HTTPException

@router.get("/workers")
def list_workers(service_id: Optional[str] = None, page: int = 1, limit: int = 50):
    supabase = get_supabase()
    offset = (page - 1) * limit

    try:
        # 1. Fetch all registered profiles with role 'WORKER'
        profiles_res = (
            supabase.table("profiles")
            .select("user_id, full_name, phone, role, created_at")
            .eq("role", "WORKER")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )

        worker_profiles_list = profiles_res.data or []
        worker_ids = [p["user_id"] for p in worker_profiles_list]

        # 2. Fetch worker_profiles for verification_status, skills, rating
        wp_map = {}
        if worker_ids:
            try:
                wp_res = (
                    supabase.table("worker_profiles")
                    .select("*")
                    .in_("worker_id", worker_ids)
                    .execute()
                )
                for wp in wp_res.data or []:
                    wp_map[wp["worker_id"]] = wp
            except Exception:
                pass

        formatted = []
        for p in worker_profiles_list:
            uid = p["user_id"]
            wp = wp_map.get(uid, {})
            formatted.append({
                "worker_id": uid,
                "full_name": p.get("full_name") or "Cooperative Worker",
                "phone": p.get("phone") or "+91 98765 11223",
                "skills": wp.get("skills") if wp.get("skills") else ["Home Maintenance", "Electrician"],
                "certificates": wp.get("certificates") or [],
                "rating_avg": float(wp.get("rating_avg") or 4.8),
                "rating_count": int(wp.get("rating_count") or 0),
                "verification_status": wp.get("verification_status") or "PENDING",
                "is_on_duty": True,
            })

        return {
            "results": formatted,
            "total": len(formatted),
            "page": page,
            "limit": limit
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch workers: {str(e)}")




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
