# IbuDaya Flutter Project

## Product

IbuDaya is an Android app used by a **cooperative (koperasi)** and its
members — women-led micro-businesses in Indonesia — around a **Communal Solar
Hub**: one hub (battery + inverter) feeds 10–15 members' business appliances
directly through cabling and a per-member energy limiter, standing in for
their individual PLN connection for those registered appliances. The app:

1. **Connects members to the hub via QR.** The hub has one fixed QR code
   (`kSolarHubQr` in `lib/core/hub_qr.dart`); the admin never scans or edits
   it. A member scanning it (while logged in, so the app knows who) sends
   the admin a **usage verification request**, then may use the rest of the app
   while waiting. **She must have booked a slot for today first** — the scan is
   her arrival at that booking (`kQrRequiresBooking`); without one the scan is
   refused with "Booking slot dulu sebelum scan QR"; the request shows up on the admin's dashboard and in
   "Verifikasi Penggunaan Hub". Only after the admin approves does the session
   count. The request covers all of the member's registered appliances (no
   picker); its kWh is their total watts × the current slot's hours, within her
   own allocation. Approving starts the supply and the usage is **recorded
   automatically at that moment** — no photographing a bill. (Demo
   simplification: recorded at approval as an estimate, not at session end.)
2. **Books the hub within capacity and quota**: a shared daily production
   capacity split across time slots, plus a **per-member monthly allocation**
   (set by the admin from that member's limiter rating, falling back to a
   cooperative-wide default) that a member can also **share with other
   members** (**Tukar Kuota**, i.e. virtual quota trading; the money-dues group is **Arisan Digital**).
3. **Estimates a roof's solar potential** (Radar Atap) from the member's own
   measurements.
4. Runs **Arisan Digital** (dues submitted by members, confirmed by an admin).
5. Gives a transparent **Skor Kredit Energi** and lets a member **apply for a
   loan** that a **cooperative admin reviews, approves/rejects, disburses and
   tracks**.
   Once disbursed, the **installment schedule** (Jadwal Cicilan, member and
   admin) works like arisan dues: the borrower taps "Saya sudah bayar", an admin
   confirms or rejects it with a reason, and only a confirmation records it as
   paid (`submitInstallmentPayment` / `markInstallmentPaid` /
   `rejectInstallmentPayment`). Installments are sent in order; on-time is
   judged on the day she sent it, not the day the admin confirmed. The payment
   instructions reuse the cooperative's `arisanBankAccount`.
   The **business-activity** part of the score is productivity-based: registered
   appliances, completed hub sessions, kWh used and weekly regularity over the
   last 8 weeks (see `_business` in `credit_signals.dart`).
6. Lets members **message** the admin, the arisan group, or other members,
   and get notifications.

Two roles: `member` and `admin`. An admin registers and creates the
cooperative, which gets a 6-character invite code; members register with that
code. Login is phone number + 6-digit PIN.

**Members never enter electricity data.** Catatan Listrik, Analisis Energi and
the credit score all read what the Solar Hub recorded (completed hub sessions
and the records they create). There is no manual-entry form, and members cannot
delete records: Analisis Energi's per-appliance breakdown comes from completed
hub sessions, not declared hours.

The backend is **local-first today** (one JSON database file on the phone) and
moves to **Supabase** later — see `docs/SUPABASE.md` and
`supabase/migrations/`. Laravel is not part of the plan.

## Honesty rules (non-negotiable)

The users are financially vulnerable. Breaking one of these causes real harm.

- **No AI claims.** There is no trained model. The credit score and the
  production-window score are fixed rule sets with their inputs shown on
  screen. Never write "AI", "kecerdasan buatan", or an accuracy % about them.
- **People decide loans.** The app never approves anything. Copy says "Skor
  Anda mendukung pengajuan ini" / "Menunggu review admin", and
  `LoanDecisionNotice` appears wherever a loan is discussed.
- **People decide hub connections too.** Scanning the QR code only creates a
  `pendingVerification` request — the app never claims the connection is live
  until an admin approves it (`respondToConnectionRequest`). Copy follows the
  same "menunggu verifikasi admin" pattern as loans.
- **Server-style rules in repositories.** Authorization, eligibility, hub
  capacity, per-member allocation, quota and loan/booking status transitions
  are enforced in the repository layer (and in SQL functions for Supabase),
  never only in the UI.
- **Score needs history.** Withheld until `kMinMonthsForScore` months recorded.
- **Label assumptions.** CO₂ factor (0.87 kg/kWh), roof assumptions,
  and appliance estimates are stated where they appear.
- **Members cannot record their own usage.** Only an admin can set a booking to
  completed (`LocalSolarRepository.setBookingStatus`): approving a scan does it
  automatically, or an admin confirms a session. A member can only book, scan
  and cancel; otherwise she could write her own energy history and credit
  score. The bookings screen has a scan button for today's booking, not a
  "done" button.
- **Automatic readings stay correctable.** A hub session's `estKwh` is a
  software estimate (appliance watts × slot hours), not a physical sensor
  reading yet (see Known limits). The admin confirms each session before it is
  recorded, and the records screen tells members to contact the admin if
  something looks wrong. There is no in-app way yet for an admin to correct or
  void a completed session — add one before real use.
- **Hub limits are physical, so they are enforced in the repository.** Three
  limits plus the member's own quota: **seats** (`SolarHub.maxMembersPerSlot`,
  default 5, every slot alike, 0 = no limit — a slot is full when its seats are
  taken, never because one booking uses a lot of energy), the hub's **energy for
  the whole day** (`dailyCapacityKwh`, shared by every slot because the hub has
  a battery; there is no per-slot kWh and no sun-curve split any more) and
  **simultaneous load** (`SolarHub.maxLoadKw`, the inverter — set by the admin;
  0 = not set, not checked). A member holds one seat per slot and day: she adds
  appliances to that booking (the booking screen takes several; its energy is
  their watts added up × the slot's hours). A booking or QR request carries
  `loadKw` (appliance watts / 1000) and is refused when the slot's booked load
  plus it exceeds the limit, with the numbers in the message. **Exhibition demo exception:** `kQrIgnoresHubLimits`
  in `lib/core/hub_qr.dart` is `true`, so a QR scan is never refused for slot
  energy, the member's quota, inverter load or a closed slot (the admin still
  approves it; booking-screen bookings keep the limits). **Working hours:** the
  hub works 07.00–17.00 (`kHubOpensHour`/`kHubClosesHour`;
  `kQrIgnoresOperatingHours` is `false`). Outside them, scan and booking say so
  and say nothing about booking: from 17.00 "sudah lewat jam kerja" (scan and
  booking for today, in `requestConnection` and `book`), before 07.00 the scan
  says the hub is not open yet; the Solar Hub and booking screens show the same
  notice, and the booking screen then defaults to tomorrow. The hours check
  comes first, so within hours a scan without a booking gets the separate
  `kQrRequiresBooking` (true) message "Booking slot dulu sebelum scan QR". The
  sample seeder's demo scan (Dewi) is therefore only created within hours.
  **Set `kQrIgnoresHubLimits` to `false` before a real pilot.** An admin can close a slot (`HubSlot.isOpen`); closing
  stops new bookings and QR requests but never cancels existing ones. A QR scan
  for a slot the member already booked attaches to that booking rather than
  reserving capacity twice (`HubBooking.requestedAt` marks scans). The weather
  card's "kapasitas ±N%" is an estimate from the BMKG rule and does NOT change
  booking rules (they must not depend on a network call).
- **The monthly quota is shown as it is spent.** `quotaBalance` splits what a
  member has booked into **used** (sessions the hub recorded after the admin
  approved the scan) and **reserved** (booked, not used yet); both come off
  what is left the moment they exist, a rejected scan or cancelled booking
  gives it back, and a session never counts twice. The member dashboard
  (Beranda) shows what is left of the 35 kWh, used, booked, today's use, quota
  shared/received, **days left in the month** (today included, `quotaPace`) and
  the per-day pace that makes the rest last. The approval notification says
  how much quota is left. The month-on-month comparison on the dashboard
  compares a month still in progress with the same share of last month and
  says nothing before day 10, so day 1 never reads as "86% lower".
- **Sizing: 35 kWh per member per month** (`kMemberMonthlyKwh`, which is
  `kDefaultMemberMonthlyQuotaKwh`). Quota is counted per calendar month; the
  admin can change the cooperative default or one member's allocation. The
  hub is planned as members × quota ÷ 30 days (`dailyCapacityForQuota`; Hub
  Settings shows it as a hint and never enforces it): the sample hub is built for a full
  cooperative of 15 (15 × 35 ÷ 30 = 17.5 kWh/day) (≈ 5.5 kWp at 4 sun hours × 80%) with
  a 5 kW inverter. At this size one 1.5 kW oven for 3 hours (4.5 kWh) is a
  quarter of the hub's day, so the day's energy runs out before the seats do
  — that is the real constraint, not a bug. The sample seeder creates five members and one admin,
  each a different thing to explore: Clara (clean account, free to apply for a
  loan), Siti (application waiting for review, arisan payment waiting for the
  admin), Lina (no arisan payment, overdue installment), Putri (near her
  35 kWh, repaying a loan with one installment waiting for the admin) and Dewi
  (joined last month: no score yet, not in the arisan, scans the hub QR). It
  places each session
  (appliance watts × slot hours) only where the slot's energy, the inverter and
  the member's own month have room; `workflow_test.dart` checks that no month
  exceeds 35 kWh and no slot its capacity. Quota trades are a few kWh (the
  1/2/3/5 kWh choices).
- **Quota sharing moves no electricity.** It records an agreement (Tukar
  Kuota). Two ways to share: to anyone (a market post — the first member who
  takes it completes the trade at once, the post being the owner's consent) or
  to one chosen member (a directed share that waits in her "Kuota untuk Anda"
  inbox until she accepts or declines). The giver's balance is re-checked when
  the trade completes. Never say quota "lapses" or is "lost": the app counts
  quota per calendar month but carry-over is an unresolved policy, so screens
  only trade quota, they do not claim expiry. Suggested matches use a rule
  shown on screen (best-fitting amount, then longest wait) —
  `quota_insights.dart`.
- **Sample data is opt-in and labelled.** A fresh install is empty; "Coba
  dengan data contoh" creates a clearly marked sample cooperative.

## Tech Stack

- Flutter · Dart · Material 3
- Riverpod (state) · GoRouter (navigation, `StatefulShellRoute` per role)
- `path_provider`, `camera`, `image_picker`, `mobile_scanner`, `crypto` — each
  justified in `pubspec.yaml`

Do not introduce another state management or routing framework. Do not add a
dependency without explaining why.

## Architecture

```
UI (lib/features/**)
  → appStateProvider (AppState: me + CoopSnapshot)   lib/core/state/app_state.dart
  → selectors (pure extension on CoopSnapshot)        lib/core/state/selectors.dart
  → AppActions (every mutation, then refresh)         lib/core/state/actions.dart
  → Repository interfaces                             lib/core/repositories/repositories.dart
  → Local*Repository → LocalDatabase (JSON file)      lib/core/repositories/local/, lib/core/db/
```

- `lib/core/models/` — immutable rows with `fromRow`/`toRow` (snake_case,
  identical to the Supabase columns).
- `lib/core/logic/` — pure arithmetic: loan math & status machine, roof
  estimator, hub capacity, quota ledger, energy insights, credit signals.
- `LocalSnapshotRepository.load` mirrors RLS: a member sees her own rows; an
  admin sees her whole cooperative.
- Side effects that will be DB triggers in Supabase (notifications, system
  messages in the support thread, auto-creating an `EnergyRecord` when a hub
  booking completes) live in the local repositories / `AppActions`.
- `lib/app/router.dart` — `guard()` is the role gate; keep it pure and tested.
- `BookingStatus` is `pendingVerification → booked → completed` (or
  `cancelled` from either of the first two) — see `HubBooking` in
  `lib/core/models/solar.dart`. A `pendingVerification` booking already
  reserves hub capacity, so two members can't both be approved past it.

**Riverpod pause gotcha:** routes that are off-screen have paused
subscriptions; a *derived provider chain* that changed meanwhile is flushed
during the resuming build and throws. Screens therefore watch only
`appStateProvider` and derive with selectors. Do not add derived `Provider`s
that screens watch. `test/widget/app_flow_test.dart` guards push → save → pop.

Widgets must not touch repositories or the database directly — go through
`actionsProvider`.

## UI Rules

- Two user-facing languages, **Indonesian (default) and English**, switched in
  Profil → Bahasa and applied at once. Short, concrete sentences in both. Every
  string a person can read must exist in both:
  - Screen text: a getter on `AppLocalizations` (`lib/core/l10n/`), implemented
    in `_IdStrings` and `_EnStrings`. `AppLocalizations.current` is the language
    in use for code with no `BuildContext` (date/rupiah/kWh formatters).
  - Errors: `AppException('Indonesia', en: 'English')`. `test/unit/i18n_guard_test.dart`
    fails on an `AppException` without `en:`; the UI shows `e.localized(english: …)`.
  - Texts stored at write time (notifications, system chat messages, score
    factor labels) keep both versions (`titleEn`/`bodyEn`, `labelEn`…) because
    the writer cannot know the reader's language; `notify`/`postSystemMessage`
    require the English half.
  - `test/widget/english_screens_test.dart` opens every screen in English and
    fails on Indonesian interface words. What people type, and the Indonesian
    demo content the sample seeder creates (names, businesses, chat lines), are
    content, not interface text, and stay as written.
- Green identity; use `lib/core/design` tokens and components (`ui_kit.dart`,
  `SuccessPanel`, `AppScaffold` with centred titles). Never inline a hex,
  radius or spacing value in feature code.
- Support 360 dp width; minimum tap target 48 dp.
- Every screen handles empty / error / success states; mutations go through
  `runAction` so failures show a readable message.
- Destructive or money-related actions need a confirmation dialog.
- Member bottom nav is 4 flat tabs (Beranda, Catatan, Pesan, Profil) plus a raised
  center button that is a real `StatefulShellRoute` branch selector for Solar
  Hub, not a `push` — see `AppBottomNav`'s `centerItem`/`centerBranchIndex` in
  `lib/core/design/components/ui_kit.dart` and `MemberShell` in
  `lib/features/shell/shells.dart`.

## Coding Rules

- Small reusable widgets; immutable state; `copyWith` for updates.
- Comment only where the reasoning is not obvious.
- No secrets, credentials or API keys in the repository (Supabase keys come
  from `--dart-define`).

## Workflow

After changing code:
1. `dart format lib/ test/`
2. `flutter analyze`
3. `flutter test`
4. Fix everything the change broke, then summarise exactly what changed.

Never mark a task complete while `flutter analyze` fails.

## Known limits

- **The proposal (YESIST12) says more than the app does.** It describes
  "AI-driven" deep-learning credit scoring, ML scheduling, blockchain-backed
  quota trading and real-time IoT sensors. The app has a fixed-rule score, a
  fixed-rule production window, a plain ledger (Buku Kuota) and estimated kWh.
  Say so in demos: the rule-based score is the transparent, auditable first
  stage; ML calibration is the proposal's own months 11–12 step once MVP data
  exists. Its 37.5% cost reduction and 95% repayment figures are projections —
  `coop_kpis.dart` only reports what is measured, and the admin card says so.
  "Loan-Ready" (`isLoanReady`) means the score meets the cooperative's minimum;
  it is never an approval. The Laporan Kredit Energi is copied only after an
  explicit consent dialog and the app sends nothing anywhere.

- **TODO(supabase-migration)** for bilingual stored text: `notifications` needs
  `title_en` / `body_en` and `messages` needs `body_en`; `ScoreFactorSnapshot`
  already keeps `label_en` inside the existing jsonb. Errors raised by SQL
  functions are Indonesian only until they are given an English counterpart
  (the app shows them as written).
- Until Supabase is connected, data lives on one phone: admin and members only
  "meet" when they use the same device (e.g. the sample cooperative).
- The Supabase migration in `supabase/migrations/` covers the pre-Communal-Hub
  schema. `SupabaseEnergyRepository` and most of `SupabaseSolarRepository` are
  real, working implementations already — but **TODO(supabase-migration)**:
  the fields/status this refactor added
  (`Profile.hubAllocationKwh`, `SolarHub.maxLoadKw`, `HubSlot.isOpen`,
  `HubBooking.loadKw`, `HubBooking.requestedAt`,
  `EnergyRecord.bookingId`, `BookingStatus.pendingVerification`) have no
  matching Supabase columns yet, and the `request_connection` /
  `respond_to_connection_request` RPC functions `SupabaseSolarRepository`
  calls do not exist in any migration — only `LocalSolarRepository`
  implements the QR verification flow for real today. Likewise
  `respond_quota` must now complete a trade immediately (it used to leave it
  pending), `settle_quota` is gone from the app, and directed shares need
  `post_quota`'s `p_to` argument plus an `answer_quota_gift` function. Because the database
  is one file on one phone, a member's request only reaches an admin who is
  signed in on the same device until Supabase (or another shared backend) is
  connected. Add the migration and
  those two SQL functions (mirroring `book_slot` / `set_booking_status`'s
  capacity/quota enforcement) before that repository is exercised for real.
- Lending must be run by a legally registered savings-and-loan cooperative.
- Hub sessions are recorded automatically, but "automatic" currently means
  computed from the approved booking's `estKwh` (appliance watts × slot
  hours) at confirmation time — not a real-time physical sensor reading.
  Wiring up actual IoT hardware (ESP32 + sensor, per the original proposal)
  is future work; until then treat `estKwh` as a software estimate, same
  honesty bar as the roof/appliance estimates elsewhere in the app.
- The Solar Hub "best production window today" panel (`lib/core/weather/`)
  calls BMKG's public forecast API directly — the one place in the app that
  needs network access. It is opt-in (admin sets a `weatherAdm4Code` on the
  hub in Hub Settings) and hides itself on any failure; nothing else
  depends on it. The production-window score is a fixed, explainable rule — not AI: each
  BMKG point in 10.00–14.00 gets a 0–100 production score (cloud cover, rain,
  panel heat above 30°C — the heat derating is an assumption) shown on screen,
  and the booking screen prefers slots inside the best window, then free
  capacity. The recommended window is restricted to 10.00–14.00
  (`kProductionWindowStartHour`/`kProductionWindowEndHour` in
  `weather_service.dart`) — the sun's actually productive hours, not the
  full 06:00–18:00 daylight span; a window is never reported outside it and
  never extends past 14.00. Verified against a live response on
  2026-09-17: the `tcc` cloud-cover field and the rest of the parsed shape
  are correct as coded. `16.71.05.1001` (Kelurahan Delapan-belas Ilir, Kec.
  Ilir Timur Satu, Kota Palembang) is a real adm4 code — usable as the
  pilot/demo default.
