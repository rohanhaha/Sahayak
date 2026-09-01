from typing import Literal, Optional
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, Field
import uuid
from datetime import datetime, timezone

router = APIRouter()


# --- Pydantic Data Contracts (Atom 1.1) ---

class RegisterRequest(BaseModel):
    email: str = Field(..., min_length=5, description="User email address")
    password: str = Field(..., min_length=6, description="Password (min 6 characters)")
    full_name: str = Field(..., min_length=2, description="User full name")
    phone: Optional[str] = Field(None, description="Contact phone number")
    role: Literal["CUSTOMER", "WORKER"] = Field(..., description="Role must be CUSTOMER or WORKER")


class LoginRequest(BaseModel):
    email: str = Field(..., min_length=5, description="User email address")
    password: str = Field(..., min_length=1, description="Password")


class AuthResponse(BaseModel):
    user_id: str
    email: str
    full_name: str
    role: str
    access_token: str


class UserProfileResponse(BaseModel):
    user_id: str
    email: str
    full_name: str
    phone: Optional[str] = None
    role: str
    created_at: str



from app.core.supabase import get_supabase

@router.post("/auth/register", response_model=AuthResponse, status_code=201)
def register(payload: RegisterRequest):
    supabase = get_supabase()
    
    try:
        user_id = None
        token = None

        # 1. Attempt user creation in Supabase Auth
        try:
            auth_response = supabase.auth.admin.create_user({
                "email": payload.email,
                "password": payload.password,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": payload.full_name,
                    "role": payload.role
                }
            })
            if auth_response and auth_response.user:
                user_id = str(auth_response.user.id)
        except Exception:
            auth_response = supabase.auth.sign_up({
                "email": payload.email,
                "password": payload.password,
                "options": {
                    "data": {
                        "full_name": payload.full_name,
                        "role": payload.role
                    }
                }
            })
            if auth_response and auth_response.user:
                user_id = str(auth_response.user.id)
                if auth_response.session:
                    token = auth_response.session.access_token

        if not user_id:
            raise HTTPException(status_code=400, detail="Failed to create user account.")

        # 2. Insert into public.profiles
        try:
            supabase.table("profiles").insert({
                "user_id": user_id,
                "full_name": payload.full_name,
                "phone": payload.phone,
                "role": payload.role
            }).execute()
        except Exception:
            pass

        # 3. If WORKER, initialize public.worker_profiles
        if payload.role == "WORKER":
            try:
                supabase.table("worker_profiles").insert({
                    "worker_id": user_id,
                    "skills": [],
                    "certificates": [],
                    "rating_avg": 0.0,
                    "rating_count": 0,
                    "verification_status": "PENDING"
                }).execute()
            except Exception:
                pass

        # 4. Sign in to obtain access token if needed
        if not token:
            try:
                session_response = supabase.auth.sign_in_with_password({
                    "email": payload.email,
                    "password": payload.password
                })
                if session_response and session_response.session:
                    token = session_response.session.access_token
            except Exception:
                token = "session_active"

        return {
            "user_id": user_id,
            "email": payload.email,
            "full_name": payload.full_name,
            "role": payload.role,
            "access_token": token or "session_active"
        }

    except HTTPException:
        raise
    except Exception as e:
        err_str = str(e)
        if "already registered" in err_str.lower() or "unique" in err_str.lower():
            raise HTTPException(status_code=400, detail="User with this email already exists.")
        raise HTTPException(status_code=500, detail=f"Registration failed: {err_str}")


@router.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest):
    supabase = get_supabase()
    
    try:
        # 1. Authenticate with Supabase Auth
        auth_response = supabase.auth.sign_in_with_password({
            "email": payload.email,
            "password": payload.password
        })

        if not auth_response.user or not auth_response.session:
            raise HTTPException(status_code=401, detail="Invalid email or password.")

        user_id = str(auth_response.user.id)
        token = auth_response.session.access_token

        # 2. Fetch User Profile from public.profiles
        profile_res = (
            supabase.table("profiles")
            .select("full_name, role")
            .eq("user_id", user_id)
            .execute()
        )

        if not profile_res.data:
            full_name = auth_response.user.user_metadata.get("full_name", "User")
            role = auth_response.user.user_metadata.get("role", "CUSTOMER")
        else:
            profile = profile_res.data[0]
            full_name = profile.get("full_name", "User")
            role = profile.get("role", "CUSTOMER")

        return {
            "user_id": user_id,
            "email": payload.email,
            "full_name": full_name,
            "role": role,
            "access_token": token
        }

    except HTTPException:
        raise
    except Exception as e:
        err_msg = str(e)
        if "invalid" in err_msg.lower() or "credentials" in err_msg.lower():
            raise HTTPException(status_code=401, detail="Invalid email or password.")
        raise HTTPException(status_code=500, detail=f"Login failed: {err_msg}")


@router.get("/auth/me", response_model=UserProfileResponse)
def get_me(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid Authorization header. Expected 'Bearer <token>'."
        )

    token = authorization.split(" ")[1]
    supabase = get_supabase()

    try:
        # 1. Verify token signature with Supabase Auth
        user_response = supabase.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired session token.")

        user = user_response.user
        user_id = str(user.id)

        # 2. Fetch Profile from public.profiles
        profile_res = (
            supabase.table("profiles")
            .select("user_id, full_name, phone, role, created_at")
            .eq("user_id", user_id)
            .execute()
        )

        if not profile_res.data:
            return {
                "user_id": user_id,
                "email": user.email or "",
                "full_name": user.user_metadata.get("full_name", "User"),
                "phone": user.phone,
                "role": user.user_metadata.get("role", "CUSTOMER"),
                "created_at": user.created_at or datetime.now(timezone.utc).isoformat(),
            }

        profile = profile_res.data[0]
        return {
            "user_id": profile["user_id"],
            "email": user.email or "",
            "full_name": profile["full_name"],
            "phone": profile.get("phone"),
            "role": profile["role"],
            "created_at": profile.get("created_at") or datetime.now(timezone.utc).isoformat(),
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")

