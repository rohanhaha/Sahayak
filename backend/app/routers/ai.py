import os
import json
import urllib.request
import urllib.error
from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

router = APIRouter()

class DiagnoseRequest(BaseModel):
    message: str = Field(..., description="Customer's description of their issue")

class DiagnoseResponse(BaseModel):
    reply: str
    service_id: Optional[str] = None
    service_name: Optional[str] = None
    category: Optional[str] = None
    price_formatted: Optional[str] = None

SERVICES_CATALOG = {
    "plumber": {
        "service_id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
        "service_name": "Plumbing Inspection & Repair",
        "category": "Plumber",
        "price_formatted": "₹399"
    },
    "electrician": {
        "service_id": "d3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44",
        "service_name": "Electrician Home Service",
        "category": "Electrician",
        "price_formatted": "₹299"
    },
    "appliance": {
        "service_id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
        "service_name": "AC Service & Repair",
        "category": "Appliance",
        "price_formatted": "₹599"
    },
    "cleaning": {
        "service_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        "service_name": "Home Deep Cleaning",
        "category": "Cleaning",
        "price_formatted": "₹1,499"
    },
    "pest_control": {
        "service_id": "e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55",
        "service_name": "Pest Control Treatment",
        "category": "Pest Control",
        "price_formatted": "₹899"
    }
}

SYSTEM_PROMPT = """You are Sahayak AI, an intelligent home service diagnostic assistant for the Sahayak Worker Cooperative Platform.
Your job is to:
1. Empathize with the customer's household problem in 1-2 concise sentences.
2. Recommend the best matching cooperative service category from these exact options:
   - "plumber" (pipe leaks, tap repair, drain blockage, water pressure)
   - "electrician" (short circuit, switchboard spark, fan repair, wiring, MCB trip)
   - "appliance" (AC cooling issue, gas refill, appliance breakdown)
   - "cleaning" (deep home cleaning, kitchen scrubbing, bathroom sanitization)
   - "pest_control" (cockroaches, termites, bed bugs, insects)
   - "none" (if unrelated to household repair)

You MUST respond strictly with a valid JSON object matching this schema:
{
  "reply": "Your brief 1-2 sentence response to the user",
  "category": "plumber" | "electrician" | "appliance" | "cleaning" | "pest_control" | "none"
}
Do not include markdown backticks or any extra formatting, output raw JSON only.
"""

@router.post("/ai/diagnose", response_model=DiagnoseResponse)
def diagnose_issue(payload: DiagnoseRequest):
    user_msg = payload.message.strip()
    api_key = os.getenv("GEMINI_API_KEY", "").strip()

    if api_key:
        try:
            # Call Gemini 2.5 Flash / 1.5 Flash REST endpoint
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
            body = {
                "system_instruction": {
                    "parts": [{"text": SYSTEM_PROMPT}]
                },
                "contents": [
                    {
                        "role": "user",
                        "parts": [{"text": user_msg}]
                    }
                ],
                "generationConfig": {
                    "response_mime_type": "application/json",
                    "temperature": 0.2
                }
            }
            
            req = urllib.request.Request(
                url,
                data=json.dumps(body).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=8) as resp:
                result_data = json.loads(resp.read().decode("utf-8"))
                text_out = result_data["candidates"][0]["content"]["parts"][0]["text"]
                parsed = json.loads(text_out)
                
                cat = parsed.get("category", "none").lower()
                reply = parsed.get("reply", "I can help connect you with our cooperative technician.")
                
                srv = SERVICES_CATALOG.get(cat)
                if srv:
                    return DiagnoseResponse(
                        reply=reply,
                        service_id=srv["service_id"],
                        service_name=srv["service_name"],
                        category=srv["category"],
                        price_formatted=srv["price_formatted"]
                    )
                else:
                    return DiagnoseResponse(reply=reply)
        except Exception as e:
            # Fallback to smart rule-based matching if Gemini API is unreachable or rate limited
            pass

    # Instant deterministic fallback for 100% demo resilience
    lower_msg = user_msg.lower()
    if any(k in lower_msg for k in ["pipe", "leak", "tap", "drain", "water", "plumb", "sink", "flush"]):
        srv = SERVICES_CATALOG["plumber"]
        return DiagnoseResponse(
            reply="It sounds like you have a plumbing leak or drainage issue. A certified cooperative plumber can inspect and fix this right away.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower_msg for k in ["spark", "switch", "electric", "wire", "mcb", "fan", "fuse", "power", "shock"]):
        srv = SERVICES_CATALOG["electrician"]
        return DiagnoseResponse(
            reply="Electrical faults and sparking can be hazardous. Our certified cooperative electrician is available to inspect your wiring safely.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower_msg for k in ["ac", "cool", "air condition", "gas", "filter", "compressor"]):
        srv = SERVICES_CATALOG["appliance"]
        return DiagnoseResponse(
            reply="Your AC may need filter cleaning or a refrigerant gas pressure check. Our cooperative AC technicians provide foam jet servicing.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower_msg for k in ["clean", "dust", "deep clean", "scrub", "sanitize", "stain"]):
        srv = SERVICES_CATALOG["cleaning"]
        return DiagnoseResponse(
            reply="For a spotless home, our cooperative deep cleaning team provides comprehensive floor scrubbing, kitchen degreasing, and sanitization.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower_msg for k in ["pest", "cockroach", "ant", "termite", "bug", "insect", "rodent"]):
        srv = SERVICES_CATALOG["pest_control"]
        return DiagnoseResponse(
            reply="Pest infestations should be treated with odorless, safe solutions. Our certified team provides targeted pest control treatment.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    else:
        srv = SERVICES_CATALOG["cleaning"]
        return DiagnoseResponse(
            reply="I can help you book certified cooperative professionals for plumbing, electrical, AC servicing, cleaning, or pest control.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
