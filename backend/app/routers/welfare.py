from fastapi import APIRouter
import uuid

router = APIRouter()


@router.get("/workers/{worker_id}/welfare-schemes")
def list_schemes(worker_id: str):
    fake_scheme = {
        "scheme_id": str(uuid.uuid4()),
        "name": "Health Insurance",
        "description": "Basic health coverage for gig workers",
        "enrollment_status": "PENDING",
    }
    return [fake_scheme]


@router.post("/workers/{worker_id}/welfare-schemes/{scheme_id}/enroll")
def enroll(worker_id: str, scheme_id: str):
    return {"scheme_id": scheme_id, "enrollment_status": "ENROLLED"}
