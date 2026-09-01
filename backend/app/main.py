from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import (
    auth,
    services,
    workers,
    bookings,
    payments,
    reviews,
    notifications,
    welfare,
    admin,
)

app = FastAPI(title="CodeCraft API", version="0.1.0")

# CORS: allows the Flutter app and React admin site (different origins) to call
# this server from a browser/emulator without being blocked. Wide open for the
# hackathon — tighten this to specific domains later if needed.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Every router gets mounted under /api/v1, matching docs/api-contract.md
app.include_router(auth.router, prefix="/api/v1", tags=["auth"])
app.include_router(services.router, prefix="/api/v1", tags=["services"])
app.include_router(workers.router, prefix="/api/v1", tags=["workers"])
app.include_router(bookings.router, prefix="/api/v1", tags=["bookings"])
app.include_router(payments.router, prefix="/api/v1", tags=["payments"])
app.include_router(reviews.router, prefix="/api/v1", tags=["reviews"])
app.include_router(notifications.router, prefix="/api/v1", tags=["notifications"])
app.include_router(welfare.router, prefix="/api/v1", tags=["welfare"])
app.include_router(admin.router, prefix="/api/v1", tags=["admin"])


@app.get("/")
def health_check():
    # Quick way to confirm the server is alive — visit this URL in a browser.
    return {"status": "ok", "message": "CodeCraft API is running"}
