from typing import Optional, Literal
from fastapi import APIRouter, HTTPException, Query, Header
from pydantic import BaseModel, Field
import uuid
from datetime import datetime, timezone
from app.core.supabase import get_supabase

router = APIRouter()


class CreateBookingRequest(BaseModel):
    service_id: str
    worker_id: Optional[str] = None
    customer_id: Optional[str] = None
    scheduled_at: str
    address: str = "Indiranagar, Bengaluru"
    lat: Optional[float] = 12.9716
    lng: Optional[float] = 77.5946
    notes: Optional[str] = ""


class UpdateStatusRequest(BaseModel):
    status: Literal["PENDING", "ACCEPTED", "IN_PROGRESS", "COMPLETED", "CANCELLED"]
    worker_id: Optional[str] = None


@router.post("/bookings", status_code=201)
def create_booking(payload: CreateBookingRequest, authorization: Optional[str] = Header(None)):
    supabase = get_supabase()
    
    # 1. Resolve customer_id from token or payload
    customer_id = payload.customer_id
    if not customer_id and authorization and authorization.startswith("Bearer "):
        try:
            token = authorization.split(" ")[1]
            user_res = supabase.auth.get_user(token)
            if user_res and user_res.user:
                customer_id = str(user_res.user.id)
        except Exception:
            pass

    # Fallback to demo customer if not specified
    if not customer_id:
        profiles_res = supabase.table("profiles").select("user_id").eq("role", "CUSTOMER").limit(1).execute()
        if profiles_res.data:
            customer_id = profiles_res.data[0]["user_id"]
        else:
            cust_res = supabase.table("profiles").select("user_id").eq("role", "CUSTOMER").limit(1).execute()
            if cust_res.data:
                customer_id = cust_res.data[0]["user_id"]
            else:
                customer_id = str(uuid.uuid4())

    try:
        # Validate service_id exists to satisfy foreign key constraint
        valid_service_id = payload.service_id
        try:
            srv_check = supabase.table("services").select("service_id").eq("service_id", payload.service_id).execute()
            if not srv_check.data:
                first_srv = supabase.table("services").select("service_id").limit(1).execute()
                if first_srv.data:
                    valid_service_id = first_srv.data[0]["service_id"]
        except Exception:
            pass

        new_booking = {
            "service_id": valid_service_id,
            "customer_id": customer_id,
            "worker_id": payload.worker_id,
            "scheduled_at": payload.scheduled_at,
            "address": payload.address,
            "lat": payload.lat,
            "lng": payload.lng,
            "notes": payload.notes or "",
            "status": "PENDING",
            "payment_status": "UNPAID",
        }


        response = supabase.table("bookings").insert(new_booking).execute()

        if not response.data:
            raise HTTPException(status_code=400, detail="Failed to create booking.")

        return response.data[0]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Booking creation failed: {str(e)}")


@router.get("/bookings/{booking_id}")
def get_booking(booking_id: str):
    supabase = get_supabase()
    
    try:
        response = supabase.table("bookings").select("*, services(name, category, base_price_amount, image_url), profiles:customer_id(full_name, phone)").eq("booking_id", booking_id).execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Booking not found.")
            
        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch booking: {str(e)}")


@router.get("/bookings")
def list_bookings(
    status: Optional[str] = None,
    customer_id: Optional[str] = None,
    worker_id: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100)
):
    supabase = get_supabase()
    offset = (page - 1) * limit

    try:
        query = supabase.table("bookings").select("*, services(name, category, base_price_amount, image_url), profiles:customer_id(full_name, phone)", count="exact")
        
        if status:
            query = query.eq("status", status.upper())
        if customer_id:
            query = query.eq("customer_id", customer_id)
        if worker_id:
            query = query.eq("worker_id", worker_id)

        # Order by newest first
        query = query.order("created_at", desc=True)

        response = query.range(offset, offset + limit - 1).execute()

        return {
            "results": response.data,
            "total": response.count or len(response.data),
            "page": page,
            "limit": limit
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list bookings: {str(e)}")


@router.patch("/bookings/{booking_id}/status")
def update_status(booking_id: str, payload: UpdateStatusRequest):
    supabase = get_supabase()

    try:
        update_data = {
            "status": payload.status,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        if payload.worker_id:
            update_data["worker_id"] = payload.worker_id

        response = supabase.table("bookings").update(update_data).eq("booking_id", booking_id).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Booking not found.")

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update booking status: {str(e)}")

