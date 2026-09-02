# 🏛️ Sahayak (CodeCraft) — Full System Architecture & Teammate Onboarding Guide
**Smart India Hackathon 2026** • Problem Statement: *Cooperative Gig Services Platform for Household & Community Services*

---

## 🎯 Executive Overview (The 30-Second Elevator Pitch)
> *"Sahayak is a **three-tier, cooperative-owned gig marketplace platform**. It connects household consumers directly with certified labour cooperative workers through unified, production-grade cloud APIs and dual-role cross-platform mobile apps, supervised by a real-time React federation admin dashboard."*

---

## 🏗️ 1. The Three-Tier Architecture

```
                              [ THE SAHAYAK ECOSYSTEM ]
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
[ LAYER 1: FRONTENDS ]         [ LAYER 2: BACKEND ]            [ LAYER 3: DATABASE ]
• Flutter Mobile Apps          • FastAPI (Python 3.11)         • Supabase (PostgreSQL 15)
  (Customer + Worker)          • Pydantic v2 + Uvicorn         • Supabase Auth (JWT Engine)
• React 18 Admin Web           • Hosted Live on Render         • Row Level Security (RLS)
  (Vite + Tailwind CSS)          (Webhooks & CI/CD)            • 10 Relational Tables
```

| Layer | Technology | Host / Deployment | Role in Sahayak |
| :--- | :--- | :--- | :--- |
| **1. Mobile Apps** | Flutter 3.x / Dart | Local Web (`0.0.0.0:8080`) / APK | Dual Customer & Worker Mobile Portals |
| **2. Admin Web** | React 18 + TS + Vite | Vercel Cloud | Cooperative Federation Dispatch Command |
| **3. Cloud Backend** | FastAPI (Python 3.11) | Render Cloud | High-Speed Asynchronous REST Engine |
| **4. Database** | PostgreSQL 15 | Supabase Cloud | 10 Tables, Auth Engine & Role Checking |

---

## 📱 2. Mobile Application Layer (Flutter / Dart)
* **Single Unified Codebase**: Both Customer and Worker interfaces live in `mobile/`.
* **Dynamic Role Routing (`AuthGate` & `AuthService`)**:
  1. On launch, `AuthGate` reads `auth_token` and `auth_role` from device storage (`SharedPreferences`).
  2. If `role == 'CUSTOMER'` $\rightarrow$ opens `CustomerHomeScreen` (services catalog, search bar, category chips, booking modal).
  3. If `role == 'WORKER'` $\rightarrow$ opens `WorkerHomeScreen` (on-duty toggle, dynamic name greeting, incoming requests feed, availability schedule).
  4. If unauthenticated $\rightarrow$ opens `AuthScreen` (Sign In / Sign Up with Customer/Worker toggle).

---

## ⚙️ 3. Cloud Backend Layer (FastAPI / Render)
* **Production URL**: `https://sahayak-t0pw.onrender.com/api/v1`
* **Key Endpoints**:
  - `POST /auth/register` & `POST /auth/login`: User creation & JWT generation.
  - `GET /services`: Live service catalog with category filtering.
  - `POST /bookings` & `GET /bookings`: Order creation & joined customer data.
  - `PATCH /bookings/{id}/status`: Live status transitions (`ACCEPTED`, `IN_PROGRESS`, `COMPLETED`).
  - `GET /workers` & `PATCH /admin/workers/{id}/verify`: Federation worker listing & verification.
* **Integer Paise Standard**: All currency values are stored as integers (e.g. `49900` = ₹499.00) to eliminate IEEE 754 floating-point rounding errors in financial and welfare dividend calculations.

---

## 🗄️ 4. Database Schema (Supabase / PostgreSQL 15)
Our database uses **10 specialized relational tables**:
1. `profiles`: Master identity and role registry (`user_id`, `full_name`, `phone`, `role`).
2. `worker_profiles`: Extended skills, rating averages, and verification badges (`PENDING`/`VERIFIED`).
3. `services`: Federation-approved rate card with prices in paise and Unsplash photos.
4. `bookings`: Real-time customer job orders and status tracking.
5. `worker_availability`: Monday–Sunday on-duty calendar.
6. `payments`: Digital invoices and settlement records.
7. `reviews`: 1–5 star customer ratings and comments.
8. `complaints`: Cooperative grievance and dispute resolution tickets.
9. `worker_welfare`: Social security, health insurance, and pension accruals.
10. `notifications`: Push and in-app event log.

---

## 💻 5. Cooperative Federation Admin Dashboard (React 18 / Vite / Vercel)
* **Live Command Center**: Real-time operational oversight for cooperative managers.
* **8-Second Background Polling**: Automatically synchronizes with mobile bookings without manual page reloads.
* **Interactive Modals**: Click any row in the dispatch table to view customer notes, contact info, and override job statuses.
* **Instant Optimistic Verification**: Federation officers can approve newly registered workers with one click.

---

## 🎬 6. The "Hero Demonstration Loop" (Live Presentation Steps)

| Step | Device | Action | Visible Result |
| :--- | :--- | :--- | :--- |
| **1** | Laptop (Admin) | Open Vercel Dashboard | Live KPI cards display active bookings & verified workers. |
| **2** | Phone 1 (Customer) | Book *"Home Deep Cleaning"* | Green toast appears; order is saved as `PENDING` in database. |
| **3** | Laptop (Admin) | Watch Dispatch Table | New booking row appears with Orange `[ Pending Dispatch ]` badge. |
| **4** | Phone 2 (Worker) | Tap **"Accept"** in Incoming Jobs | Job turns `ACCEPTED`; worker is assigned in cloud DB. |
| **5** | Laptop (Admin) | Watch Status Badge | Row updates to Blue `[ Worker Accepted ]` with technician assigned. |
| **6** | Phone 2 (Worker) | Tap **"Start"** $\rightarrow$ **"Complete Job"** | Worker earnings increment; status updates to `COMPLETED`. |
| **7** | Laptop (Admin) | Observe Final Settlement | Row turns Green `[ Completed ]`; Platform Revenue increases live! |

---

## 🎯 7. Judge Viva Cheat-Sheet (Top 4 Questions)

**Q1: How does the mobile app know whether to open the Customer or Worker screen?**
> *"During registration/login, our FastAPI backend checks `public.profiles` and returns the user's role. Flutter stores this in `SharedPreferences`. On app launch, `AuthGate` reads the role and instantly opens either `CustomerHomeScreen` or `WorkerHomeScreen`."*

**Q2: What is the core market advantage over Urban Company?**
> *"Urban Company takes 25%–30% commissions and treats workers as disposable freelance supply. Sahayak is owned by the Labour Cooperative Federation: platform overhead is only 3%–5%, workers keep 95%+ of their payout, every technician is vetted by state societies, and completed jobs contribute to e-Shram health and pension funds."*

**Q3: Why store prices in paise instead of rupees?**
> *"Financial precision standard: Storing currency as integers (paise) prevents IEEE 754 floating-point rounding errors during GST deductions and worker dividend splits."*

**Q4: What makes this architecture scalable?**
> *"FastAPI uses asynchronous endpoints running on Uvicorn ASGI on Render, and our database is PostgreSQL 15 on Supabase with connection pooling and indexed foreign keys."*
