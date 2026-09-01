from fastapi import APIRouter
from pydantic import BaseModel
import uuid
from datetime import datetime, timezone

router = APIRouter()


class CreateReviewRequest(BaseModel):
    booking_id: str
    rating: int
    comment: str = ""


@router.post("/reviews", status_code=201)
def create_review(payload: CreateReviewRequest):
    return {
        "review_id": str(uuid.uuid4()),
        "booking_id": payload.booking_id,
        "rating": payload.rating,
        "comment": payload.comment,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/workers/{worker_id}/reviews")
def list_worker_reviews(worker_id: str, page: int = 1, limit: int = 20):
    fake_review = {
        "rating": 5,
        "comment": "Great service!",
        "customer_name": "Test Customer",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return {"results": [fake_review], "total": 1, "page": page, "limit": limit}
