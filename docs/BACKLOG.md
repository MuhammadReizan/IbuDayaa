# IbuDaya — Backlog (beyond MVP)

> Everything here is **P2 / post-MVP** unless pulled forward. Ordered roughly by
> value for turning the prototype into a pilot. Each epic lists intent,
> dependencies, and the honesty risk it removes (many current UI claims are
> `FUTURE_IMPLEMENTATION`).

## Epic A — Real bill ingestion (OCR)

- **Intent:** replace the canned `EnergyInsight` with actual parsing of a PLN
  bill photo (total kWh, tariff class, billing period, amount).
- **Scope:** on-device OCR (ML Kit) or a server OCR; field extraction; validation
  UI; manual-correction fallback.
- **Depends on:** `image_picker` (P1 already), a parsing service behind
  `BillScanRepository`.
- **Removes claim risk:** "the app reads your bill".
- **Not included:** appliance-level disaggregation (that's Epic B).

## Epic B — Appliance-level energy attribution

- **Intent:** the "Alat Penyumbang Biaya" breakdown becomes data-driven.
- **Reality check:** true non-intrusive load monitoring needs smart-meter or
  plug-level data the product does not have. Options: (1) user-declared appliance
  inventory + usage estimates; (2) integration with a metering partner.
- **Depends on:** Epic A, an appliance inventory feature, a metering data source.
- **Removes claim risk:** the "ilustrasi" label on the appliance list.

## Epic C — BMKG weather integration + real solar scheduling

- **Intent:** `SolarDay.capacityPct` and slot recommendations come from a real
  forecast + a load-balancing algorithm.
- **Scope:** BMKG open weather API client (behind an interface); daily
  capacity/irradiance model; slot recommender; battery-state input; offline
  cache of the last forecast.
- **Depends on:** backend or on-device scheduler; a data contract with the hub
  hardware for battery/production telemetry.
- **Removes claim risk:** "ML scheduling synchronized with weather forecasts"
  (PDF) currently unimplemented.

## Epic D — Roof assessment pipeline

- **Intent:** "Radar Atap AI" produces a defensible estimate.
- **Scope (phased):** (1) manual inputs (address, roof photos, self-measured
  dimensions) → deterministic estimate; (2) assisted measurement (AR / known
  reference object); (3) satellite/imagery-based sizing via a partner.
- **Depends on:** an estimation service, possibly a solar-data partner.
- **Removes claim risk:** the MVP roof screen shows only a preliminary
  assessment ("Kelayakan Awal") + a mandatory technical-verification notice, with
  **no** accuracy %, confidence probability, or precise pitch. This epic is what
  lets any of the roof numbers (area, orientation, savings, payback) become
  defensible measurements.

## Epic E — Production credit model + lending partner

- **Intent:** move from the transparent rule-based prototype score to a validated
  model, operated with a licensed partner under OJK Reg. 29/2024.
- **Scope:** feature pipeline from real energy/arisan/business signals; model
  training + back-testing against repayment outcomes; model card + explainability
  (keep the factor breakdown); partner API for application submission, decision,
  disbursement, repayment; consent & data-use disclosures.
- **Depends on:** backend, auth/KYC (Epic G), a signed lending partner, legal
  review.
- **Removes claim risk:** the MVP score is an explainable rule-based
  `DemoCreditScoringEngine` and financing is a labelled "Simulasi Pembiayaan"
  ("Berdasarkan profil skor Anda", not "Direkomendasikan oleh AI"). This epic is
  what makes a real underwriting decision and real disbursement possible.

## Epic F — Energy Arisan settlement & P2P trading

- **Intent:** quota trading and arisan payouts become real transactions.
- **Scope:** define what "energy quota" legally means at the hub; settlement
  ledger (start centralized + auditable; evaluate blockchain only if a pilot
  needs multi-party trust per the PDF's reference); dispute handling; payout
  scheduling; wallet/e-money partner for arisan contributions.
- **Depends on:** hub operator agreements, backend, payments partner, legal
  review of P2P energy rules.
- **Removes claim risk:** "Perdagangan Energi", "Tercatat dengan Aman" implying
  real transfer.

## Epic G — Accounts, auth, KYC, multi-tenancy

- **Intent:** real users, real groups.
- **Scope:** phone-OTP auth; profile; group creation/join with an admin role;
  per-group data isolation; light KYC as required by the lending partner;
  role-based screens (member / group admin / hub operator).
- **Depends on:** backend.

## Epic H — Backend, sync, offline-write queue

- **Intent:** the app stops being single-device.
- **Scope:** API for all repositories (the interfaces already exist); an
  offline-first sync layer with an outbox for bookings/ledger/applications;
  conflict handling; local cache (SQLite/Drift or Isar) replacing the in-memory
  demo store.
- **Depends on:** Epic G.
- **Note:** keep a `DemoRepository` path forever for pitching/onboarding.

## Epic I — Messaging backend

- **Intent:** "Pesan" becomes real group + support chat.
- **Scope:** real-time transport, push, attachments, moderation for group threads,
  a support inbox routed to hub operators / loan support.
- **Depends on:** Epic G, push (Epic J).

## Epic J — Notifications (push)

- **Intent:** payment reminders, quota requests, booking reminders, score
  changes as real push.
- **Scope:** FCM; notification preferences (the Profil toggle becomes real);
  deep links (routes already stable).
- **Depends on:** Epic G/H.

## Epic K — Onboarding & digital-literacy support

- **Intent:** address the PDF's "Literacy Gap" disadvantage.
- **Scope:** guided first-run; in-context tips; audio/voice-over in Indonesian
  and regional languages; a "pendamping" (buddy) mode where an admin can assist.
- **Depends on:** i18n (Epic L).

## Epic L — Localization beyond Indonesian

- **Intent:** regional languages (Javanese, Sundanese, etc.) and accessibility
  copy.
- **Scope:** externalize all strings (structure already required in MVP); RTL not
  needed; number/date locales.

## Epic M — Field pilot instrumentation

- **Intent:** measure the impact the PDF claims (energy cost share, margins,
  repayment).
- **Scope:** privacy-respecting analytics; a metrics dashboard for operators;
  baseline/endline data capture; consent.
- **Depends on:** Epic H.

## Epic N — Platform expansion

- iOS build and store presence.
- Tablet / operator console layout.
- Dark mode (proper design pass).

## Cross-cutting / tech debt (revisit during/after MVP)

- Introduce `freezed` + `json_serializable` once models stabilise; remove
  hand-written `copyWith`.
- Add golden tests for the design-system components.
- CI: `flutter analyze` + tests on every PR; a check that the demo flavor has no
  `http`/`dio` in its dependency graph.
- Replace bundled placeholder illustrations with final licensed art.
- Accessibility audit with TalkBack.
- App size / startup profiling before the competition build.

## Decisions applied (this planning round — no longer open)

Resolved by the team's final product decisions; folded into all planning docs:

1. Canonical persona = **Ibu Clara** ("Siti Rahma" is a community member only).
2. Energy-quota sharing is **P0-Lite** and appears in the live demo.
3. Roof screen: **no** "Akurasi AI 92%", **no** confidence probability, **no**
   precise pitch — a "Kelayakan Awal" assessment + technical-verification notice.
4. Credit score = explainable rule-based `DemoCreditScoringEngine`
   (30/24/18/10 = 82); replaceable by ML behind the same interface.
5. Financing = "Simulasi Pembiayaan" only; flat 2%/month DEMO ASSUMPTION;
   cap Rp 2.000.000; "Berdasarkan profil skor Anda".
6. **No blockchain** in the MVP.
7. Primary classification = **SDG 11**.
8. Android app id `com.baswaramusi.ibudaya`, display name "IbuDaya".

## Remaining confirmations (asset/polish only — not implementation blockers)

- Final licensed illustrations + exact brand colour hex + font file
  (`DESIGN_SYSTEM.md` values are provisional `PROTOTYPE_DECISION`s).
- Grid CO₂ emission-factor constant (`DATA_MODEL.md §4.4`).
- The exact "Reset Demo" control placement (`DEMO_SCRIPT.md`).
