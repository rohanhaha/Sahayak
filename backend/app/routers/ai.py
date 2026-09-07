import os
import json
import urllib.request
import urllib.error
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
from dotenv import load_dotenv

load_dotenv()

router = APIRouter()

class ChatTurn(BaseModel):
    role: str # "user" or "assistant"
    content: str

class DiagnoseRequest(BaseModel):
    message: str = Field(..., description="Latest customer message")
    history: Optional[List[ChatTurn]] = Field(default=[], description="Previous conversation turns")

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

SYSTEM_INSTRUCTION = """You are Sahayak AI (सहायक AI), an empathetic, knowledgeable, and helpful AI assistant for the Sahayak Worker Cooperative Platform (CodeCraft).
Sahayak is a democratic, cooperative-owned home services marketplace connecting households with verified tradespersons (electricians, plumbers, AC technicians, cleaners, pest control experts).

YOUR BEHAVIOR & GUIDELINES:
1. Converse naturally, politely, and warmly. You understand English, Hindi, Hinglish, and regional Indian contexts.
2. If the user greets you or asks general questions (e.g. "Who are you?", "How does Sahayak work?", "Why choose cooperatives over Urban Company?"):
   - Answer conversationally, explain how 95%+ earnings go to workers and collective welfare (e-Shram, insurance), and set "category": "none".
3. If the user describes ANY household problem (e.g. leaks, broken taps, low cooling, sparks, tripping MCB, cockroaches, termites, deep cleaning, moving into a new home):
   - Provide helpful, friendly diagnosis advice.
   - Categorize the issue into one of our exact service offerings:
     * "plumber": Pipe leaks, tap/faucet issues, drainage blocks, bathroom fittings, flush repairs.
     * "electrician": Short circuit, sparking switchboard, wiring, ceiling fan, MCB trip, appliance points.
     * "appliance": AC cooling, gas leak/refill, foam jet servicing, refrigerator/washing machine checks.
     * "cleaning": Deep home cleaning, kitchen degreasing, bathroom scrubbing, full sanitization.
     * "pest_control": Cockroaches, termites, bed bugs, ants, pest eradication.
4. If no service matches (e.g. cooking, carpentry, gardening, dog walking), explain politely what Sahayak currently offers.

OUTPUT FORMAT:
You MUST respond STRICTLY in valid JSON matching this schema:
{
  "reply": "Your conversational, helpful response to the user",
  "category": "plumber" | "electrician" | "appliance" | "cleaning" | "pest_control" | "none"
}
Do not wrap in backticks or markdown, output pure JSON only.
"""

@router.post("/ai/diagnose", response_model=DiagnoseResponse)
def diagnose_issue(payload: DiagnoseRequest):
    user_msg = payload.message.strip()
    api_key = os.getenv("GEMINI_API_KEY", "").strip()

    if not api_key:
        # Check alternative common env names
        api_key = os.getenv("GOOGLE_API_KEY", "").strip()

    if api_key:
        try:
            # Build conversation history for Gemini
            contents = []
            for turn in (payload.history or []):
                role = "user" if turn.role == "user" else "model"
                contents.append({
                    "role": role,
                    "parts": [{"text": turn.content}]
                })
            contents.append({
                "role": "user",
                "parts": [{"text": user_msg}]
            })

            # Use official stable model: gemini-1.5-flash (or gemini-2.0-flash)
            is_bearer = api_key.startswith("AQ.") or api_key.startswith("ya29.")
            if is_bearer:
                url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
                headers = {
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}"
                }
            else:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
                headers = {"Content-Type": "application/json"}

            body = {
                "system_instruction": {
                    "parts": [{"text": SYSTEM_INSTRUCTION}]
                },
                "contents": contents,
                "generationConfig": {
                    "response_mime_type": "application/json",
                    "temperature": 0.4
                }
            }

            req = urllib.request.Request(
                url,
                data=json.dumps(body).encode("utf-8"),
                headers=headers,
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=12) as resp:
                result_data = json.loads(resp.read().decode("utf-8"))
                text_out = result_data["candidates"][0]["content"]["parts"][0]["text"]
                parsed = json.loads(text_out)

                cat = parsed.get("category", "none").lower()
                reply = parsed.get("reply", "I am happy to assist you with Sahayak cooperative services.")

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
            print(f"[AI] Gemini call error: {e}")
            # Try backup model gemini-2.0-flash
            try:
                if is_bearer:
                    url_fallback = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
                else:
                    url_fallback = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
                req = urllib.request.Request(
                    url_fallback,
                    data=json.dumps(body).encode("utf-8"),
                    headers=headers,
                    method="POST"
                )
                with urllib.request.urlopen(req, timeout=12) as resp:
                    result_data = json.loads(resp.read().decode("utf-8"))
                    text_out = result_data["candidates"][0]["content"]["parts"][0]["text"]
                    parsed = json.loads(text_out)
                    cat = parsed.get("category", "none").lower()
                    reply = parsed.get("reply", "")
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
            except Exception as e2:
                print(f"[AI] Gemini backup model error: {e2}")


    # Dynamic intelligent fallback if no key is present or cloud is disconnected
    lower = user_msg.lower()
    if any(k in lower for k in ["hello", "hi", "hey", "who are you", "what is this", "namaste"]):
        return DiagnoseResponse(
            reply="Namaste! I am Sahayak AI. How can I assist you with your home services today? Feel free to describe any repairs or cleaning needed.",
            service_id=None
        )
    elif any(k in lower for k in ["cooperative", "urban company", "why sahayak", "commission"]):
        return DiagnoseResponse(
            reply="Unlike corporate aggregators that take 25%-30% cuts, Sahayak is owned by labour cooperatives! Workers keep 95%+ of their pay, receive e-Shram health benefits, and you get guaranteed, transparent pricing.",
            service_id=None
        )
    elif any(k in lower for k in ["pipe", "leak", "tap", "drain", "sink", "water", "plumb"]):
        srv = SERVICES_CATALOG["plumber"]
        return DiagnoseResponse(
            reply=f"A leaking or blocked pipe needs timely attention to avoid damage. Our cooperative plumbers can inspect and fix this right away.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower for k in ["spark", "switch", "electric", "wire", "mcb", "fan", "shock"]):
        srv = SERVICES_CATALOG["electrician"]
        return DiagnoseResponse(
            reply=f"Electrical sparking and short circuits require certified handling. Our licensed cooperative electrician is ready to help.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower for k in ["ac", "cool", "air condition", "gas", "filter"]):
        srv = SERVICES_CATALOG["appliance"]
        return DiagnoseResponse(
            reply=f"If your AC isn't cooling properly, it may need foam jet servicing or a gas pressure check. Here is our certified AC service.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower for k in ["clean", "dust", "deep clean", "scrub", "sanitize"]):
        srv = SERVICES_CATALOG["cleaning"]
        return DiagnoseResponse(
            reply=f"Our cooperative cleaning crew provides deep scrubbing of floors, kitchen degreasing, and complete home sanitization.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    elif any(k in lower for k in ["pest", "cockroach", "ant", "termite", "bed bug"]):
        srv = SERVICES_CATALOG["pest_control"]
        return DiagnoseResponse(
            reply=f"We offer safe, odorless, and government-approved pest control treatments for long-lasting protection.",
            service_id=srv["service_id"],
            service_name=srv["service_name"],
            category=srv["category"],
            price_formatted=srv["price_formatted"]
        )
    else:
        return DiagnoseResponse(
            reply=f"I understand! Could you share a bit more detail about the issue? I can assist you with Plumbing, Electrical, AC Repair, Cleaning, or Pest Control.",
            service_id=None
        )
