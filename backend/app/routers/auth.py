from fastapi import APIRouter
from pydantic import BaseModel
import uuid
from datetime import datetime, timezone

# APIRouter = a mini FastAPI app just for auth-related endpoints.
# main.py will "plug this in" under the /api/v1 prefix.
router = APIRouter()


# --- Pydantic models describe the exact shape of request/response JSON ---
# FastAPI uses these to auto-validate incoming data and auto-generate docs.

class RegisterRequest(BaseModel):
    email: str
    password: str
    full_name: str
    phone: str
    role: str  # "CUSTOMER" or "WORKER"


class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/auth/register", status_code=201)
def register(payload: RegisterRequest):
    # STUB: no real Supabase call yet — just returns fake data matching
    # the contract shape so frontend devs can build against it today.
    return {
        "user_id": str(uuid.uuid4()),
        "email": payload.email,
        "role": payload.role,
        "access_token": "fake-token-for-now",
    }


@router.post("/auth/login")
def login(payload: LoginRequest):
    return {
        "user_id": str(uuid.uuid4()),
        "role": "CUSTOMER",
        "access_token": "fake-token-for-now",
    }


@router.get("/auth/me")
def get_me():
    return {
        "user_id": str(uuid.uuid4()),
        "email": "test@example.com",
        "full_name": "Test User",
        "phone": "9999999999",
        "role": "CUSTOMER",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
