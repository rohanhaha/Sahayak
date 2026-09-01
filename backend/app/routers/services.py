# backend/app/routers/services.py
from fastapi import APIRouter, HTTPException, Query
from app.core.supabase import get_supabase

router = APIRouter()

@router.get("/services")
def list_services(
    category: str = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100)
):
    supabase = get_supabase()
    offset = (page - 1) * limit
    
    query = supabase.table("services").select("*", count="exact")
    if category:
        query = query.eq("category", category)
    
    response = query.range(offset, offset + limit - 1).execute()
    
    return {
        "results": response.data,
        "total": response.count or len(response.data),
        "page": page,
        "limit": limit
    }

@router.get("/services/{service_id}")
def get_service(service_id: str):
    supabase = get_supabase()
    response = supabase.table("services").select("*").eq("service_id", service_id).execute()
    
    if not response.data:
        raise HTTPException(status_code=404, detail="Service not found")
        
    return response.data[0]