# IbuDaya — User Flows

> Notation: `>` = navigation step, `?` = decision point, `!` = edge case.
> Every flow assumes **Demo Mode / offline**. `DEMO_SIMULATION` outputs are
> pre-scripted. Persona is **Ibu Clara** throughout.

## 0. Golden demo path (the one that must never break)

Rehearsed in `DEMO_SCRIPT.md`:

```
Splash / seed load
  > Home (Beranda)  — "Hi Ibu Clara"
    > Scan Tagihan  (tap "Ambil Foto Tagihan" / "Unggah dari Galeri")
      > Analisis Energi  (DEMO_SIMULATION spike + appliance attribution "ilustrasi")
        > (CTA) Lihat Jadwal Solar Hub
  > Solar Hub tab  ("Scan Sekarang")
      > Radar Atap — Kelayakan Awal  (DEMO_SIMULATION: assessment + verification notice)
        > (CTA) Lanjut ke Rekomendasi Solar Hub
          > Solar Hub Booking  (pick appliance > pick slot > Booking Sekarang)
            > Booking confirmation
  > Home > Arisan quick action
      > Arisan Energi  (group overview, rotation, append-only ledger)
        > (CTA) Perdagangan Energi
          > Bagikan Kuota  (pick 1/2/3 kWh > pick slot > preview > Publikasikan)
            > Penawaran Berhasil Dipublikasikan   ← P0-Lite, in the demo
  > Arisan Energi > Skor Kredit Energi
      > Skor Kredit Energi  (82/100, 4-category explanation)
        > (CTA) Simulasi Pembiayaan
          > Simulasi Pembiayaan (input)  (amount ≤ Rp 2.000.000 > purpose > tenor > Hitung Simulasi)
            > Hasil Simulasi Pembiayaan  (principal / tenor / flat rate / total cost / total repayment / monthly installment + disclaimer)
              ← ends here (no submission)
  > Profil  (Dampak Saya / impact metrics)
```

Target 3–5 minutes.

---

## 1. First launch / Demo Mode bootstrap

**Goal:** reach Home with seed data loaded, no network.

1. App starts on Splash.
2. App loads the bundled scenario (`assets/demo/scenario_happy_path.json`) into
   in-memory repositories.
3. `?` Seed load succeeds → route to Home.
4. `!` Seed asset missing/corrupt → full-screen error state with one "Coba lagi"
   button that re-runs the load.

`PROTOTYPE_DECISION`: no login. "Ibu Clara" is pre-signed-in; there is no auth
state.

---

## 2. Scan energy bill → energy insight

**Goal:** turn "my bill is high" into an explained, actionable insight.

**Entry:** Home > "Scan Tagihan" quick action.

1. Screen **Scan Tagihan Listrik**: guidance + two buttons.
2. `?` **Ambil Foto Tagihan**: P1 opens the camera (`image_picker`); the
   `DEMO_SIMULATION` fallback skips it and shows a ~1.2 s "menganalisis…" state.
3. `?` **Unggah dari Galeri**: same, with the gallery picker (P1) or the same
   fallback.
4. Short analysis loading state.
5. Screen **Analisis Energi** (`DEMO_SIMULATION` from the scenario):
   - spike window (e.g. 18.00–21.00);
   - added monthly cost (e.g. Rp 45.200) — qualifier "estimasi";
   - ranked "Alat penyumbang biaya" list — qualifier "ilustrasi";
   - "Insight Utama": one plain recommendation;
   - CTA **Lihat Jadwal Solar Hub** → Solar Hub Booking.
6. `!` Back during loading → return to Scan Tagihan, no state kept.
7. `!` Scenario has no insight → empty state "Belum ada analisis…" + scan CTA.

**Success end state:** on Analisis Energi, able to jump to Solar Hub.

---

## 3. Roof preliminary assessment → Solar Hub recommendation → booking

**Goal:** show a communal Solar Hub is worth it, then reserve a slot.
**No AI-accuracy %, confidence probability, or precise pitch is shown**
(decision #2).

**Entry:** bottom nav **Solar Hub** tab.

1. Screen **Scan Atap Solar Hub** — framed roof illustration/preview + "Scan
   Sekarang".
2. Tap **Scan Sekarang** → ~1.5 s "memindai atap…" state.
3. Screen **Radar Atap — Kelayakan Awal** (`DEMO_SIMULATION`):
   - headline **"Kelayakan Awal: Sangat Baik"**;
   - **Estimasi area potensial** (m², rounded);
   - **Orientasi atap** (e.g. "Menghadap timur–barat");
   - **Potensi paparan matahari** (qualitative, e.g. "Tinggi");
   - **mandatory notice**: "Ini estimasi awal. Perlu verifikasi teknis di lokasi
     sebelum pemasangan.";
   - "Tips IbuDaya" callout;
   - **No** rupiah savings, payback/ROI, or capacity calculation on this P0
     screen (CR-13) — those are `FUTURE_IMPLEMENTATION`;
   - CTA **Lanjut ke Rekomendasi Solar Hub** → Solar Hub Booking.
4. Screen **Solar Hub Booking**:
   - "Kapasitas Energi Hari Ini" gauge (`DEMO_SIMULATION` %, e.g. 86%);
   - Step 1 **Pilih Alat**: choose one (Oven / Mesin Jahit / Kulkas / Blender),
     each with a rough power draw;
   - Step 2 **Rekomendasi Booking**: a highlighted slot + a one-line canned
     weather rationale;
   - Step 3 **Pilih Waktu Booking**: choose one of 4 slots (08–10, 10–12, 13–15,
     15–17);
   - `?` recommended slot → proceed; non-recommended slot → allowed, gentle note;
   - CTA **Booking Sekarang**.
5. Booking confirmation (card/dialog): appliance + slot + "tercatat".
6. `P1`: booking appears on Home under "Jadwal AI Hari Ini".
7. `!` No appliance selected on "Booking Sekarang" → CTA disabled / inline
   validation.
8. `!` Slot `full` in the scenario → disabled with a "penuh" tag.

**Success end state:** a booking exists for Ibu Clara for today.

---

## 4. View Energy Arisan (group, rotation, ledger)

**Goal:** show the digital Arisan as a transparent, living record.

**Entry:** Home > "Arisan" quick action (or the Home Arisan status card).

1. Screen **Arisan Energi** — "Arisan Energi Melati".
   - "Ringkasan Saya": contribution status, next payout, turn position.
   - Rotation: **Giliran Pemakaian Berikutnya** + a month calendar strip.
   - "Transaksi Terbaru": append-only ledger list (date, member, type, amount,
     status, ref id) — copy "tercatat transparan", **no "blockchain"**.
   - CTAs: **Perdagangan Energi** (P0-Lite), **Skor Kredit Energi**.
2. `?` Tap a ledger row → read-only row detail (who, what, when, reference id).
3. `!` Empty ledger → empty state "Belum ada transaksi arisan."

**Success end state:** user can reach quota sharing and the credit score.

---

## 5. Energy-quota sharing — share quota  `P0-Lite`

**Goal:** publish spare kWh for other members. Kept deliberately simple
(decision #3): amount, slot, note, preview, publish. No bidding / negotiation /
filters / real-time.

**Entry:** Arisan Energi > **Perdagangan Energi** > "Saya ingin berbagi kuota" >
**Bagikan Kuota**.

1. Screen **Perdagangan Energi**: "Kuota Energi Saya" (available kWh), my turn
   slot, my published offers, "Penawaran dari Anggota" list.
2. Screen **Bagikan Kuota** (stepped form):
   - Step 2 — amount: **1 / 2 / 3 kWh** chips, capped at available;
   - Step 3 — pick one time slot;
   - Step 4 — optional note (≤ 140 chars);
   - Step 5 — **Pratinjau Penawaran** (read-back);
   - CTA **Publikasikan Penawaran**.
3. `?` Amount chip > available → disabled with a reason.
4. On publish → append a `QuotaOffer` (status `open`) **and** a `LedgerEntry`
   (`quotaShared`, `pending`); decrease `EnergyQuota.availableKwh`.
5. Screen **Penawaran Berhasil Dipublikasikan** — summary, "Tercatat dengan
   Aman", **Kembali ke Perdagangan Energi**.
6. Back on Perdagangan Energi, the new offer shows under "Kuota yang dibagikan"
   and "Kuota Energi Saya" reflects the reduced amount — **without reload**.
7. `!` Cancel mid-form → confirm discard → Perdagangan Energi.

---

## 6. Energy-quota sharing — request / take an available quota  `P0-Lite`

**Goal:** take kWh from a member's offer.

**Entry:** Perdagangan Energi > "Penawaran dari Anggota" > a member row (e.g.
Siti Rahma – 5 kWh) > **Minta**.

1. Bottom sheet / screen **Minta Kuota**: confirm the amount + slot from that
   offer, optional note.
2. CTA **Kirim Permintaan** → append a `QuotaRequest` + a `LedgerEntry`
   (`quotaReceived`, `pending`); offer status → `taken`; if the current user is
   the requester, decrease `EnergyQuota.neededKwh`.
3. Confirmation card/sheet; back to Perdagangan Energi with the offer row now
   marked "sudah diambil".
4. `P1`: a demo notification "Permintaan kuota terkirim" is added.
5. `!` Offer already `taken` in the scenario → row disabled "sudah diambil".

---

## 7. View credit score → understand it

**Goal:** the user sees a number **and** the four categories behind it.

**Entry:** Home score tile, or Arisan Energi > **Skor Kredit Energi**.

1. Screen **Skor Kredit Energi**:
   - Score gauge (0–100) + band; canonical demo value **82 — "Baik Sekali"**.
   - **Rincian Skor** — one row per category, each with points / max, direction,
     and a plain reason (generated by `DemoCreditScoringEngine`):
     - Konsistensi pemakaian energi — **30 / 35**
     - Riwayat pembayaran — **24 / 30**
     - Aktivitas usaha — **18 / 20**
     - Partisipasi komunitas — **10 / 15**
   - "Potensi Pembiayaan Anda": **Rp 2.000.000** (qualifier "simulasi").
   - CTA **Simulasi Pembiayaan** → financing simulation.
2. `?` Tap a category row → expandable detail: what it measures, how to improve
   (P1; the one-line reason is enough otherwise).
3. `!` Inputs partial in the scenario → show the score with a "data contoh"
   banner; never a blank score.

**Success end state:** user can name at least two categories that shaped the
score, then proceeds.

---

## 8. Simulasi Pembiayaan (financing simulation — calculation only)

**Goal:** calculate a financing simulation and show the result. **No application
is submitted.** Not approval, underwriting, disbursement, or a regulated product
(decision #6 / CR-2).

**Entry:** Skor Kredit Energi > **Simulasi Pembiayaan**, or Home > "Pembiayaan"
quick action.

1. Screen **Simulasi Pembiayaan (input)**:
   - Header shows the credit score (read-only) with the line **"Berdasarkan
     profil skor Anda"** (never "Direkomendasikan oleh AI").
   - Step 1 — **Nominal**: slider, **max Rp 2.000.000**.
   - Step 2 — **Tujuan Usaha**: one of beli bahan produksi / beli alat produksi /
     renovasi tempat usaha / lainnya.
   - Step 3 — **Tenor**: 3 / 6 / 12 bulan.
   - CTA **Hitung Simulasi**.
2. `?` Amount clamped to Rp 2.000.000; helper text explains the cap.
3. `?` Score below `eligibleScoreThreshold` (65) → the header line becomes "Perlu
   peninjauan manual"; the calculation still runs. (Happy-path score is 82.)
4. On **Hitung Simulasi** → compute a `LoanSimulation` (flat 2%/month,
   `DATA_MODEL.md §4.3`) → navigate to the result. Nothing is submitted or
   persisted.
5. Screen **Hasil Simulasi Pembiayaan** shows: principal, tenor, simulated flat
   rate (2%/bulan), estimated total cost, estimated total repayment, estimated
   monthly installment, and the **visible disclaimer**: "Ini simulasi, bukan
   penawaran resmi. IbuDaya tidak menyalurkan pinjaman."
   - Primary CTA **Kembali ke Beranda**; optional **Ulangi Simulasi** → step 1.
   - `PROTOTYPE_DECISION`: a secondary CTA, if kept, may only read **"Saya
     Tertarik"** and must state that partner financing integration is
     `FUTURE_IMPLEMENTATION` — it performs no submission. Preferred P0: omit it.
6. `!` Back from the input screen → return to Skor Kredit Energi (values may be
   kept for the session).

**Success end state:** the simulation result is on screen; the flow ends. There
is no "Pengajuan Terkirim".

---

## 9. View impact / profile

**Goal:** close the demo on measurable impact.

**Entry:** bottom nav **Profil**.

1. Screen **Profil Saya** (persona **Ibu Clara**):
   - Identity card: name "Ibu Clara", role "Anggota IbuDaya", phone, city, join
     date, member id.
   - "Dampak Saya": energy used (kWh), energy shared (kWh), CO₂ avoided (kg),
     group size — `DEMO_SIMULATION`, qualifier "data komunitas".
   - "Akun & Pengaturan": Informasi Pribadi, Keamanan, Notifikasi, Bahasa,
     Bantuan & Dukungan, **Tentang IbuDaya**.
   - "Keluar Akun" → confirm dialog → no-op or Splash.
2. `?` "Tentang IbuDaya" → static screen: team (Baswara Musi), **SDG 11**
   (primary; SDG 5/7/8 as related areas), one-paragraph summary, three pillars,
   and the honesty disclosure (AI outputs shown are prototype estimates /
   simulations).
3. `?` "Notifikasi" → notifications list / toggles (P1).
4. `?` Other settings rows → hidden or a "Segera hadir" stub. "Reset Demo" lives
   here or on a dedicated Pengaturan screen (`SC-21`).
5. `!` "Bahasa" is display-only (Indonesian).

**Success end state:** the impact numbers are on screen for the closing line.

---

## 10. Messages  `P1`

**Entry:** bottom nav **Pesan**.

1. Screen **Pesan** — search, filter chips (Semua / Belum Dibaca / Grup), thread
   list (Arisan group, Solar Hub admin, member DMs incl. "Siti Rahma", "Tips
   IbuDaya").
2. `?` Tap a thread → read-only thread view.
3. Compose FAB hidden or disabled (no send in MVP).
4. `!` Empty filter result → "Tidak ada pesan."

---

## 11. Demo reset

**Goal:** return to a known state between demo runs.

**Entry:** Profil > Pengaturan > **Reset Demo** (the exact control is documented
in `DEMO_SCRIPT.md`).

1. Confirm dialog: "Kembalikan data demo ke kondisi awal?"
2. On confirm → discard in-session mutations, re-parse the seed asset, route to
   Home.
3. Completes in < 5 s, no network.

---

## Cross-cutting behaviours

- **Back navigation** never leaves the app mid-flow without a confirm on
  multi-step forms (flows 5, 8).
- **Offline is the only mode** — no "you are offline" banners.
- **Every `DEMO_SIMULATION` number** carries a short qualifier ("estimasi",
  "simulasi", "ilustrasi", "data contoh"); financing also shows its disclaimer.
- **No "blockchain"/"on-chain" wording** anywhere.
- **No dead ends** — every terminal screen has a CTA back to Home or the previous
  hub.
