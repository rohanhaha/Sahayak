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


@router.get("/workers")
def list_workers(service_id: str = None, lat: float = None, lng: float = None,
                  radius_km: float = None, page: int = 1, limit: int = 20):
    fake_worker = {
        "worker_id": str(uuid.uuid4()),
        "full_name": "Test Worker",
        "skills": ["cleaning", "plumbing"],
        "rating_avg": 4.5,
        "rating_count": 12,
        "distance_km": 2.3,
        "available": True,
    }
    return {"results": [fake_worker], "total": 1, "page": page, "limit": limit}


@router.get("/workers/{worker_id}")
def get_worker(worker_id: str):
    return {
        "worker_id": worker_id,
        "full_name": "Test Worker",
        "skills": ["cleaning", "plumbing"],
        "certificates": [{"name": "Plumbing License", "file_url": "https://example.com/cert.pdf"}],
        "rating_avg": 4.5,
        "rating_count": 12,
        "availability": [{"day_of_week": "MON", "start_time": "09:00", "end_time": "17:00"}],
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
