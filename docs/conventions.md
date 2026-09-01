# CodeCraft — Project Conventions

You are helping build one feature of a larger team project. Other team members are
building other parts in parallel, in separate branches, and will only ever integrate
with your code through the rules below. Follow them exactly, even if you'd normally
choose differently — consistency across the team matters more than personal style
here.

## Project shape

- One Flutter mobile app serves both customers and workers (separate role-based
  sections in the same app).
- One React web app serves cooperative/federation administrators.
- One FastAPI backend serves both frontends over REST.
- Supabase (PostgreSQL) is the data layer, plus Supabase Auth and Supabase Storage.
- Razorpay for payments, Firebase FCM for push notifications, OpenStreetMap /
  flutter_map + geolocator for maps and location.

## Repo structure

```
codecraft/
├── mobile/                 # Flutter — shared app, role-based UI
│   └── lib/
│       ├── customer/       # customer-facing screens
│       ├── worker/         # worker-facing screens
│       ├── shared/         # api client, models, auth — shared, coordinate before editing
│       └── main.dart
├── admin-web/               # React admin dashboard
│   └── src/
├── backend/                  # FastAPI
│   └── app/
│       ├── routers/          # one file per resource, matches api-contract.md
│       ├── models/
│       ├── services/
│       └── ai/               # matching/forecasting — plain importable functions, no HTTP
├── docs/
│   ├── api-contract.md        # every endpoint's request/response shape — source of truth
│   ├── conventions.md          # this file
│   └── test-cases.md
└── .github/
```

## The only rule that matters: scope stops at the communication channel

Your code's job ends the moment it correctly sends or receives data across one of
these boundaries. You never need to know how the other side is implemented.

- **Frontend (Flutter/React) ↔ Backend**: a REST endpoint, defined in
  `docs/api-contract.md`. Build against that contract even if the real endpoint
  isn't finished yet — it will be live as a stub returning example data from very
  early on.
- **AI/algorithm code ↔ Backend**: a plain Python function call (e.g.
  `match_workers(booking: dict) -> list[dict]`), not HTTP. It lives in
  `backend/app/ai/` and gets imported directly.
- Nothing else crosses between people's work. If you think you need to know
  another feature's internals to finish yours, stop and flag it — that usually
  means the contract is missing something, not that you should go read their code.

## Naming and data conventions (applies to anything in `api-contract.md` or the DB schema)

- Field names: `snake_case` everywhere — in the database, and in every JSON
  request/response.
- IDs: UUID v4, represented as strings.
- Timestamps: ISO 8601, UTC, field name ends in `_at` (e.g. `created_at`,
  `updated_at`).
- Money: stored and transmitted as an integer in the smallest currency unit
  (paise, not rupees), field name ends in `_amount`.
- Status/enum fields: fixed uppercase strings, defined once per resource in
  `api-contract.md`. Don't invent new status values inline in your code — add
  them to the contract first.
  Example: `booking.status ∈ {PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED}`
- Auth: Supabase JWT, sent as `Authorization: Bearer <token>` on every
  authenticated request.
- Error responses: always shaped as
  `{ "error": { "code": "STRING", "message": "STRING" } }`
- Pagination: query params `?page=` and `?limit=`; response includes `total`,
  `page`, and `limit` alongside the results.
- API route prefix: `/api/v1/`

## Git workflow

- `main` is the integration branch — never commit features directly to it.
- One branch per person per feature: `firstname/feature-name` (e.g.
  `rishav/booking-flow`, `omkar/matching-algo`).
- Merge in small, frequent PRs (every 2–3 hours of work), not one giant PR at
  the end.
- If a change touches `api-contract.md` or `conventions.md`, that PR needs a
  quick heads-up to the team before merging — everything else needs no
  coordination at all.

## What "done" means for a ticket

Your ticket is done when your side of its communication channel is satisfied —
nothing more, nothing less.
- A frontend screen is done when it correctly calls the documented endpoint and
  correctly renders the documented response shape, even if the backend behind
  it is still returning stubbed/fake data.
- A backend endpoint is done when it accepts the documented request shape and
  returns the documented response shape, regardless of which screen is calling
  it or whether that screen exists yet.
