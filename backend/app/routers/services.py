from fastapi import APIRouter
import uuid

router = APIRouter()


@router.get("/services")
def list_services(category: str = None, page: int = 1, limit: int = 20):
    # STUB data — replace with a real Supabase query later.
    fake_service = {
        "service_id": str(uuid.uuid4()),
        "name": "Home Cleaning",
        "category": category or "cleaning",
        "description": "Standard home cleaning service",
        "base_price_amount": 50000,  # paise -> ₹500
        "image_url": "https://example.com/image.jpg",
    }
    return {"results": [fake_service], "total": 1, "page": page, "limit": limit}


@router.get("/services/{service_id}")
def get_service(service_id: str):
    return {
        "service_id": service_id,
        "name": "Home Cleaning",
        "category": "cleaning",
        "description": "Standard home cleaning service",
        "base_price_amount": 50000,
        "image_url": "https://example.com/image.jpg",
        "available_workers_count": 4,
    }
