# IbuDaya — Screen Inventory

> One entry per screen. Fields: **Purpose**, **Primary action**, **Required
> data**, **States**, **Navigation** (in / out), **Edge cases**, **Acceptance
> criteria (AC)**.
>
> Screens are grouped by feature. MVP class (P0 / P0-Lite / P1 / P2) from
> `MVP_SCOPE.md` is on each heading. `DEMO_SIMULATION` = pre-scripted demo output
> (no model / OCR / network). Persona is **Ibu Clara** on every screen; "Siti
> Rahma" only appears as a community member.

## Index

| ID | Screen | Feature | Class |
| --- | --- | --- | --- |
| SC-00 | Splash / Bootstrap | Shell | P0 |
| SC-01 | Home (Beranda) | Shell | P0 |
| SC-02 | Scan Tagihan Listrik | Bill scan | P0 |
| SC-03 | Analisis AI Energi | Bill scan | P0 |
| SC-04 | Solar Hub — Scan Atap | Solar Hub | P0 |
| SC-05 | Radar Atap — Kelayakan Awal | Solar Hub | P0 |
| SC-06 | Solar Hub Booking | Solar Hub | P0 |
| SC-07 | Booking Terkonfirmasi | Solar Hub | P0 |
| SC-08 | Arisan Energi (overview) | Energy Arisan | P0 |
| SC-09 | Skor Kredit Energi | Credit scoring | P0 |
| SC-10 | Simulasi Pembiayaan (input) | Financing | P0 |
| SC-11 | Hasil Simulasi Pembiayaan | Financing | P0 |
| SC-12 | Perdagangan Energi | Energy Arisan | P0-Lite |
| SC-13 | Bagikan Kuota | Energy Arisan | P0-Lite |
| SC-14 | Minta Kuota | Energy Arisan | P0-Lite |
| SC-15 | Penawaran Berhasil Dipublikasikan | Energy Arisan | P0-Lite |
| SC-16 | Pesan (list) | Messages | P1 |
| SC-17 | Pesan — Thread | Messages | P1 |
| SC-18 | Profil Saya | Profile | P0 |
| SC-19 | Tentang IbuDaya | Profile | P0 |
| SC-20 | Notifikasi | Shell | P1 |
| SC-21 | Pengaturan / Demo Mode | Profile | P0 |
| SC-22 | Onboarding (carousel) | Shell | P1 |

Shared, non-screen widgets (loading / empty / error / confirm dialog) are in
`DESIGN_SYSTEM.md`.

---

## SC-00 — Splash / Bootstrap  `P0`

- **Purpose:** load the demo seed into repositories before any feature screen.
- **Primary action:** none (automatic).
- **Required data:** `assets/demo/*.json` bundle; app version.
- **States:** loading (default); error (seed failed).
- **Navigation:** in — app launch. out — replace with SC-01 on success; stay with
  retry on error.
- **Edge cases:** corrupt/missing asset → error state with "Coba lagi"; very fast
  load → still show splash ≥ 400 ms to avoid a flash.
- **AC:**
  1. Reaches Home within ~1.5 s on a mid-range device, offline.
  2. On forced seed failure, shows the error state and retry works.
  3. No network request is made.

---

## SC-01 — Home (Beranda)  `P0`

- **Purpose:** demo launch pad; snapshot of savings, energy source mix, credit
  score, Arisan status, and alerts; entry to every pillar.
- **Primary action:** tap a **quick action** (Scan Tagihan / Solar Hub / Arisan /
  Pembiayaan).
- **Required data:** user greeting name; month saving (Rp); % energy from Solar
  Hub; credit score + band; Arisan status (Lunas/…); power-usage alerts list
  (title, severity, time window); optional "Jadwal AI Hari Ini" items.
- **States:**
  - success (all tiles populated from seed);
  - partial (a tile's data missing → that tile shows its own empty text, page
    still renders);
  - loading (brief, on first entry / after demo reset);
  - error (seed unreadable → global error screen, not a broken Home).
- **Navigation:** in — SC-00, or bottom-nav "Beranda", or "Kembali ke Beranda"
  CTAs. out — SC-02 (Scan Tagihan), SC-04 (Solar Hub tab), SC-08 (Arisan),
  SC-10 (Pembiayaan), SC-09 (score tile), SC-20 (bell icon).
- **Edge cases:** long name truncates with ellipsis; ≥ 3 alerts → list scrolls
  within a max height or shows "Lihat Semua"; 0 alerts → "Tidak ada peringatan
  daya hari ini."; very small width (360 dp) → quick-action grid stays 4-up or
  wraps to 2×2 without overflow.
- **AC:**
  1. All four quick actions navigate to the correct screen.
  2. Score tile shows the same score value as SC-09 for the active scenario.
  3. Arisan status matches SC-08 data.
  4. No RenderFlex overflow at 360 / 412 dp.
  5. Every monetary figure has a qualifier label ("bulan ini", "estimasi").

---

## SC-02 — Scan Tagihan Listrik  `P0`

- **Purpose:** entry point to energy insight; capture or upload a PLN bill image.
- **Primary action:** tap **Ambil Foto Tagihan** (or **Unggah dari Galeri**).
- **Required data:** guidance copy; (P1) camera/gallery permission status.
- **States:** idle (default); picking (camera/gallery open — P1); analysing
  (loading, ~1.2 s canned); → navigates to SC-03. No error state needed for the
  canned path.
- **Navigation:** in — Home quick action. out — SC-03 on analyse complete; back →
  Home.
- **Edge cases:** permission denied (P1) → inline note + fall back to the canned
  analyse path so the demo never blocks; user backs out during "analysing" → no
  state kept.
- **AC:**
  1. Both buttons lead to SC-03 within ~1.5 s, offline.
  2. In the P1 camera path, a denied permission still reaches SC-03.
  3. Buttons meet the 48 dp minimum target.

---

## SC-03 — Analisis AI Energi  `P0`

- **Purpose:** explain a usage spike, attribute added cost to appliances, and
  route to Solar Hub scheduling.
- **Primary action:** tap **Lihat Jadwal Solar Hub**.
- **Required data (from scenario `energyInsight`):** spike window; added monthly
  cost (Rp); ranked appliance contributions (name, Rp delta); main insight
  sentence; optional per-appliance tips.
- **States:** loading (brief); success; empty ("Belum ada analisis" + scan CTA)
  if the scenario has no insight.
- **Navigation:** in — SC-02. out — SC-06 (Solar Hub Booking) via CTA; back →
  SC-02 → Home.
- **Edge cases:** long appliance names wrap; 0 appliance contributions → hide that
  block; added cost = 0 → show "Tidak ada lonjakan terdeteksi" success variant.
- **AC:**
  1. Appliance list is sorted by Rp delta descending.
  2. Added-cost figure carries an "estimasi" label; appliance block carries an
     "ilustrasi" label.
  3. CTA lands on SC-06.
  4. No horizontal overflow with the longest seeded appliance name.

---

## SC-04 — Solar Hub — Scan Atap  `P0`

- **Purpose:** start the roof assessment.
- **Primary action:** tap **Scan Sekarang**.
- **Required data:** guidance copy; (P2) camera preview.
- **States:** idle; scanning (loading, ~1.5 s canned) → SC-05.
- **Navigation:** in — bottom-nav "Solar Hub". out — SC-05; back → previous tab.
- **Edge cases:** no camera hardware / permission → static framed illustration and
  the button still works (canned).
- **AC:**
  1. "Scan Sekarang" reaches SC-05 within ~2 s, offline.
  2. Screen renders with no camera permission granted.

---

## SC-05 — Radar Atap — Kelayakan Awal  `P0`

- **Purpose:** present a **preliminary roof assessment** (`DEMO_SIMULATION`) and
  the value case for a communal Solar Hub — explicitly an initial estimate that
  needs technical verification (decision #2).
- **Primary action:** tap **Lanjut ke Rekomendasi Solar Hub**.
- **Required data (scenario `roofScan`):** `suitability` → "Kelayakan Awal:
  Sangat Baik"; estimated potential area (m², rounded); roof orientation label;
  sun-exposure potential label (qualitative); `verificationNotice` string; tip
  copy.
  **P0 shows no financial projection** — no monthly saving, no payback/ROI, no
  capacity calculation (CR-13 / decision #3 roof simplification). Those fields
  are `FUTURE_IMPLEMENTATION` (`DATA_MODEL §3.6`, `BACKLOG` Epic D).
- **States:** loading (from SC-04); success. (No error — `DEMO_SIMULATION`.)
- **Navigation:** in — SC-04. out — SC-06 via CTA; back → SC-04.
- **Edge cases:** lower `suitability` variants ("Baik"/"Cukup"/"Kurang") must
  render without crashing (not used in the happy path).
- **AC:**
  1. **No AI-accuracy percentage, no confidence probability, and no precise pitch
     (°) appears anywhere on the screen.**
  2. **No rupiah savings figure, payback period, ROI, or capacity calculation
     appears on the screen** (CR-13).
  3. The `verificationNotice` ("estimasi awal … perlu verifikasi teknis …") is
     visible without scrolling past the metrics.
  4. Area / orientation / sun-exposure are labelled "estimasi awal".
  5. CTA lands on SC-06.

---

## SC-06 — Solar Hub Booking  `P0`

- **Purpose:** reserve a time slot to run one productive appliance, guided by the
  day's (canned) solar capacity.
- **Primary action:** tap **Booking Sekarang** after choosing an appliance and a
  slot.
- **Required data (scenario `solarDay`):** today's capacity % ; appliance list
  (name, approx. power kW, icon); recommended slot id + one-line rationale; slot
  list (id, label, availability).
- **States:**
  - default (nothing selected — CTA disabled);
  - appliance selected (recommendation highlighted);
  - slot selected (CTA enabled);
  - submitting (brief);
  - → SC-07.
- **Navigation:** in — SC-03 CTA, SC-05 CTA, or Home. out — SC-07 on confirm;
  back → previous screen.
- **Edge cases:** slot marked "penuh" is disabled; picking a non-recommended slot
  shows a non-blocking note; nothing selected → inline validation; back during
  "submitting" → cancel, no booking created.
- **AC:**
  1. CTA is disabled until both an appliance and a slot are chosen.
  2. Exactly one appliance and one slot can be selected (single-select).
  3. Confirmed booking is written to state and shown on SC-07.
  4. Capacity gauge value equals the scenario's `solarDay.capacityPct`.

---

## SC-07 — Booking Terkonfirmasi  `P0`

- **Purpose:** confirm the reservation and offer a way back.
- **Primary action:** tap **Kembali ke Beranda** (or **Lihat Jadwal**).
- **Required data:** the just-created booking (appliance, slot, date, reference
  id).
- **States:** success only.
- **Navigation:** in — SC-06. out — Home; (P1) Home "Jadwal AI Hari Ini" now
  lists this booking.
- **Edge cases:** hardware back button → Home (not back into the form).
- **AC:**
  1. Shows the exact appliance + slot chosen on SC-06.
  2. Returns to Home; the form is not re-entered on back.

---

## SC-08 — Arisan Energi (overview)  `P0`

- **Purpose:** show the digital Arisan — my status, the rotation, and the
  transparent ledger.
- **Primary action:** browse; secondary CTAs to **Perdagangan Energi** (P0-Lite)
  and **Skor Kredit Energi**.
- **Required data (scenario `arisanGroup`):** group name; member count; my
  contribution status; my turn position + next-turn date; rotation slots (date,
  member); recent transactions (date, member, type, amount, status, ref id).
- **States:** success; empty ledger variant; loading (brief after reset).
- **Navigation:** in — Home "Arisan" quick action or Arisan status card. out —
  SC-12 (P0-Lite), SC-09; row tap → transaction detail (read-only).
- **Edge cases:** long member names truncate; ledger > N rows → scroll or "Lihat
  Semua"; calendar month with no turns → still renders.
- **AC:**
  1. Group name and member count match Home's Arisan card and SC-18 impact
     ("… dalam Grup").
  2. Ledger is ordered newest first.
  3. "Skor Kredit Energi" CTA lands on SC-09.
  4. Ledger copy says "tercatat transparan" — no "blockchain" wording.

---

## SC-09 — Skor Kredit Energi  `P0`

- **Purpose:** present the score **and** the four categories behind it, then route
  to the financing simulation.
- **Primary action:** tap **Simulasi Pembiayaan**.
- **Required data:** score (0–100) + band from `DemoCreditScoringEngine`
  (`IMPLEMENTED`, rule-based); one row per `CreditCategory` (label, direction,
  points / max, reason); eligibility; borrowing ceiling (Rp).
- **States:** success; "data contoh" banner variant if inputs are partial;
  loading (brief). No hard error — always renders a score.
- **Navigation:** in — Home score tile or SC-08 CTA. out — SC-10 via CTA; (P1)
  category row → detail.
- **Edge cases:** score at 0 or 100 → gauge clamps; all categories ≥ 0.6 → header
  "Kekuatan Skor Anda"; mixed → neutral header "Rincian Skor Anda"; ceiling = 0
  (score < 65) → "Belum memenuhi syarat" state with guidance and no CTA to SC-10.
- **AC:**
  1. The displayed score equals `DemoCreditScoringEngine.compute(scenario.creditInputs)`;
     for the happy path it is exactly **82** with categories **30 / 24 / 18 / 10**.
  2. The four category rows sum to the displayed score — there is no hidden term.
  3. Category reasons are generated by the engine, not hardcoded per scenario.
  4. Ceiling shown here (Rp 2.000.000 when eligible) equals the slider max on
     SC-10.
  5. Every figure carries "simulasi" / "estimasi". The engine is **not**
     described as AI/ML anywhere on the screen.

---

## SC-10 — Simulasi Pembiayaan (input)  `P0`

- **Purpose:** let the user set up a financing **simulation** — amount, business
  purpose, tenor — and run the calculation. **No application is submitted.** Not
  approval, underwriting, disbursement, or a regulated product (decision #6).
- **Primary action:** tap **Hitung Simulasi**.
- **Required data:** carried-in credit score + eligibility label; `LoanParams`
  (`maxDemoFinancingIdr` = Rp 2.000.000, `flatMonthlyRatePct` = 2.0,
  tenors 3/6/12); purpose options.
- **States:**
  - editing (default, amount = a sensible preset ≤ Rp 2.000.000);
  - valid (purpose + tenor chosen → CTA enabled);
  - calculating (brief);
  - → SC-11.
- **Navigation:** in — SC-09 CTA or Home "Pembiayaan". out — SC-11 on calculate;
  back → SC-09 (values may be kept for the session).
- **Edge cases:** amount clamped to Rp 2.000.000 with helper text; score < 65 →
  eligibility line reads "Perlu peninjauan manual" (calculation still allowed);
  tenor/purpose not chosen → CTA disabled; rotate device → state preserved.
- **AC:**
  1. Screen title reads **"Simulasi Pembiayaan"**. No "Ajukan", "Kirim
     Pengajuan", "Pinjaman Disetujui", "pengajuan", or "disetujui" wording
     anywhere.
  2. Eligibility line reads **"Berdasarkan profil skor Anda"** (or "Perlu
     peninjauan manual"), never "Direkomendasikan oleh AI".
  3. Slider maximum = **Rp 2.000.000**; tenor options are 3 / 6 / 12 months.
  4. The CTA computes a `LoanSimulation` and navigates to SC-11. It does **not**
     create, submit, or persist any application.

---

## SC-11 — Hasil Simulasi Pembiayaan  `P0`  *(golden-path end for financing)*

- **Purpose:** show the simulation result and stop. This is the P0 end of the
  financing flow — there is no submission step.
- **Primary action:** tap **Kembali ke Beranda** (or **Ulangi Simulasi** → SC-10).
- **Required data (`LoanSimulation`):** principal; tenor (months); simulated flat
  rate (2% / bulan); estimated total cost; estimated total repayment; estimated
  monthly installment.
- **States:** success only.
- **Navigation:** in — SC-10. out — Home, or back to SC-10 to re-run. Hardware
  back → Home.
- **Edge cases:** non-round installment (e.g. ≈ Rp 373.333) shown with a "≈"
  prefix — it is correct (CR-14).
- **AC:**
  1. Shows exactly: principal, tenor, simulated flat rate, estimated total cost,
     estimated total repayment, estimated monthly installment.
  2. Numbers match `LoanSimulation` / the worked rows in `DATA_MODEL.md §4.3`
     (unit tested).
  3. A **visible disclaimer** is present: "Ini simulasi, bukan penawaran resmi.
     IbuDaya tidak menyalurkan pinjaman."
  4. No "disetujui" / "approved" / "pengajuan terkirim" wording anywhere.
  5. If a secondary CTA is shown it may only read **"Saya Tertarik"** and must
     state that partner financing integration is `FUTURE_IMPLEMENTATION`
     (it performs no submission). Preferred P0: omit it and end at the result.

---

## SC-12 — Perdagangan Energi  `P0-Lite`

- **Purpose:** simple hub for energy-quota sharing — my available quota, my
  published offers, and offers from other members. **No** filters, search,
  sorting, bidding, or real-time updates (decision #3).
- **Primary action:** tap **Bagikan Kuota** (or a member row's **Minta**).
- **Required data (scenario `quota` + `offers`):** my `availableKwh` /
  `neededKwh`; my turn slot label; my published offers; member offers (name,
  kWh, slot, status).
- **States:** success; empty ("Belum ada penawaran dari anggota"); loading.
- **Navigation:** in — SC-08. out — SC-13 (share), member row → SC-14.
- **Edge cases:** `availableKwh` = 0 → "Bagikan Kuota" disabled with a reason;
  offer `taken` → row disabled "sudah diambil".
- **AC:**
  1. "Kuota Energi Saya" equals `EnergyQuota.availableKwh` and matches SC-13.
  2. Publishing (SC-13) or taking an offer (SC-14) updates this screen's quota
     value and offer list **without a reload**.
  3. No "blockchain" / "on-chain" wording; a ledger reference reads "tercatat
     transparan".

---

## SC-13 — Bagikan Kuota  `P0-Lite`

- **Purpose:** compose and publish one quota offer, kept intentionally simple.
- **Primary action:** tap **Publikasikan Penawaran**.
- **Required data:** my `availableKwh`; the fixed slot options; optional note.
- **States:** editing; preview (step 5); publishing; → SC-15. Validation state
  when the chosen amount > available.
- **Navigation:** in — SC-12. out — SC-15 on publish; cancel → confirm discard →
  SC-12.
- **Edge cases:** amount chips (1 / 2 / 3 kWh) above `availableKwh` are disabled;
  no slot chosen → CTA disabled; note capped at 140 chars.
- **AC:**
  1. Amount is chosen from **1 / 2 / 3 kWh** chips only; cannot exceed
     `availableKwh`.
  2. The step-5 preview reflects the exact amount, slot, and note.
  3. Publish appends one `QuotaOffer` (`open`) **and** one `LedgerEntry`
     (`quotaShared`, `pending`), decrements `availableKwh`, and navigates to
     SC-15.

---

## SC-14 — Minta Kuota  `P0-Lite`

- **Purpose:** take / request an available quota from a member's offer.
- **Primary action:** tap **Kirim Permintaan**.
- **Required data:** the selected `QuotaOffer` (owner name, kWh, slot); optional
  note.
- **States:** editing; submitting; success (confirmation card / sheet).
- **Navigation:** in — SC-12 (member row). out → back to SC-12 with a
  confirmation; (P1) a notification is added.
- **Edge cases:** offer becomes `taken` before submit → block with "sudah
  diambil".
- **AC:**
  1. Shows the owner and amount from the chosen offer (no editing of amount in
     the Lite version — take the offered amount as-is).
  2. Submit appends one `QuotaRequest` + one `LedgerEntry` (`quotaReceived`,
     `pending`), sets the offer to `taken`, updates `neededKwh`, and returns to
     SC-12.

---

## SC-15 — Penawaran Berhasil Dipublikasikan  `P0-Lite`

- **Purpose:** confirm a published quota offer.
- **Primary action:** tap **Kembali ke Perdagangan Energi**.
- **Required data:** the published offer summary (kWh, slot, note).
- **States:** success only.
- **Navigation:** in — SC-13. out — SC-12.
- **Edge cases:** hardware back → SC-12, not SC-13.
- **AC:**
  1. Summary matches the SC-13 preview.
  2. Copy: "Tercatat dengan Aman / transparan" — **no "blockchain" wording**.

---

## SC-16 — Pesan (list)  `P1`

- **Purpose:** list group and 1:1 threads.
- **Primary action:** tap a thread → SC-17.
- **Required data:** threads (title, avatar/type, last message preview,
  timestamp, unread flag).
- **States:** success; empty (per filter); loading.
- **Navigation:** in — bottom-nav "Pesan". out — SC-17. Compose FAB hidden or
  disabled.
- **Edge cases:** filter with no results → "Tidak ada pesan."; long preview
  truncates to one line.
- **AC:**
  1. Filter chips (Semua / Belum Dibaca / Grup) filter the list correctly.
  2. Unread count on the "Belum Dibaca" chip matches the list.

---

## SC-17 — Pesan — Thread  `P1`

- **Purpose:** read a demo conversation.
- **Primary action:** read / scroll (no send in MVP).
- **Required data:** ordered messages (sender, text, timestamp).
- **States:** success; loading. Input bar disabled or hidden.
- **Navigation:** in — SC-16. out — back to SC-16.
- **Edge cases:** long messages wrap; system/notice messages styled distinctly.
- **AC:**
  1. Messages render in chronological order.
  2. No send affordance is interactive.

---

## SC-18 — Profil Saya  `P0`

- **Purpose:** identity, cumulative impact, and settings entry.
- **Primary action:** tap a settings row (primarily **Tentang IbuDaya** /
  **Pengaturan**).
- **Required data:** name (**"Ibu Clara"**), role ("Anggota IbuDaya"), phone,
  city, join date, member id; impact metrics (energy used kWh, energy shared kWh,
  CO₂ avoided kg, group size); settings row list.
- **States:** success; loading (brief).
- **Navigation:** in — bottom-nav "Profil". out — SC-19, SC-20, SC-21; "Keluar
  Akun" → confirm dialog → no-op or SC-00.
- **Edge cases:** group size here must equal SC-08's member count; long city/name
  truncate; stub rows show "Segera hadir".
- **AC:**
  1. The identity card shows **"Ibu Clara"** — the same name as Home (SC-01) and
     Credit Score (SC-09). "Siti Rahma" never appears as the account holder.
  2. Impact metrics come from demo data and are labelled "data komunitas".
  3. "Tentang IbuDaya" opens SC-19.
  4. Group size matches SC-08.

---

## SC-19 — Tentang IbuDaya  `P0`

- **Purpose:** honest product + team summary; the place for the "prototype"
  disclosure.
- **Primary action:** read; back.
- **Required data:** static: team name (Baswara Musi); **SDG 11 — Sustainable
  Cities and Communities** as the primary classification (SDG 5 / 7 / 8 named
  only as related impact areas); one-paragraph product summary; three-pillar
  list; honesty disclosure; app version.
- **States:** static.
- **Navigation:** in — SC-18. out — back.
- **Edge cases:** none.
- **AC:**
  1. States clearly that the credit score is a rule-based prototype and that the
     bill/roof analyses and figures shown in the app are demo simulations /
     estimates.
  2. Names the three pillars exactly as `PRODUCT_SPEC.md`.
  3. Shows "SDG 11" as primary; does not present SDG 7 as the primary goal.
  4. Contains no "blockchain" claim.

---

## SC-20 — Notifikasi  `P1`

- **Purpose:** local demo list of alerts (quota requests, bookings, payment
  reminders).
- **Primary action:** tap a notification → deep-link to the related screen
  (best-effort).
- **Required data:** notifications (icon, title, body, timestamp, read flag,
  optional route).
- **States:** success; empty ("Tidak ada notifikasi"); loading.
- **Navigation:** in — Home bell icon or SC-21. out — deep-linked screen or back.
- **Edge cases:** notification with no route → tap marks read only.
- **AC:**
  1. Renders the seeded notifications.
  2. At least one notification deep-links correctly (e.g. to SC-12).

---

## SC-21 — Pengaturan / Demo Mode  `P0`

- **Purpose:** house the **Reset Demo** control and any real toggles.
- **Primary action:** tap **Reset Demo**.
- **Required data:** current scenario name; app version; build flavor.
- **States:** idle; resetting (brief) → routes to Home.
- **Navigation:** in — SC-18. out — Home after reset.
- **Edge cases:** double-tap reset → guarded (ignore while resetting).
- **AC:**
  1. Reset restores seed state and returns to Home in < 5 s, offline.
  2. The screen is reachable in ≤ 3 taps from Home (Profil → Pengaturan →
     Reset).

---

## SC-22 — Onboarding (carousel)  `P1`

- **Purpose:** 3-slide intro to the pillars for first launch.
- **Primary action:** **Lanjut** / **Mulai**.
- **Required data:** static slide content + illustrations.
- **States:** static; "seen" flag persisted so it shows once.
- **Navigation:** in — SC-00 on first run. out — Home. Skippable.
- **Edge cases:** if skipped/seen, never blocks the demo; a demo reset may
  optionally re-show it (document the choice in `DEMO_SCRIPT.md`).
- **AC:**
  1. Can be skipped in one tap.
  2. Does not appear on subsequent launches unless demo is reset with the
     "show onboarding" option.

---

## Screens intentionally NOT in the MVP

- Login / Register / OTP / Forgot password.
- KYC / document upload.
- Real map or address picker.
- **Financing application submission / "Pengajuan Terkirim" / approval / status
  tracking** — removed from P0 (CR-2). Financing ends at SC-11 (result).
- Payment / disbursement / repayment screens.
- Roof financial projection (savings, payback/ROI, capacity calc) — removed from
  P0 (CR-13); `FUTURE_IMPLEMENTATION`.
- Solar Hub operator console; Arisan admin console.
- Settings detail screens beyond SC-19 and SC-21 (shown as "Segera hadir").
- Compose-message screen.
