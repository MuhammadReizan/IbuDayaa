# IbuDaya — Assumptions, Risks, and Consistency Review

> Updated after the team's final product decisions. Consistency items (CR-xx) now
> carry a **status**.

## 0. Honesty hierarchy (decision #10)

Every capability, field, and figure in the product is exactly one of:

| Label | Meaning |
| --- | --- |
| `IMPLEMENTED` | Real, deterministic logic that runs in the app (e.g. the credit-scoring engine math, the loan formula, form validation, the local ledger). |
| `DEMO_SIMULATION` | A value produced for the demo with no real model / measurement / network behind it (bill insight, roof assessment, capacity %, impact figures). Must be visibly labelled in the UI. |
| `PROTOTYPE_DECISION` | A deliberate MVP scope or shape choice. |
| `ASSUMPTION` | A gap-fill the team should confirm; not stated in the PDF. |
| `FUTURE_IMPLEMENTATION` | Shown or implied by the UI/PDF but explicitly not built for the MVP. |

**No `DEMO_SIMULATION` capability may be presented as a production capability.**

---

## 1. Assumptions

| # | Assumption | Status |
| --- | --- | --- |
| AS-01 | Primary persona is an urban-fringe home-based food/craft MSME owner, WhatsApp-literate, arisan member. | Open (persona detail) — name resolved (Ibu Clara). |
| AS-02 | The demo represents **one** Arisan group ("Arisan Energi Melati", 12 members), single-tenant. | Confirmed for MVP. |
| AS-03 | The user is pre-signed-in; no auth in the MVP. | Confirmed for MVP. |
| AS-04 | Indonesian (`id`) is the only locale for the MVP. | Confirmed. |
| AS-05 | "Energy quota" = a kWh allowance tied to a member's rotation slot at the communal hub (not grid electricity). | Open — confirm the operational definition before a pilot (Epic F). |
| AS-06 | Credit-score inputs the app can plausibly obtain: energy-usage consistency, payment history, business activity, community participation. | Confirmed as the four scoring categories (decision #7). |
| AS-07 | Demo financing is small (**cap Rp 2.000.000**) and short tenor (**3 / 6 / 12 months**). | Confirmed (decision #6). |
| AS-08 | CO₂ figure uses a single grid emission-factor constant. | Open — set the constant value (`DATA_MODEL.md §4.4`). |
| AS-09 | App id `com.baswaramusi.ibudaya`, display name "IbuDaya". | **Confirmed** (decision #5). |
| AS-10 | Target devices: Android phones, portrait, 360 dp+ width, Flutter 3.32 / Dart 3.8. | Open — confirm min Android API. |
| AS-11 | Simulated latency (150–1200 ms) on scan/analyse screens is acceptable for demo realism. | Confirmed for MVP. |
| AS-12 | **No authoritative Figma exists.** Screenshots are the provisional visual source; all inferred tokens are `PROTOTYPE_DECISION` and centralised for later replacement. | **Confirmed** (decision #4). |
| AS-13 | **DEMO ASSUMPTION:** flat simulated financing rate = **2% per month**, applied as `principal × rate × months`. | **Confirmed** (decision #6); must be labelled a simulation assumption in the data model and UI. |
| AS-14 | Canonical credit inputs are tuned so `DemoCreditScoringEngine` returns exactly **82** (categories 30 / 24 / 18 / 10). | **Confirmed** (decision #7). |

---

## 2. Prototype decisions

| # | Decision | Notes |
| --- | --- | --- |
| PD-01 | **Offline-only demo build.** All data from `assets/demo/scenario_happy_path.json`. No `http`/`dio` wired. | |
| PD-02 | **One demo scenario** ("happy path"). `generatedAt` fixes "today". | |
| PD-03 | **Bill scan → canned `EnergyInsight`.** No OCR. Capture/upload UI real (P1). Appliance breakdown labelled "ilustrasi". | `DEMO_SIMULATION` |
| PD-04 | **Roof scan → preliminary assessment** ("Kelayakan Awal: Sangat Baik") with estimated potential area, roof orientation, sun-exposure potential, and a **mandatory technical-verification notice**. **No** savings figure, payback/ROI, or capacity calculation on the P0 screen (CR-13 / final correction 3). | `DEMO_SIMULATION` |
| PD-05 | **No AI-accuracy %, no confidence probability, no precise pitch (°)** anywhere in the roof feature. The screenshot's "Akurasi AI 92%" and "Kemiringan Atap 28°" are removed. | decision #2 |
| PD-06 | **Credit score = `DemoCreditScoringEngine`** — explainable, rule-based, deterministic, behind a `CreditScoringEngine` interface. Fixed rubric: Energy usage /35, Payment history /30, Business activity /20, Community participation /15. | decision #7. `IMPLEMENTED` |
| PD-07 | **Score UI shows the four categories as the entire explanation** (points / max + reason); the categories sum to the score with no hidden term. The screenshot's "+25/+38/+27" factor list is replaced. | decision #7 |
| PD-08 | **Financing is a calculation only — no submission (final correction 2 / CR-2).** P0 flow: Skor Kredit Energi → Simulasi Pembiayaan → amount → business purpose → tenor → **Hitung Simulasi** → **Hasil Simulasi Pembiayaan** (ends here). Formula: `total_cost = principal × 0.02 × months`; `total_repayment = principal + total_cost`; `monthly_installment = total_repayment / months` (rounded for display). Cap **Rp 2.000.000**; tenors 3/6/12. Result shows principal, tenor, simulated flat rate, estimated total cost, estimated total repayment, estimated monthly installment + visible disclaimer. **No** "Ajukan" / "Kirim Pengajuan" / "Pengajuan Terkirim" / "Pinjaman Disetujui". Eligibility "Berdasarkan profil skor Anda" (never "Direkomendasikan oleh AI"). Optional secondary CTA may only be "Saya Tertarik" (`FUTURE_IMPLEMENTATION` note, no submission); preferred P0 omits it. | decision #6. Formula `IMPLEMENTED`; rate is `AS-13`; `LoanApplication` is `FUTURE_IMPLEMENTATION` |
| PD-09 | **Energy Arisan ledger = plain append-only local list.** UI: "tercatat transparan". **No blockchain**, no on-chain wording. | decision #8. `IMPLEMENTED` (local) |
| PD-10 | **Quota sharing is P0-Lite and in the demo:** overview, my available quota, member offers, share (1/2/3 kWh + slot + note + preview + publish), take an offer, confirmation, ledger append, quota update. Nothing more. | decision #3 |
| PD-11 | **No real energy transfer or money movement** anywhere. | decision #6 |
| PD-12 | **Solar Hub camera preview** may be a static framed illustration; live camera is P1. | |
| PD-13 | **Canonical persona = "Ibu Clara"** on Home, Credit Score, Profile, Impact. "Siti Rahma" only as an `ArisanMember` / message contact. | decision #1 |
| PD-14 | **Bottom nav = 4 tabs** (Beranda / Solar Hub / Pesan / Profil). Arisan, Credit Score, Financing reached via always-visible Home entry points + cross-links. | |
| PD-15 | **Light theme only.** No dark mode. | |
| PD-16 | **No persistence.** App kill == reset. An explicit "Reset Demo" also exists. | |
| PD-17 | **SDG 11 is the primary classification.** SDG 5 / 7 / 8 mentioned only as related impact areas. | decision #9 |
| PD-18 | **Honesty-label vocabulary is applied in-app** via qualifier pills and the "Tentang IbuDaya" disclosure. | decision #10 |

---

## 3. Future implementation (shown/implied, not built)

| # | Item | Where it appears | Epic |
| --- | --- | --- | --- |
| FI-01 | Real OCR bill parsing | SC-02/03, PDF | A |
| FI-02 | Appliance-level load disaggregation | SC-03 "Alat Penyumbang Biaya" | B |
| FI-03 | BMKG weather API + ML load scheduling | PDF, SC-06 recommendation | C |
| FI-04 | Roof measurement / CV pipeline + any real measurement or accuracy metric | SC-05 | D |
| FI-05 | Trained/validated credit model + licensed lending partner + disbursement/repayment | SC-09, SC-10, PDF (OJK Reg. 29/2024) | E |
| FI-06 | Real P2P energy settlement; blockchain ledger if a pilot needs it | SC-12–15, PDF | F |
| FI-07 | Accounts / auth / KYC / group admin roles | any real use | G |
| FI-08 | Backend + sync + offline outbox; local DB replacing the in-memory store | all repositories | H |
| FI-09 | Real messaging + push notifications | SC-16/17/20, Profil toggle | I, J |
| FI-10 | Regional-language + voice support for low-literacy users | PDF "Literacy Gap" | K, L |
| FI-11 | Solar hardware, metering, battery telemetry, maintenance workflow | PDF | (out of app scope) |
| FI-12 | Impact measurement / pilot instrumentation | PDF impact claims | M |

---

## 4. Consistency review — PDF vs prototype vs proposed MVP

### 4.1 Items from the first review — resolution status

| ID | Finding (short) | Status after decisions |
| --- | --- | --- |
| CR-01 | User identity conflict (Ibu Clara vs Siti Rahma). | **RESOLVED** — decision #1 / PD-13. Canonical "Ibu Clara" everywhere; "Siti Rahma" is a community member only. Applied in `DATA_MODEL §3.2`, `SCREEN_INVENTORY SC-18`, `USER_FLOWS`, `DEMO_SCRIPT`. |
| CR-02 | Fabricated "Akurasi AI 92%" model-accuracy metric. | **RESOLVED** — decision #2 / PD-04, PD-05. Removed entirely; **no** replacement percentage or confidence probability. Roof screen shows "Kelayakan Awal" + verification notice. |
| CR-03 | Blockchain (PDF research survey) vs plain ledger (screens). | **RESOLVED** — decision #8 / PD-09. MVP = append-only local list; blockchain is `FUTURE_IMPLEMENTATION`; no on-chain wording in UI. |
| CR-04 | SDG 11 (title) vs SDG 7 (a reference). | **RESOLVED** — decision #9 / PD-17. SDG 11 primary; SDG 5/7/8 as related areas only. |
| CR-05 | Appliance naming ("Freezer" / "Kulkas" / "Kubas"). | **RESOLVED** — standardise the catalog to **"Kulkas"** (`DATA_MODEL §3.5`); "Kubas" was a typo. |
| CR-06 | Bottom nav has no Arisan / Score / Financing entry. | **RESOLVED** — PD-14: 4 tabs kept; Home has always-visible entry points and Arisan→Score→Financing cross-links (`USER_FLOWS`, `SCREEN_INVENTORY`). |
| CR-07 | Currency-format inconsistency ("Rp45.000", "hingga ke 2.000.000"). | **RESOLVED** — one formatter, `Rp 2.000.000` style (`DESIGN_SYSTEM §9`); copy typos fixed. |
| CR-08 | Screenshot factor deltas (+25/+38/+27) don't map to 82. | **SUPERSEDED** by decision #7 — see CR-15. |
| CR-09 | "Direkomendasikan oleh AI" implies automated underwriting. | **RESOLVED** — decision #6 / PD-08. Reframed to "Berdasarkan profil skor Anda"; shown when `score ≥ 65`. |
| CR-10 | Savings figures (Rp 245.000 / 280.000 / 45.200) not derived. | **RESOLVED** — seeded `DEMO_SIMULATION` values chosen for a coherent story, each with a visible qualifier; documented in the scenario file. |
| CR-11 | Energy Arisan scope creep risk. | **RESOLVED** — decision #3 / PD-10. Explicit P0-Lite subset in `MVP_SCOPE §Pillar 3`; advanced trading is P1/P2. |
| CR-12 | OJK Reg. 29/2024 cited as fact. | **RESOLVED** — repeated in-app only in "Tentang IbuDaya" as a cited research finding; legal review deferred to Epic E. |

### 4.2 New items surfaced by the decisions

| ID | Finding | Severity | Resolution |
| --- | --- | --- | --- |
| CR-13 | Roof screen showed projected monthly saving + payback, which are financial projections, not a preliminary roof assessment. | Low | **RESOLVED** — final correction 3. **Removed from P0.** The P0 roof screen shows only: Kelayakan Awal, estimated potential area, roof orientation, sun-exposure potential, technical-verification notice. Savings / payback / ROI / capacity calc are `FUTURE_IMPLEMENTATION` (`DATA_MODEL §3.6`, `MVP_SCOPE S03 → P2`, `BACKLOG` Epic D). |
| CR-14 | `monthly_installment = total_repayment / months` produces non-round rupiah (e.g. 3-month ≈ Rp 706.667), whereas the screenshot shows "Rp 706.000". | Low | **RESOLVED.** The formula (decision #6) is authoritative; screenshots are provisional. Display rounds to the nearest rupiah. Unit tests assert the computed values in `DATA_MODEL §4.3`, not the screenshot value. |
| CR-15 | The screenshot's credit "factors" list (+25/+38/+27, three items) does not match the fixed four-category rubric (30/24/18/10). | Low | **RESOLVED.** The four-category breakdown replaces the screenshot's factor list (PD-07). This supersedes CR-08. |
| CR-16 | A screen titled "AI Credit Score" while the engine is explicitly rule-based. | Low–Medium | **RESOLVED** — final correction 1. The screen is renamed **"Skor Kredit Energi"** everywhere user-facing (`SCREEN_INVENTORY SC-09`, `USER_FLOWS`, `DEMO_SCRIPT`; route `/credit-score`). `DemoCreditScoringEngine` is never described as trained AI/ML. "AI" / "alternative credit scoring" remains valid in roadmap/research context only. |
| CR-17 | Home quick action labelled "Pinjaman" (loan) conflicts with "Simulasi Pembiayaan". | Low | **RESOLVED.** Rename the Home quick action to **"Pembiayaan"** (or "Simulasi"); it routes to SC-10. |
| CR-18 | "Radar Atap AI" as a feature name still contains "AI". | Low | **RESOLVED** — screen heading is **"Radar Atap — Kelayakan Awal"** in `SCREEN_INVENTORY`/`USER_FLOWS`/`DEMO_SCRIPT`; the short name "Radar Atap" is fine without "AI". |
| CR-2 | Golden path still contained a financing **submission** flow (Ajukan Pembiayaan Usaha → Kirim Pengajuan → Pengajuan Terkirim). | Medium | **RESOLVED** — final correction 2. Submission removed from P0. Financing is calculation-only, ending at **Hasil Simulasi Pembiayaan** (SC-11). `LoanApplication` and all approval/status/disbursement screens are `FUTURE_IMPLEMENTATION`. |

### 4.3 Consistent & supported (no action needed)

- Three pillars (Communal Solar Hub, Alternative Credit Scoring, Energy Arisan)
  match PDF, screenshots, and MVP scope.
- Productive appliances (electric oven, sewing machine, refrigerator, blender)
  match PDF and screenshots.
- Target user (unbanked women-led MSMEs, Indonesia) is consistent.
- Green visual identity is consistent across all screenshots.
- Offline/demo requirement aligns with `CLAUDE.md` and is architecturally
  supported.
- Explainable scoring (category breakdown) matches PDF intent and `CLAUDE.md`.

### 4.4 Unsupported claims in the current UI — MVP handling (updated)

| Claim in the screenshots | MVP handling |
| --- | --- |
| "Akurasi AI 92%" | **Removed.** No accuracy %, no confidence probability. |
| "Kemiringan Atap 28°" (precise pitch) | **Removed.** Replaced by qualitative roof-orientation label. |
| Appliance-level rupiah breakdown from a bill photo | Kept visually, labelled "ilustrasi"; disclosed in Q&A. `FUTURE_IMPLEMENTATION`. |
| Roof area (m²) | Shown as "estimasi area potensial" (rounded, no decimals). `DEMO_SIMULATION`. |
| "Rp 280.000/bulan" saving, "3,2 tahun" payback | **Removed from P0** (CR-13). Not shown on the roof screen; `FUTURE_IMPLEMENTATION`. |
| "Potensi Pembiayaan … Rp 2.000.000" | Labelled "simulasi"; equals the SC-10 cap. |
| "Direkomendasikan oleh AI" | Replaced by "Berdasarkan profil skor Anda". |
| Monthly installment "Rp 706.000" | Computed via the decision-#6 formula; display rounded (3-month ≈ Rp 706.667). |
| "96 kg CO₂", "128 kWh", "32 kWh" | Seeded `DEMO_SIMULATION`, labelled "data komunitas". |
| "Tercatat dengan Aman" / transparency | Kept; **no "blockchain"** wording; no real transfer. |
| Screen titles "AI Credit Score" / "Radar Atap AI" | **Renamed** → "Skor Kredit Energi" / "Radar Atap — Kelayakan Awal" (CR-16, CR-18). |

---

## 5. Risks

### 5.1 Demo / competition risks

| ID | Risk | L | I | Mitigation |
| --- | --- | --- | --- | --- |
| RD-01 | App crash / glitch mid-demo | Med | High | Release build; `runZonedGuarded` → ErrorScreen; `DEMO_SCRIPT §4`; backup phone/screenshots. |
| RD-02 | Judge probes "is the AI real?" and the answer sounds evasive | Med | High | Rehearse `DEMO_SCRIPT §6`; every `DEMO_SIMULATION` labelled on-screen; score/roof screens already renamed away from "AI" (CR-16/18). |
| RD-03 | Over 5 minutes | Med | Med | Scene timings; Scene 4's quota share is a single 2-kWh publish, not a full exploration. |
| RD-04 | RenderFlex overflow on the presenter's device width | Med | Med | Test at 360/412 dp; scrollable bodies; `Expanded` discipline in review. |
| RD-05 | Stale state from a previous run (esp. a published quota offer) | Med | Med | "Reset Demo" in the pre-demo checklist; app-kill also resets. |
| RD-06 | System dialog (camera perm, update) appears | Low | Med | Airplane mode; prefer "Unggah dari Galeri"; disable the P1 camera path if flaky. |
| RD-07 | Non-round installment figure looks like a bug | Low | Low | Show it as "≈ Rp 373.333" with the formula visible; it is correct (CR-14). |

### 5.2 Product / adoption risks (from the PDF)

| ID | Risk | Mitigation direction (post-MVP) |
| --- | --- | --- |
| RP-01 | High CAPEX for solar hardware | Communal model + financing partner; grant/CSR funding for the first hubs. |
| RP-02 | Digital-literacy gap | Epic K (onboarding, voice, buddy mode); large targets + plain language in the design system. |
| RP-03 | Maintenance needs local technical training | Operator training program; operator console (Epic N). |
| RP-04 | Regulatory limits on P2P energy trading | Local-hub model per the PDF; legal review before any real trading (Epic F). |
| RP-05 | Alternative credit scoring fairness / bias | Keep it explainable; back-test; human-review path ("Perlu peninjauan manual"); model card (Epic E). |
| RP-06 | Data privacy (energy + business data → credit) | Consent, data-use disclosures, minimisation; no PII in the demo at all. |

### 5.3 Technical risks (MVP)

| ID | Risk | Mitigation |
| --- | --- | --- |
| RT-01 | P0-Lite quota sharing quietly grows into a marketplace | Hard scope list in `MVP_SCOPE §Pillar 3` (A05–A08 only); everything else is A09/A10 = P1/P2. |
| RT-02 | Over-engineering the architecture | `ARCHITECTURE §11` non-goals; services + repos only; no codegen initially. |
| RT-03 | Design tokens not actually centralised → inconsistent UI | Review rule: no inline hex / `EdgeInsets` literals; component library first; all tokens `PROTOTYPE_DECISION`. |
| RT-04 | Score/loan math wrong or unexplainable | Pure services with unit tests (P0): Ibu Clara = 82; the three loan-tenor rows. |
| RT-05 | Accidental network dependency in the demo flavor | CI check: demo flavor dependency graph must not contain `http`/`dio`. |
| RT-06 | Localisation strings scattered | Centralised `AppStrings`/ARB from day one (P0). |
| RT-07 | "AI" wording creeps back into score/roof screens | Screens renamed (CR-16/18); `SCREEN_INVENTORY` AC forbids "AI/ML" on the score screen; review checklist item. |

---

## 6. Blockers before Flutter implementation

**None. Planning documents are FROZEN for MVP implementation** (final corrections
1–3 applied). No further product-scope changes unless a technical blocker
requires discussion.

Remaining items are **asset/polish confirmations**, not blockers — filled in
during implementation:

1. Final licensed illustrations; exact brand colour hex; the font file.
2. Grid CO₂ emission-factor constant (`DATA_MODEL §4.4`).
3. Min Android API level (`AS-10`).
4. Exact "Reset Demo" control placement (`DEMO_SCRIPT`).
