# IbuDaya — Live Demo Script

> Target: **3–5 minutes**, one Android phone, airplane mode ON, Demo Mode.
> Goal: show the three pillars working as one system, end on impact.
> Persona: **Ibu Clara**. Rule: never improvise a tap that isn't in this script.

## 1. Pre-demo checklist (before you're on stage)

- [ ] Phone charged > 60%, brightness up, auto-lock 5+ minutes.
- [ ] **Airplane mode ON** (proves the offline claim).
- [ ] App installed from a release build (`flutter build apk --release`), not a
      debug USB run.
- [ ] Open the app, go to **Profil → Pengaturan → Reset Demo**, confirm.
- [ ] Land on Home showing: "Hi Ibu Clara", "Penghematan Bulan Ini Rp 245.000",
      "45% Energy Usaha dari Solar Hub", score tile "82/100", "Status Arisan:
      Lunas".
- [ ] Close any keyboard; scroll Home to top.
- [ ] Backup phone / screenshot deck ready.

## 2. One-line framing (before the first tap, ~15 s)

> "IbuDaya helps women-led micro-businesses in Indonesia cut electricity costs
> with a shared community solar hub, and turns their energy habits into a credit
> score so they can access small business financing. Everything here runs
> offline on this phone, and every AI estimate is labelled as a prototype
> estimate."

## 3. Scene-by-scene

### Scene 1 — Home (≈ 25 s)

- **Show:** the dashboard. Point at monthly saving, "45% from Solar Hub", the
  energy alert card ("Lonjakan Energi Produksi", "Alat Usaha Standby").
- **Say:** "Ibu Clara runs a home catering business. The app already sees her
  usage patterns and flags where money is leaking."
- **Tap:** quick action **Scan Tagihan**.

### Scene 2 — Scan bill → AI Energy Insight (≈ 35 s)

- **On Scan Tagihan:** **Tap "Ambil Foto Tagihan"** (or "Unggah dari Galeri").
  A short "menganalisis…" appears.
- **On Analisis Energi:** point at the spike window (18.00–21.00), "Biaya
  tambahan Rp 45.200/bln" (note the **"estimasi"** label), and the appliance
  list (note the **"ilustrasi"** label).
- **Say:** "The prototype reads her bill and attributes the spike to appliances,
  then tells her when to shift that load."
- **Tap:** **Lihat Jadwal Solar Hub**.

### Scene 3 — Solar Hub: preliminary roof assessment → booking (≈ 55 s)

- You arrive at **Solar Hub Booking** from the CTA. To also show the roof
  assessment: **tap the "Solar Hub" bottom tab**, then **"Scan Sekarang"**.
- **On "Radar Atap — Kelayakan Awal":** point at
  - **"Kelayakan Awal: Sangat Baik"**,
  - estimasi area potensial, orientasi atap, potensi paparan matahari,
  - and read out the **verification notice**: "this is an initial estimate and
    needs a technical check on site before installation."
- **Say:** "We don't claim a measured result and we don't put a savings number on
  screen yet — this is a first-pass suitability check. The point: individually
  solar is out of reach; as a group the hub becomes viable."
- **Tap:** **Lanjut ke Rekomendasi Solar Hub**.
- **On Solar Hub Booking:**
  - point at "Kapasitas Energi Hari Ini 86%",
  - **Tap the "Oven"** appliance,
  - note the recommended slot **10.00–12.00** and its weather reason,
  - **Tap the 10.00–12.00 slot**,
  - **Tap "Booking Sekarang"** → confirmation.
- **Say:** "She books the oven into the sunniest window; the schedule protects
  the shared battery."
- **Tap:** **Kembali ke Beranda**.

### Scene 4 — Energy Arisan + share energy quota (≈ 55 s)

- **On Home:** **Tap "Arisan" quick action**.
- **On Arisan Energi:** point at "Arisan Energi Melati", "Giliran Pemakaian
  Berikutnya", and the **Transaksi Terbaru** ledger ("recorded transparently").
- **Say:** "The traditional arisan, now a transparent ledger. Members can also
  share spare energy quota."
- **Tap:** **Perdagangan Energi**.
- **On Perdagangan Energi:** point at "Kuota Energi Saya" and the member offers
  list (Siti Rahma, Ibu Lina, Ibu Putri).
- **Tap:** **Bagikan Kuota**.
- **On Bagikan Kuota:** **Tap "2 kWh"**, **tap a time slot**, **tap
  "Publikasikan Penawaran"**.
- **On "Penawaran Berhasil Dipublikasikan":** note "Tercatat dengan Aman".
- **Tap:** **Kembali ke Perdagangan Energi** — point out "Kuota Energi Saya"
  dropped by 2 kWh and the new offer is listed.
- **Say:** "That share is now in the ledger. No blockchain, no real transfer —
  a transparent local record for the pilot."
- **Tap:** back to **Arisan Energi**, then **Skor Kredit Energi**.

### Scene 5 — Skor Kredit Energi (≈ 45 s)

- **On Skor Kredit Energi:** point at
  - the score **82 / 100 — "Baik Sekali"**,
  - the four rows: **Konsistensi pemakaian energi 30/35**, **Riwayat pembayaran
    24/30**, **Aktivitas usaha 18/20**, **Partisipasi komunitas 10/15**,
  - "Potensi Pembiayaan Anda" up to **Rp 2.000.000** (label **"simulasi"**).
- **Say:** "No bank history. The score is a transparent rule — four categories,
  they add up to 82, and every one is shown. In production this engine is
  replaced by a validated model behind the same screen."
- **Tap:** **Simulasi Pembiayaan**.

### Scene 6 — Simulasi Pembiayaan (≈ 35 s)

- **On "Simulasi Pembiayaan (input)":**
  - note the eligibility line **"Berdasarkan profil skor Anda"**,
  - leave the amount at the preset (Rp 2.000.000),
  - **Tap purpose "Membeli bahan produksi"**,
  - **Tap tenor "6 Bulan"**,
  - **Tap "Hitung Simulasi"**.
- **On "Hasil Simulasi Pembiayaan":** point at principal Rp 2.000.000, tenor
  6 bulan, flat rate 2%/bulan, estimated total cost **Rp 240.000**, total
  repayment **Rp 2.240.000**, monthly installment **≈ Rp 373.333**, and the
  **disclaimer**: "Ini simulasi, bukan penawaran resmi. IbuDaya tidak
  menyalurkan pinjaman."
- **Say:** "A right-sized simulation with a clear installment — flat 2% a month,
  a stated demo assumption. Nothing is submitted; in production this hands off to
  a licensed partner. IbuDaya never disburses funds."
- **Tap:** **Kembali ke Beranda**.

### Scene 7 — Impact / close (≈ 25 s)

- **Tap the "Profil" bottom tab.**
- **On Profil Saya (Ibu Clara):** point at **Dampak Saya**: 128 kWh used, 32 kWh
  shared, **96 kg CO₂ avoided**, 12 members — labelled "data komunitas".
- **Say:** "One member, illustrative numbers. Across a group, IbuDaya turns clean
  energy into income *and* creditworthiness for the women who run Indonesia's
  economy."

**Total:** ~4:35.

## 4. If something breaks (recovery)

| Problem | Recovery |
| --- | --- |
| A screen looks wrong / stale | Profil → Pengaturan → **Reset Demo**, resume from the current scene's entry on Home. |
| App crashes | Reopen from the launcher (state resets), go to Home, resume from the current scene. Do **not** re-run earlier scenes. |
| Tap does nothing | Wait 2 s (simulated latency), tap once more. Don't double-tap CTAs. |
| Camera dialog stalls (P1 path) | Dismiss it; the canned analysis still proceeds. Prefer "Unggah dari Galeri". |
| Quota share already published (demo re-run) | Reset Demo before starting, or narrate the existing offer instead of publishing again. |
| Totally stuck | Switch to the backup phone / screenshot deck and narrate. |

## 5. Do NOT do live

- Do not toggle airplane mode off.
- Do not open Settings rows other than "Reset Demo" / "Tentang IbuDaya".
- Do not try real OCR, real camera roof scanning, or language switching.
- Do not tap "Keluar Akun".
- Do not take a member's quota offer *and* publish your own in the same run
  unless you will Reset Demo afterward.
- Do not scroll into unfinished P2 areas.

## 6. Judge Q&A — honest answers

- **"Is the AI real?"** — "The credit score is a transparent rule-based engine
  over demo data — four categories that add up to the score, all shown. The bill
  analysis and roof assessment are scripted demo results. No trained model, no
  live API in this build."
- **"Where does the data come from?"** — "A bundled demo scenario. No backend, no
  network — that's why it runs in airplane mode."
- **"Is this a real lender?"** — "No. Financing is a simulation with a stated
  flat-2%-per-month demo assumption. Production would operate with a licensed
  partner; the research survey cites OJK Regulation No. 29/2024. IbuDaya does not
  disburse funds."
- **"Blockchain?"** — "The paper references it as future work. The app uses a
  plain transparent local ledger."
- **"Where do the savings / CO₂ numbers come from?"** — "Illustrative figures
  with documented placeholder factors, labelled as estimates in the UI."
- **"Which SDG?"** — "Primary is SDG 11 — Sustainable Cities and Communities.
  It also touches SDG 5, 7, and 8."
