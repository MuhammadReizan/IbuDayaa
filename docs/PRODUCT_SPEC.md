> **DOKUMEN V1 — sudah digantikan.** Redesign v2 (role anggota/admin, pinjaman ditinjau admin koperasi, scan OCR, lokal lalu Supabase) dijelaskan di `CLAUDE.md`, `docs/SCREENS.md`, dan `docs/SUPABASE.md`. Isi di bawah hanya untuk riwayat.

# IbuDaya — Product Specification

> Phase: Planning. This document describes **what** IbuDaya is and **why**. It is
> derived from the competition PDF (authoritative) and the current prototype
> screenshots (directional), updated with the team's final product decisions
> (see `ASSUMPTIONS_AND_RISKS.md §0` for the honesty-label vocabulary).

## 1. Source of truth

| Source | Role |
| --- | --- |
| `IEEE-New (1).pdf` (Team Baswara Musi, "IbuDaya: AI-Powered Community Solar & Micro-Financing Cooperative", WePOWER, **SDG 11 — Sustainable Cities and Communities**) | Authoritative for product claims, problem framing, and the three pillars. |
| Prototype screenshots (14 screens) | **Provisional** visual source (no Figma exists — decision #4). Directional, not immutable. |
| Team final product decisions (this planning round) | Override where they conflict with the screenshots. |
| Flutter repo (`C:\ibudaya`) | Currently an unmodified `flutter create` scaffold. |

## 2. Honesty hierarchy (decision #10)

Every capability in this product is one of:

`IMPLEMENTED` · `DEMO_SIMULATION` · `PROTOTYPE_DECISION` · `ASSUMPTION` ·
`FUTURE_IMPLEMENTATION`

No `DEMO_SIMULATION` capability may be presented as a production capability. The
app surfaces this through qualifier labels ("estimasi", "simulasi", "ilustrasi",
"data contoh") and an explicit disclosure in "Tentang IbuDaya".

## 3. Vision

IbuDaya is a mobile cooperative platform for **women-led MSMEs in Indonesia**. It
connects three things the PDF presents as one system:

1. A **communal off-grid Solar Hub** that powers shared productive appliances
   (electric ovens, sewing machines, refrigerators, blenders).
2. An **alternative credit score** built from energy-usage and business-activity
   data, so unbanked women can qualify for legal micro-financing.
3. A **digital Energy Arisan** — the traditional rotating savings group turned
   into a transparent ledger, plus virtual peer-to-peer energy-quota sharing.

Conclusion quote from the PDF: *"Empowering Women is the Single Most Effective
Way to Combat Climate Change."*

## 4. Problem statement (from PDF)

1. **Economic energy burden.** Women-led MSMEs in Indonesia spend up to ~20% of
   revenue on electricity; fossil-fuel-heavy grid costs suppress margins and
   block business growth.
2. **Financial exclusion / the credit gap.** Over 60% of Indonesian women
   entrepreneurs are "unbanked" and lack formal collateral, so they cannot
   finance the upfront cost of solar technology.
3. **Resource inefficiency & regulatory barriers.** Individual solar adoption is
   blocked by technical illiteracy and high CAPEX; existing regulation limits P2P
   energy trading, leaving community energy potential untapped.

## 5. Target user

- **Canonical demo persona — "Ibu Clara"** (`PROTOTYPE_DECISION`, decision #1):
  owner of a home-based food/craft MSME in an urban-fringe Indonesian city
  (screenshots reference Palembang). WhatsApp-literate; limited experience with
  formal financial apps. Member of the "Arisan Energi Melati" group.
  **"Ibu Clara" is used on every screen** (Home, Credit Score, Profile, Impact).
- **"Siti Rahma"** exists only as another **Energy Arisan community member**
  (e.g. in "Perdagangan Energi" offers and as a message contact) — never as the
  signed-in user.
- **Secondary personas (context only, not app users in MVP):** Arisan
  coordinator; Solar Hub operator; a future lending partner's loan officer.

Design implication (`DESIGN_SYSTEM.md`): plain Indonesian, large tap targets,
minimal jargon, explain every number.

## 6. Core pillars in detail

### 6.1 Communal Solar Hub

| Element | Description | Source / status |
| --- | --- | --- |
| Solar Hub | A shared, legal off-grid solar installation serving an MSME group, powering high-impact productive tools. | PDF |
| Roof **preliminary assessment** ("Radar Atap") | Camera-framed scan returns an **initial estimate**: "Kelayakan Awal: Sangat Baik", estimated potential roof area, roof orientation, sun-exposure potential. Every result states it is an initial estimation that **requires technical verification before installation**. | Screenshots + decision #2. `DEMO_SIMULATION`. |
| Roof financial projection (savings, payback/ROI, capacity) | **Not in P0** (CR-13 / decision #3). No savings figure, payback, or capacity calculation appears on the P0 roof screen. | `FUTURE_IMPLEMENTATION` — `BACKLOG` Epic D. |
| Capacity-aware booking ("Solar Hub Booking") | Reserve a time slot to run one appliance; the app recommends a slot from the day's (canned) solar capacity. | Screenshots. Selection logic `IMPLEMENTED`; capacity/recommendation `DEMO_SIMULATION`. |
| Weather-synced scheduling | ML scheduling synchronised with weather forecasts (PDF cites BMKG's open weather API). | PDF. `FUTURE_IMPLEMENTATION`. |

- **No AI-accuracy percentage, confidence probability, or measurement-precision
  claim** appears anywhere in the roof feature (decision #2). The screenshot's
  "Akurasi AI 92%" and "Kemiringan Atap 28°" are removed.

### 6.2 Alternative Credit Scoring

| Element | Description | Source / status |
| --- | --- | --- |
| Score | A 0–100 score (canonical demo value **82 / 100 — "Baik Sekali"**). | Screenshots + decision #7 |
| Engine | `DemoCreditScoringEngine` — an **explainable, rule-based, deterministic** engine. It is **not** a trained ML model and the UI must not imply one. | Decision #7. `IMPLEMENTED`. |
| Rubric (fixed) | Energy usage consistency **30 / 35**; Payment history **24 / 30**; Business activity **18 / 20**; Community participation **10 / 15**; total **82 / 100**. | Decision #7 |
| Explainability | The score screen shows one row per category with points/max and a plain reason — the four categories are the entire explanation. | Screenshots + `CLAUDE.md` |
| Output | Indicative micro-loan ceiling for the demo: **Rp 2.000.000** when eligible. | Screenshots + decision #6 |
| Regulatory context | The PDF states alternative credit scoring is legally sanctioned in Indonesia via OJK Regulation No. 29 of 2024. Repeated in-app only as a cited research finding, not as our own compliance claim. | PDF |
| Replaceability | The engine sits behind an interface so a validated ML implementation can replace it later **without UI changes**. | Decision #7. `FUTURE_IMPLEMENTATION`. |

### 6.3 Energy Arisan  (core differentiator)

| Element | Description | Source / status |
| --- | --- | --- |
| Digital Arisan ledger | The group ("Arisan Energi Melati", 12 members) with an **append-only transparent record** of contributions, payouts, and whose turn is next. | PDF + screenshots. `IMPLEMENTED` (local). |
| Rotation schedule | Calendar / "Giliran Pemakaian Berikutnya" showing the next member's turn. | Screenshots |
| **Energy-quota sharing** ("Perdagangan Energi") — **P0-Lite, in the demo** | A member publishes spare kWh (simple 1/2/3 kWh) for a time slot, or takes an available quota from another member's offer. Each action appends a ledger entry and updates the member's quota. Confirmation screen included. | Screenshots + decision #3. `IMPLEMENTED` (local, minimal). |
| Micro-loan access | The Arisan is an entry point to the financing simulation. | PDF |
| Advanced trading | Marketplace, bidding, negotiation, filters, real-time updates, cross-community trading, chat-based negotiation. | Decision #3. `FUTURE_IMPLEMENTATION`. |
| Blockchain / on-chain settlement | The PDF's research survey references a blockchain P2P model. | Decision #8. `FUTURE_IMPLEMENTATION` only — **no blockchain in the MVP and no UI wording implying it.** |

## 7. Supporting features (in the demo path)

| Feature | Purpose | Status |
| --- | --- | --- |
| Energy bill scan ("Scan Tagihan") | Capture/upload a PLN bill photo as the entry point to energy insight. | Capture/upload UI `IMPLEMENTED` (P1 real picker); result is `DEMO_SIMULATION`. No OCR. |
| AI Energy Insight ("Analisis Energi") | Explain a usage spike, attribute added cost to appliances ("ilustrasi"), recommend Solar Hub scheduling. | `DEMO_SIMULATION`. Appliance-level attribution is `FUTURE_IMPLEMENTATION`. |
| **Simulasi Pembiayaan** | Set an amount (≤ Rp 2.000.000), business purpose, and tenor (3/6/12), then **calculate** an indicative installment and see the result (principal, tenor, flat rate, total cost, total repayment, monthly installment + disclaimer). **No application is submitted** (CR-2). | Installment math `IMPLEMENTED` (flat **2%/month**, decision #6). The flow ends at the result — **not** approval, submission, underwriting, disbursement, or a regulated product. |
| Impact / Profile ("Profil Saya" — Ibu Clara) | Cumulative impact (kWh used, kWh shared, CO₂ avoided, group size) and settings. | Values `DEMO_SIMULATION` ("data komunitas"). |
| Messages ("Pesan") | Group and 1:1 demo threads. | `P1`. Read-only; no messaging backend. |
| Notifications | Alerts for quota requests, bookings, payment reminders. | `P1`. Local demo list. |
| "Tentang IbuDaya" | Team, **SDG 11** (primary; SDG 5/7/8 mentioned only as related impact areas), and the honesty disclosure. | `P0`. |

## 8. Financing — hard product boundaries (decision #6)

The MVP financing feature **is a calculation only**. It does not: submit an
application; approve loans; perform underwriting; disburse funds; represent a
regulated lending provider; represent a financial partnership.

- The P0 flow is: **Skor Kredit Energi → Simulasi Pembiayaan → select amount →
  select business purpose → select tenor → calculate → Hasil Simulasi
  Pembiayaan.** It **ends at the result** — there is no "Ajukan", "Kirim
  Pengajuan", or "Pengajuan Terkirim" (CR-2).
- Screen / CTA copy: **"Simulasi Pembiayaan"** / **"Hitung Simulasi"** — never
  "Pinjaman Disetujui", "Pinjaman", "Ajukan", or "Pengajuan".
- Eligibility copy: **"Berdasarkan profil skor Anda"** — never "Direkomendasikan
  oleh AI".
- The result screen shows: principal, tenor, simulated flat rate, estimated total
  cost, estimated total repayment, estimated monthly installment, and a visible
  disclaimer that this is a simulation, not an official financing offer.
- If a secondary CTA is kept it may only read **"Saya Tertarik"** and must state
  that partner financing integration is `FUTURE_IMPLEMENTATION` (no submission).
  Preferred P0: omit it.
- Demo cap: **Rp 2.000.000**. Tenors: **3 / 6 / 12 months**. Rate: **flat 2% per
  month (DEMO ASSUMPTION)**. Formula and worked examples: `DATA_MODEL.md §4.3`.

## 9. Explicit product-level non-goals

Out of scope for **the product as demonstrated**:

- Any hardware, installation, metering, or physical energy delivery.
- Actual movement of money (disbursement, repayment, transfer).
- Actual transfer of electricity or grid interaction.
- Being a licensed lender, payment institution, or credit bureau.
- Legal/compliance representations beyond citing the PDF.
- KYC / identity verification.
- Blockchain / distributed ledger.

## 10. SDG classification (decision #9)

Primary: **SDG 11 — Sustainable Cities and Communities** (as on the PDF title
page). SDG 5 (Gender Equality), SDG 7 (Affordable & Clean Energy), and SDG 8
(Decent Work & Economic Growth) may be described **only** as related impact areas
where relevant. Do not replace SDG 11.

## 11. Success criteria (competition)

`PROTOTYPE_DECISION` — what "done" means for this phase:

1. A judge can watch a **3–5 minute uninterrupted live demo** on an Android phone
   in airplane mode following `DEMO_SCRIPT.md`.
2. The golden path runs without crashes, network calls, or visible placeholder
   text: Home → Bill Scan → Energy Insight → Solar Hub (Radar Atap → Booking) →
   Energy Arisan (overview → share quota) → Credit Score → Simulasi Pembiayaan →
   Impact/Profile.
3. Every `DEMO_SIMULATION` number on screen has a visible qualifier; financing
   shows its disclaimer.
4. The credit score (82) and loan installments are reproducible from the
   documented formulas and covered by unit tests.
5. Demo Mode can be reset to a known state in under 5 seconds between runs.
6. `flutter analyze` is clean.

## 12. Open product questions

Tracked in `ASSUMPTIONS_AND_RISKS.md §6`. After this decisions round, none are
blockers for starting implementation; remaining items are asset/polish
confirmations (final illustrations, exact colour hex, emission-factor constant).
