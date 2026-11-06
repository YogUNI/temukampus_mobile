# AGENTS.md — TemuKampus Mobile (Flutter)

You are an expert Flutter & Dart mobile application engineer working on **TemuKampus Mobile**: the official mobile companion for Universitas Mercu Buana (UMB) students and campus organizations.

TemuKampus allows students to discover campus events, verify eligibility, register, upload payment proofs, store digital tickets with QR codes, and enables event organizers (panitia) to scan participant tickets on event day.

The mobile app connects to the **TemuKampus Laravel 13 REST API backend** (`http://temukampus.test/api/v1` in local development). It shares 100% feature parity, domain rules, validation logic, and design branding with the web version.

---

## Source of Truth (Must Read Before Coding)
1. `docs/01-MOBILE-PRD.md` — Product requirements, student & panitia mobile journeys, business rules (BR-01..BR-25).
2. `docs/02-MOBILE-ARCHITECTURE.md` — Flutter Clean Architecture, project folder layout, state management, Dio networking, local secure storage.
3. `docs/03-API-CONTRACT.md` — Exact REST API endpoints, request/response JSON schemas, authentication bearer token lifecycle, error codes.
4. `docs/04-MOBILE-DESIGN-SYSTEM.md` — Design tokens (Cobalt `#2447F5`, Signal `#FF7A2F`, Ink `#12162B`), Ticket Notch motif, Typography, UI components.

> **Rule on Discrepancies:** If Flutter code and the docs disagree, pause and ask. Never invent API endpoints, alter business rules, or change design tokens without approval.

---

## Tech Stack & Standards
- **Framework:** Flutter 3.24+ (Dart 3.5+)
- **Architecture:** Feature-first Clean Architecture (`core/`, `features/`, `shared/`)
- **State Management:** Riverpod (or BLoC/Cubit / Provider as configured in `pubspec.yaml`)
- **Networking:** `dio` with custom interceptors for Auth Token injection, logging, and 401 handling
- **Local Storage:** `flutter_secure_storage` for sensitive auth tokens; `shared_preferences` or `hive` for cached preferences & offline catalog
- **Image Picker & Compression:** `image_picker` + `flutter_image_compress` (proof must be <= 4 MB before upload)
- **QR Code Engine:** `qr_flutter` (generate ticket QR) + `mobile_scanner` (camera check-in scanner for organizers)
- **Typography:** `google_fonts` (Plus Jakarta Sans for Body/UI, Bricolage Grotesque for Headings/Badges)
- **Routing:** `go_router` with auth state redirection guards
- **Code Hygiene:** `flutter_lints`, strict typing, immutable models (`freezed` + `json_serializable`)

---

## Domain Essentials & Invariants (Shared with Web)
- **Roles:** `user` (student/external), `admin` (panitia), `superadmin`. Account types: `umb` (student with NIM), `external` (public/other universities).
- **NIM Parsing:** 11-digit string. Digits 1–3 = Study Program Code (e.g. `415` for Teknik Informatika, `418` for Sistem Informasi). Digits 4–5 = Cohort Year (`20` + YY, e.g. `24` = 2024). This logic is handled via client-side preview in `NimParser` and strictly enforced by the backend.
- **Registration Statuses:**
  - `pending_verification` (Amber) — Waiting for committee manual transfer check.
  - `needs_revision` (Signal Orange) — Transfer proof rejected/unreadable; user must re-upload.
  - `confirmed` (Mint Green) — Approved; ticket QR active, WhatsApp group & meeting link unlocked.
  - `rejected` (Danger Red) — Final rejection for that event.
  - `cancelled` (Ink Gray) — Cancelled by user before event start.
- **Payment is MANUAL:** No automated payment gateway. User copies committee bank/QRIS details, transfers money with a 3-digit unique code (e.g. Rp 25.137), uploads screenshot, and committee verifies it.
- **Audience & Eligibility:**
  - `public`: Everyone can register.
  - `umb_only`: Must have an active `umb` account with validated NIM.
  - `restricted`: Allowed faculties/prodi with OR logic, then cohort year range with AND logic.

---

## Development Environment & Network URLs
- **Local Laravel Backend:**
  - Android Emulator: `http://10.0.2.2:8000/api/v1` (or Laragon virtual host via host reverse proxy)
  - iOS Simulator: `http://localhost:8000/api/v1`
  - Physical Device (Wi-Fi LAN): `http://<LAPTOP_LOCAL_IP>:8000/api/v1` (ensure phone and PC share the same Wi-Fi)
- Base configuration lives in `lib/core/constants/app_env.dart` or `.env` via `flutter_dotenv`. Never hardcode raw IP strings across the codebase.

---

## Code Quality Rules
1. **No UI Hardcoding:** Always use `AppColors`, `AppTypography`, and `AppSpacing` design tokens.
2. **Handle All 4 UI States:** Every data-fetching screen MUST handle:
   - `Loading` (shimmer atau custom ticket loading indicator)
   - `Empty` (friendly empty state dengan ikon dan call-to-action)
   - `Error` (human-readable pesan error bahasa Indonesia + tombol "Coba Lagi")
   - `Success` (data display)
3. **Form Validation:** All validation errors returned from Laravel (HTTP 422 `{ "errors": { "field": [...] } }`) must be cleanly attached to the respective form input fields.
4. **Token Expiry (HTTP 401):** Intercept 401 Unauthenticated globally, clear secure storage, and route smoothly to `/login` with a clear message: *"Sesi Anda telah berakhir, silakan masuk kembali."*
5. **Indonesian Language:** All user-facing strings (labels, alerts, toasts, error messages) MUST be in Indonesian (casual yet polite, consistent with web `lang/id`). Code and comments must be in English.

---

## Git Workflow & Repository Rules
- **Branch:** Branch lokal dan remote utama adalah `main`. Yoga bekerja langsung di branch `main`.
- **Remote Origin:** `https://github.com/YogUNI/temukampus_mobile.git`
- **Aturan Wajib Git:** Setiap kali menyelesaikan sebuah tahap, fitur, atau perbaikan bug (setelah lolos `dart analyze` dan `flutter test`), kamu WAJIB melakukan `git commit` dengan pesan conventional (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`) dan langsung menjalankan `git push origin main`.
