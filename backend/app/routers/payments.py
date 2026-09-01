from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class CreateOrderRequest(BaseModel):
    booking_id: str


class VerifyPaymentRequest(BaseModel):
    booking_id: str
    razorpay_payment_id: str
    razorpay_order_id: str
    razorpay_signature: str


@router.post("/payments/create-order")
def create_order(payload: CreateOrderRequest):
    # STUB — real version calls the Razorpay SDK to create an actual order.
    return {
        "razorpay_order_id": "order_fake123",
        "amount": 50000,
        "currency": "INR",
    }


@router.post("/payments/verify")
def verify_payment(payload: VerifyPaymentRequest):
    return {"payment_status": "PAID", "booking_id": payload.booking_id}
