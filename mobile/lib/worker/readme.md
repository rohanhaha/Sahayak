# Worker Dashboard & Operations UI Module

Owner: Vaishnavi  
Scope: Worker Dashboard & Job Management UI

## Directory Structure

```
mobile/lib/worker/
├── models/
│   └── worker_job.dart          # WorkerJob & WorkerAvailabilitySlot models with mock data
├── widgets/
│   ├── worker_header.dart       # Duty switch header, rating, and 3 quick stat cards
│   └── job_request_card.dart    # Request card with Accept/Decline action buttons
├── screens/
│   └── worker_home_screen.dart  # Main Worker Dashboard & Operations interface
├── worker.dart                  # Module barrel export
└── readme.md
```

## Features Implemented

1. **WorkerJob & Availability Models (`models/worker_job.dart`)**:
   - Matches API Contract: `booking_id`, `status` (`PENDING`, `ACCEPTED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`), `day_of_week`, and money in paise.
   - Includes 3 realistic mock jobs (Electrician services) and 7 mock weekly availability slots (MON-SUN).

2. **Worker Header & Duty Toggle (`widgets/worker_header.dart`)**:
   - Worker profile: Rajesh Kumar - Electrician (★ 4.8 / 5.0).
   - Dynamic Duty toggle (Green for Online / Slate Gray for Offline).
   - 3 Quick summary cards: Today's Earnings (₹1,200), Completed Jobs (4), Pending Requests (2 / dynamic).

3. **Job Request Card (`widgets/job_request_card.dart`)**:
   - Address with pin indicator, service requested, scheduled slot, and payout in ₹.
   - **Accept** (Green button) and **Decline** (Outlined Gray button).
   - Interactive status transitions with success notifications.

4. **Worker Home Screen (`screens/worker_home_screen.dart`)**:
   - Full operations dashboard with Duty toggle, live metrics, filterable jobs feed, and weekly working schedule configuration tab.

