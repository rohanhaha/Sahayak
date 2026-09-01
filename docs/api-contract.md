# CodeCraft — API Contract (v1)

This is the source of truth for every endpoint the backend exposes. Nothing here
is implemented yet — Manish builds stub routes matching this exactly (returning
hardcoded example data), and everyone else builds against these shapes from day one.

Applies alongside `docs/conventions.md` — read that first for naming/format rules
(snake_case, UUIDs, ISO 8601 timestamps, money in paise, enum conventions, auth
header format, error shape, pagination).

Base URL: `/api/v1`

All endpoints except `POST /auth/register` and `POST /auth/login` require:
`Authorization: Bearer <supabase_jwt>`

---

## 1. Auth

### `POST /auth/register`
Request:
```json
{
  "email": "string",
  "password": "string",
  "full_name": "string",
  "phone": "string",
  "role": "CUSTOMER | WORKER"
}
```
Response `201`:
```json
{
  "user_id": "uuid",
  "email": "string",
  "role": "CUSTOMER | WORKER",
  "access_token": "string"
}
```

### `POST /auth/login`
Request:
```json
{ "email": "string", "password": "string" }
```
Response `200`:
```json
{
  "user_id": "uuid",
  "role": "CUSTOMER | WORKER | ADMIN",
  "access_token": "string"
}
```

### `GET /auth/me`
Response `200`:
```json
{
  "user_id": "uuid",
  "email": "string",
  "full_name": "string",
  "phone": "string",
  "role": "CUSTOMER | WORKER | ADMIN",
  "created_at": "iso8601"
}
```

---

## 2. Services (what customers browse/book)

### `GET /services`
Query params: `?category=&page=&limit=`
Response `200`:
```json
{
  "results": [
    {
      "service_id": "uuid",
      "name": "string",
      "category": "string",
      "description": "string",
      "base_price_amount": 0,
      "image_url": "string"
    }
  ],
  "total": 0, "page": 1, "limit": 20
}
```

### `GET /services/{service_id}`
Response `200`: same shape as one item above, plus `available_workers_count`.

---

## 3. Worker discovery & profile

### `GET /workers`
Query params: `?service_id=&lat=&lng=&radius_km=&page=&limit=`
Response `200`:
```json
{
  "results": [
    {
      "worker_id": "uuid",
      "full_name": "string",
      "skills": ["string"],
      "rating_avg": 0.0,
      "rating_count": 0,
      "distance_km": 0.0,
      "available": true
    }
  ],
  "total": 0, "page": 1, "limit": 20
}
```

### `GET /workers/{worker_id}`
Response `200`: full profile — skills, certificates (URLs), rating history summary,
`availability` (see below).

### `PUT /workers/{worker_id}/skills` (worker only, self)
Request:
```json
{ "skills": ["string"], "certificates": [{ "name": "string", "file_url": "string" }] }
```
Response `200`: updated profile object.

### `GET /workers/{worker_id}/availability`
Response `200`:
```json
{
  "slots": [
    { "day_of_week": "MON", "start_time": "09:00", "end_time": "17:00" }
  ]
}
```

### `PUT /workers/{worker_id}/availability` (worker only, self)
Request: same shape as `slots` above.
Response `200`: updated slots.

---

## 4. Bookings

### `POST /bookings` (customer)
Request:
```json
{
  "service_id": "uuid",
  "worker_id": "uuid",
  "scheduled_at": "iso8601",
  "address": "string",
  "lat": 0.0,
  "lng": 0.0,
  "notes": "string"
}
```
Response `201`:
```json
{
  "booking_id": "uuid",
  "status": "PENDING",
  "service_id": "uuid",
  "worker_id": "uuid",
  "customer_id": "uuid",
  "scheduled_at": "iso8601",
  "created_at": "iso8601"
}
```

### `GET /bookings/{booking_id}`
Response `200`: full booking object including current `status` and `payment_status`.

`status` enum: `PENDING | ACCEPTED | IN_PROGRESS | COMPLETED | CANCELLED`

### `GET /bookings` (customer sees their own, worker sees assigned, admin sees all)
Query: `?status=&page=&limit=`
Response `200`: paginated list, same item shape as above.

### `PATCH /bookings/{booking_id}/status` (worker or admin)
Request:
```json
{ "status": "ACCEPTED | IN_PROGRESS | COMPLETED | CANCELLED" }
```
Response `200`: updated booking object.

---

## 5. Payments

### `POST /payments/create-order` (customer)
Request:
```json
{ "booking_id": "uuid" }
```
Response `200`:
```json
{
  "razorpay_order_id": "string",
  "amount": 0,
  "currency": "INR"
}
```

### `POST /payments/verify`
Request:
```json
{
  "booking_id": "uuid",
  "razorpay_payment_id": "string",
  "razorpay_order_id": "string",
  "razorpay_signature": "string"
}
```
Response `200`:
```json
{ "payment_status": "PAID | FAILED", "booking_id": "uuid" }
```

---

## 6. Reviews

### `POST /reviews` (customer, after COMPLETED booking)
Request:
```json
{ "booking_id": "uuid", "rating": 5, "comment": "string" }
```
Response `201`: created review object.

### `GET /workers/{worker_id}/reviews`
Response `200`: paginated list of `{ rating, comment, customer_name, created_at }`.

---

## 7. Notifications

### `GET /notifications`
Response `200`: paginated list of `{ notification_id, title, body, read, created_at }`.

### `PATCH /notifications/{notification_id}/read`
Response `200`: `{ "notification_id": "uuid", "read": true }`.

*(Push delivery itself goes through Firebase FCM — this endpoint is just for the
in-app notification list/read-state, not for sending the push.)*

---

## 8. Welfare / Insurance (worker-facing)

### `GET /workers/{worker_id}/welfare-schemes`
Response `200`: list of `{ scheme_id, name, description, enrollment_status }`.

### `POST /workers/{worker_id}/welfare-schemes/{scheme_id}/enroll`
Response `200`: `{ "scheme_id": "uuid", "enrollment_status": "ENROLLED" }`.

---

## 9. Admin — cooperative/federation management

### `GET /admin/workers?verification_status=`
Response `200`: paginated worker list including `verification_status` (`PENDING | VERIFIED | REJECTED`).

### `PATCH /admin/workers/{worker_id}/verify`
Request: `{ "verification_status": "VERIFIED | REJECTED", "notes": "string" }`
Response `200`: updated worker object.

### `GET /admin/customers`
Response `200`: paginated customer list.

### `GET /admin/bookings`
Same shape as `GET /bookings`, unfiltered by user — admin sees all.

### `GET /admin/complaints`
Response `200`: paginated list of `{ complaint_id, booking_id, raised_by, description, status, created_at }`.

### `PATCH /admin/complaints/{complaint_id}`
Request: `{ "status": "OPEN | IN_REVIEW | RESOLVED", "resolution_notes": "string" }`
Response `200`: updated complaint object.

### `GET /admin/analytics/summary`
Response `200`:
```json
{
  "total_bookings": 0,
  "total_revenue_amount": 0,
  "active_workers": 0,
  "active_customers": 0,
  "bookings_by_status": { "PENDING": 0, "COMPLETED": 0 }
}
```

---

## 10. AI / Matching (internal — backend calls this directly, not over HTTP)

This is a Python function boundary inside `backend/app/ai/`, owned by Omkar,
called directly by Manish's route handlers. No JSON-over-HTTP needed since it's
in-process.

```python
def match_workers(booking: dict, candidates: list[dict]) -> list[dict]:
    """
    Input: the booking request + list of available worker profiles
    Output: same worker profiles, re-ordered/scored by match quality
    Each returned dict adds a `match_score: float` field.
    """
```

```python
def forecast_demand(service_id: str, days_ahead: int) -> dict:
    """
    Returns: { "service_id": str, "forecast": [{ "date": "iso8601", "predicted_bookings": int }] }
    """
```

---

## Status: DRAFT

This covers the core flows from the architecture diagram and role deliverables.
If a screen needs data this doc doesn't cover, **add the endpoint here first**,
flag it to the team, then build against it — don't invent an undocumented shape
in your own code.
