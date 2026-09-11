> **DOKUMEN V1 — sudah digantikan.** Redesign v2 (role anggota/admin, pinjaman ditinjau admin koperasi, scan OCR, lokal lalu Supabase) dijelaskan di `CLAUDE.md`, `docs/SCREENS.md`, dan `docs/SUPABASE.md`. Isi di bawah hanya untuk riwayat.

# IbuDaya — Data Model

> Local-first. Every entity below lives in memory during a demo session, seeded
> from JSON assets under `assets/demo/`. No database, no network, no PII beyond
> the fictional demo persona.
>
> Types use Dart conventions. `?` = nullable. All models are **immutable**
> (`const` constructors, `copyWith`). Money is stored as integer **rupiah**
> (no cents). Energy is `double` **kWh**. Timestamps are `DateTime` (local).

## 0. Honesty labels used in this document

Per final product decision #10. Applied to fields and formulas below.

| Label | Meaning in the data model |
| --- | --- |
| `IMPLEMENTED` | Real, deterministic logic that runs in the app (e.g. the scoring engine math, the loan formula). |
| `DEMO_SIMULATION` | A value produced for the demo with no real model/measurement behind it (e.g. roof area, projected savings). Must be visibly labelled in the UI. |
| `PROTOTYPE_DECISION` | A deliberate MVP scope/shape choice. |
| `ASSUMPTION` | A gap-fill the team should confirm. |
| `FUTURE_IMPLEMENTATION` | Field/flow shape reserved for a real implementation later; not active in the MVP. |

## 1. Entity overview

```
DemoScenario ──1:1── UserProfile            (persona: "Ibu Clara")
             ├──1:1── ImpactMetrics
             ├──1:1── EnergyInsight          (result of a bill scan — DEMO_SIMULATION)
             ├──1:1── RoofScanResult         (preliminary assessment — DEMO_SIMULATION)
             ├──1:1── SolarDay ──1:N── SolarSlot
             │                └──1:N── Appliance (catalog)
             ├──0:N── SolarBooking
             ├──1:1── ArisanGroup ──1:N── ArisanMember
             │                     ├──1:N── RotationSlot
             │                     └──1:N── LedgerEntry   (append-only)
             ├──1:1── EnergyQuota
             ├──0:N── QuotaOffer
             ├──0:N── QuotaRequest
             ├──1:1── CreditScoreInputs ──▶ CreditScore ──1:N── CreditFactor   (IMPLEMENTED engine)
             ├──1:1── LoanParams ──▶ LoanSimulation   (IMPLEMENTED formula; transient, not persisted)
             ├──0:N── MessageThread ──1:N── Message
             └──0:N── AppNotification
```

## 2. Enums

```dart
enum DemoScenarioId { happyPath }                       // MVP ships one

enum AlertSeverity { info, warning, critical }

enum ApplianceKind { oven, sewingMachine, refrigerator, blender, other }

enum SlotAvailability { open, full, booked }            // 'booked' = by demo user

enum RoofSuitability { sangatBaik, baik, cukup, kurang } // rendered as "Kelayakan Awal: <label>"

enum ArisanContributionStatus { lunas, belumLunas, terlambat }

enum LedgerEntryType { contribution, payout, quotaShared, quotaReceived, adjustment }

enum LedgerEntryStatus { pending, settled }

enum QuotaOfferStatus { open, taken, cancelled, expired }

enum QuotaRequestStatus { sent, accepted, declined }

enum CreditCategory { energyUsage, paymentHistory, businessActivity, communityParticipation }

enum CreditBand { perluPeningkatan, cukup, baik, baikSekali } // <50 / 50-64 / 65-79 / 80-100

enum FactorDirection { positive, negative, neutral }

enum LoanPurpose { bahanProduksi, alatProduksi, renovasiTempat, lainnya }

enum LoanTenorMonths { m3, m6, m12 }

enum LoanEligibility { eligible, needsReview }          // UI copy: "Berdasarkan profil skor Anda" / "Perlu peninjauan manual"

enum MessageThreadKind { group, admin, member, system }

enum NotificationKind { quotaRequest, bookingReminder, paymentReminder, scoreUpdate, tips }
```

## 3. Entities

### 3.1 DemoScenario

Root object loaded at bootstrap; wraps every other seed.

| Field | Type | Notes |
| --- | --- | --- |
| id | `DemoScenarioId` | `happyPath` in MVP |
| label | `String` | "Skenario Demo — Ibu Clara" |
| generatedAt | `DateTime` | fixed date so "today" is deterministic |
| user | `UserProfile` | persona "Ibu Clara" |
| impact | `ImpactMetrics` | |
| energyInsight | `EnergyInsight?` | null → SC-03 empty state |
| roofScan | `RoofScanResult` | |
| solarDay | `SolarDay` | |
| bookings | `List<SolarBooking>` | seeded empty; grows during demo |
| arisan | `ArisanGroup` | |
| quota | `EnergyQuota` | |
| offers | `List<QuotaOffer>` | member offers + user's own |
| requests | `List<QuotaRequest>` | grows during demo |
| creditInputs | `CreditScoreInputs` | raw inputs, see §3.11 |
| loanParams | `LoanParams` | drives the simulation; the result is transient, not stored |
| threads | `List<MessageThread>` | P1 |
| notifications | `List<AppNotification>` | P1 |

### 3.2 UserProfile

`PROTOTYPE_DECISION` — canonical persona is **Ibu Clara** everywhere in the app.
"Siti Rahma" appears only as a separate `ArisanMember` (community member), never
as the signed-in user.

| Field | Type | Notes |
| --- | --- | --- |
| id | `String` | member id, e.g. `"IDB-2404-1287"` |
| displayName | `String` | **`"Ibu Clara"`** — used on Profile, Credit Score, everywhere |
| greetingName | `String` | `"Ibu Clara"` — Home greeting ("Hi Ibu Clara") |
| role | `String` | `"Anggota IbuDaya"` |
| phone | `String` | fictional |
| city | `String` | e.g. `"Palembang"` |
| joinedAt | `DateTime` | drives "Bergabung sejak …" |
| avatarAsset | `String?` | bundled illustration |

### 3.3 ImpactMetrics

All values `DEMO_SIMULATION`; UI labels them "data komunitas".

| Field | Type | Notes |
| --- | --- | --- |
| totalEnergyUsedKwh | `double` | screenshot: 128 |
| energySharedKwh | `double` | screenshot: 32 |
| co2AvoidedKg | `double` | screenshot: 96 — derived by a fixed factor, see §4.4 |
| arisanGroupSize | `int` | must equal `ArisanGroup.members.length` |
| monthlySavingIdr | `int` | Home "Penghematan Bulan Ini" (245000) |
| solarSharePct | `int` | Home "% Energy Usaha dari Solar Hub" (45) |

### 3.4 EnergyInsight  (bill-scan result — `DEMO_SIMULATION`)

| Field | Type | Notes |
| --- | --- | --- |
| spikeDetected | `bool` | |
| spikeWindowLabel | `String` | "18.00–21.00" |
| addedMonthlyCostIdr | `int` | 45200 — UI label "estimasi" |
| contributors | `List<ApplianceCost>` | ranked desc by `costIdr`; UI label "ilustrasi" |
| mainInsight | `String` | one plain sentence |
| recommendationRoute | `String?` | deep link → SC-06 |

`ApplianceCost`: `{ ApplianceKind kind, String name, int costIdr, String? tip }`

### 3.5 Appliance  (catalog entry)

| Field | Type | Notes |
| --- | --- | --- |
| kind | `ApplianceKind` | |
| name | `String` | "Oven", "Mesin Jahit", "Kulkas", "Blender" (standardised — no "Freezer"/"Kubas") |
| approxPowerKw | `double` | shown on SC-06 |
| iconAsset | `String` | |

### 3.6 RoofScanResult  (preliminary assessment — `DEMO_SIMULATION`)

Per final product decision #2. **No AI-accuracy figure, no confidence
probability, no measurement-precision claim.** Every field is a rough initial
estimate; `verificationNotice` is mandatory on screen.

| Field | Type | Notes |
| --- | --- | --- |
| suitability | `RoofSuitability` | rendered as **"Kelayakan Awal: Sangat Baik"** |
| estimatedPotentialAreaM2 | `double` | "Estimasi area potensial" ≈ 60 (rounded, no decimals shown) |
| roofOrientationLabel | `String` | "Orientasi atap", e.g. "Menghadap timur–barat" |
| sunExposurePotentialLabel | `String` | "Potensi paparan matahari", e.g. "Tinggi" (qualitative, not a %) |
| verificationNotice | `String` | **mandatory**, e.g. "Ini estimasi awal. Perlu verifikasi teknis di lokasi sebelum pemasangan." |
| tip | `String` | "Tips IbuDaya" copy |

**Not in P0 (CR-13 / decision #3 roof simplification):** `estimatedMonthlySavingIdr`,
`estimatedPaybackYears`, and any capacity/ROI calculation. These are
`FUTURE_IMPLEMENTATION` — do not add them to the P0 `roofScan` seed or the SC-05
screen (`BACKLOG` Epic D).

**Removed earlier:** `pitchDegrees` (precise measurement claim), `confidenceLabel`
(confidence-probability claim). The screenshot's "Akurasi AI 92%" and "Kemiringan
Atap 28°" are not represented.

### 3.7 SolarDay + SolarSlot

`SolarDay` (`capacityPct` and recommendation are `DEMO_SIMULATION`):

| Field | Type | Notes |
| --- | --- | --- |
| date | `DateTime` | = scenario "today" |
| capacityPct | `int` | 86 |
| recommendedSlotId | `String` | |
| recommendationReason | `String` | "cuaca cerah, energi cukup" (canned) |
| slots | `List<SolarSlot>` | 4 entries |
| appliances | `List<Appliance>` | catalog for the picker |

`SolarSlot`: `{ String id, String label /* "10.00–12.00" */, SlotAvailability availability }`

### 3.8 SolarBooking  (created during demo)

| Field | Type | Notes |
| --- | --- | --- |
| id | `String` | generated (counter or `uuid`) |
| applianceKind | `ApplianceKind` | |
| slotId | `String` | |
| slotLabel | `String` | denormalised for display |
| date | `DateTime` | |
| createdAt | `DateTime` | |

### 3.9 ArisanGroup / ArisanMember / RotationSlot / LedgerEntry

`ArisanGroup`:

| Field | Type | Notes |
| --- | --- | --- |
| id | `String` | |
| name | `String` | "Arisan Energi Melati" |
| members | `List<ArisanMember>` | 12; includes "Siti Rahma", "Ibu Lina", "Ibu Putri", … |
| myContributionStatus | `ArisanContributionStatus` | drives Home "Status Arisan" ("Lunas") |
| myTurnPosition | `int` | 1-based |
| nextTurnDate | `DateTime` | |
| rotation | `List<RotationSlot>` | for the calendar strip |
| ledger | `List<LedgerEntry>` | newest first; **append-only** |

`ArisanMember`: `{ String id, String name, String? avatarAsset, bool isCurrentUser }`

`RotationSlot`: `{ DateTime date, String memberId, String memberName }`

`LedgerEntry`:

| Field | Type | Notes |
| --- | --- | --- |
| id | `String` | reference id shown in UI |
| type | `LedgerEntryType` | |
| memberId | `String` | |
| memberName | `String` | denormalised |
| amountIdr | `int?` | for contribution/payout |
| amountKwh | `double?` | for quota entries |
| timestamp | `DateTime` | |
| status | `LedgerEntryStatus` | |
| note | `String?` | |

> Ledger is **append-only** in code: repositories expose `append(entry)`, never
> `update`/`delete`. UI copy: "tercatat transparan". **No blockchain** (decision
> #8) — do not use the word or imply on-chain settlement.

### 3.10 EnergyQuota / QuotaOffer / QuotaRequest

`EnergyQuota` (the demo user's position):

| Field | Type | Notes |
| --- | --- | --- |
| availableKwh | `double` | "Tersedia untuk dibagikan" (e.g. 12) |
| neededKwh | `double` | "Kuota yang dibutuhkan" |
| myTurnSlotLabel | `String` | "Jumat, 10.00–12.00" |

`QuotaOffer`:

| Field | Type | Notes |
| --- | --- | --- |
| id | `String` | |
| ownerMemberId | `String` | may be the current user |
| ownerName | `String` | |
| amountKwh | `double` | simple whole-kWh values in MVP (1/2/3) |
| slotLabel | `String` | one of the fixed slots |
| note | `String?` | ≤ 140 chars |
| status | `QuotaOfferStatus` | |
| createdAt | `DateTime` | |

`QuotaRequest`:

| Field | Type | Notes |
| --- | --- | --- |
| id | `String` | |
| offerId | `String` | |
| requesterMemberId | `String` | current user |
| amountKwh | `double` | |
| note | `String?` | |
| status | `QuotaRequestStatus` | |
| createdAt | `DateTime` | |

**MVP quota-trading behaviour (P0-Lite, decision #3):**
- Publishing an offer → append `QuotaOffer` (status `open`) **and** a
  `LedgerEntry` (`quotaShared`, status `pending`); `EnergyQuota.availableKwh`
  decreases by the offered amount.
- Taking/requesting an offer → append `QuotaRequest` + `LedgerEntry`
  (`quotaReceived`, status `pending`); the offer's status → `taken`; if the
  current user is the requester, `EnergyQuota.neededKwh` decreases.
- No bidding, negotiation, partial fills, filters, real-time updates, or
  cross-group trading — those are `FUTURE_IMPLEMENTATION` (see `BACKLOG.md`).

### 3.11 CreditScoreInputs / CreditScore / CreditFactor  (`IMPLEMENTED` engine)

Per final product decision #7. The engine is `DemoCreditScoringEngine`
(`IMPLEMENTED`, rule-based, deterministic). It is **not** a machine-learning
model and the UI must not imply that it is. Interface allows a validated ML
implementation to replace it later without UI changes (`ARCHITECTURE.md §4`).

**`CreditScoreInputs`** — seeded normalised signals, one per category, each `0.0–1.0`:

| Field | Type | Category | Max points | Ibu Clara seed | → points |
| --- | --- | --- | --- | --- | --- |
| energyUsageConsistency | `double` | `energyUsage` | 35 | `0.857` | 30 |
| paymentHistory | `double` | `paymentHistory` | 30 | `0.80` | 24 |
| businessActivity | `double` | `businessActivity` | 20 | `0.90` | 18 |
| communityParticipation | `double` | `communityParticipation` | 15 | `0.667` | 10 |
| | | **TOTAL** | **100** | | **82** |

(Alternatively the seed may specify the integer category points directly; the
engine must still recompute the total and band from them so the result stays
reproducible.)

**`CreditScore`** — computed, never seeded as a finished object:

| Field | Type | Notes |
| --- | --- | --- |
| score | `int` | 0–100; Ibu Clara = 82 |
| band | `CreditBand` | from thresholds; 82 → `baikSekali` ("Baik Sekali") |
| categoryScores | `Map<CreditCategory,int>` | `{energyUsage:30, paymentHistory:24, businessActivity:18, communityParticipation:10}` |
| categoryMax | `Map<CreditCategory,int>` | `{35,30,20,15}` (constant) |
| factors | `List<CreditFactor>` | one per category, generated by the engine |
| eligibility | `LoanEligibility` | `eligible` if `score >= loanParams.eligibleScoreThreshold` |
| ceilingIdr | `int` | see §4.2; Ibu Clara → `2_000_000` |
| computedAt | `DateTime` | |

**`CreditFactor`**: `{ CreditCategory category, String label, FactorDirection direction, int points, int maxPoints, String reason }`

- `label` per category: "Konsistensi pemakaian energi", "Riwayat pembayaran",
  "Aktivitas usaha", "Partisipasi komunitas".
- `direction`: `positive` if `points/maxPoints ≥ 0.6`, `neutral` if `0.4–0.6`,
  `negative` if `< 0.4`.
- `reason`: templated per category (e.g. `paymentHistory` → "Pembayaran arisan
  tepat waktu meningkatkan skor Anda").

### 3.12 LoanParams / LoanSimulation

Per final product decision #6 and CR-2. **Calculation only.** No application
object, no submission, no underwriting, no offer, no regulated product. The flow
ends at the `LoanSimulation` result (SC-11).

`LoanParams` (`PROTOTYPE_DECISION` + explicit `ASSUMPTION` on the rate):

| Field | Type | Value | Notes |
| --- | --- | --- | --- |
| minIdr | `int` | `500_000` | slider floor |
| maxDemoFinancingIdr | `int` | `2_000_000` | **hard cap for the demo** |
| flatMonthlyRatePct | `double` | `2.0` | **DEMO ASSUMPTION: flat simulated rate = 2% per month** |
| tenors | `List<LoanTenorMonths>` | `[m3, m6, m12]` | |
| eligibleScoreThreshold | `int` | `65` | at/above → `LoanEligibility.eligible` |

`LoanSimulation` (`IMPLEMENTED`, pure function — see §4.3):

| Field | Type | Notes |
| --- | --- | --- |
| principalIdr | `int` | ≤ `min(creditScore.ceilingIdr, maxDemoFinancingIdr)` |
| purpose | `LoanPurpose` | carried through from the input screen for display |
| tenorMonths | `int` | 3 / 6 / 12 |
| flatMonthlyRatePct | `double` | `2.0` — echoed on the result screen |
| totalCostIdr | `int` | `principal * rate * months` |
| totalRepaymentIdr | `int` | `principal + totalCost` |
| monthlyInstallmentIdr | `int` | `totalRepayment / months`, rounded for display |

`LoanSimulation` is transient view state produced by `LoanSimulation.compute(...)`
on **Hitung Simulasi**; it is **not** persisted anywhere and there is no
`LoanApplication`. `LoanApplication` (submission, reference id, status) is
`FUTURE_IMPLEMENTATION` — `BACKLOG` Epic E.

**UI copy rules for this feature:**
- Screen/CTA: **"Simulasi Pembiayaan"** / **"Hitung Simulasi"** — never "Ajukan",
  "Kirim Pengajuan", "Pengajuan Terkirim", "Pinjaman Disetujui", "Pinjaman".
- Eligibility line: **"Berdasarkan profil skor Anda"** — never "Direkomendasikan
  oleh AI".
- The result screen shows principal, tenor, simulated flat rate, estimated total
  cost, estimated total repayment, estimated monthly installment, and a visible
  disclaimer that this is a simulation and not an official financing offer.
- Optional secondary CTA may only be **"Saya Tertarik"** with a
  `FUTURE_IMPLEMENTATION` note; it performs no submission. Preferred P0: omit it.

### 3.13 MessageThread / Message  `P1`

`MessageThread`: `{ String id, MessageThreadKind kind, String title, String? avatarAsset, String lastPreview, DateTime lastAt, int unreadCount, List<Message> messages }`

`Message`: `{ String id, String senderId, String senderName, bool isCurrentUser, bool isSystem, String text, DateTime sentAt }`

Threads may include a DM with "Siti Rahma" (community member) — consistent with
the persona decision.

### 3.14 AppNotification  `P1`

`{ String id, NotificationKind kind, String title, String body, DateTime at, bool read, String? route }`

## 4. Derived-value formulas

Pure services with unit tests. Constants live in one place. `IMPLEMENTED` unless
noted.

### 4.1 Credit score  (`IMPLEMENTED`)

```
categoryMax = { energyUsage: 35, paymentHistory: 30,
                businessActivity: 20, communityParticipation: 15 }   // sum = 100

categoryScoreᵢ = round( clamp(inputᵢ, 0, 1) * categoryMaxᵢ )
score          = Σ categoryScoreᵢ                                    // 0..100

band:  score < 50            -> perluPeningkatan
       50 <= score < 65      -> cukup
       65 <= score < 80      -> baik
       80 <= score <= 100    -> baikSekali

Ibu Clara canonical result:
  energyUsage            round(0.857 * 35) = 30
  paymentHistory         round(0.80  * 30) = 24
  businessActivity       round(0.90  * 20) = 18
  communityParticipation round(0.667 * 15) = 10
  score = 82  ->  band = baikSekali ("Baik Sekali")
```

**Factors** (one per category) expose *why*: `points = categoryScoreᵢ`,
`maxPoints = categoryMaxᵢ`, `direction` from the ratio, `reason` from a per-
category template. This is the entire explanation shown on SC-09 — there is no
hidden term.

### 4.2 Borrowing ceiling  (`IMPLEMENTED`)

```
ceilingIdr = 0                        if score < loanParams.eligibleScoreThreshold (65)
           = loanParams.maxDemoFinancingIdr   otherwise            // = Rp 2.000.000
```

Simple by decision #6 (single demo cap). Ibu Clara (82) → `Rp 2.000.000`, which
equals the SC-10 slider maximum.

### 4.3 Loan simulation  (`IMPLEMENTED`; rate is a `DEMO_SIMULATION` assumption)

Exact formula from final product decision #6:

```
rate   = loanParams.flatMonthlyRatePct / 100      // 0.02  (2% per month, flat)
months = tenorMonths                              // 3 | 6 | 12

total_cost        = principal * rate * months
total_repayment   = principal + total_cost
monthly_installment = total_repayment / months    // round to nearest rupiah for display
```

Worked examples (principal = Rp 2.000.000):

| Tenor | total_cost | total_repayment | monthly_installment |
| --- | --- | --- | --- |
| 3 mo | 2.000.000 × 0.02 × 3 = 120.000 | 2.120.000 | ≈ 706.667 |
| 6 mo | 240.000 | 2.240.000 | ≈ 373.333 |
| 12 mo | 480.000 | 2.480.000 | ≈ 206.667 |

(The 3-month figure matches the "Rp 706.000" in the prototype screenshot.)

UI label: **"Simulasi, bukan penawaran resmi."** Unit tests must assert all three
rows above.

### 4.4 CO₂ avoided  (`DEMO_SIMULATION`)

```
co2AvoidedKg = solarEnergyUsedKwh * gridEmissionFactorKgPerKwh
```

`gridEmissionFactorKgPerKwh` is one documented constant (`ASSUMPTION`, e.g.
`0.87`). `ImpactMetrics.co2AvoidedKg` may simply be pre-computed to match the
screenshot (96 kg). UI labels it "estimasi".

## 5. Seed assets layout

```
assets/demo/
  scenario_happy_path.json      # the whole DemoScenario tree
  appliances.json               # shared appliance catalog (optional split)
```

Rules:

- One scenario file fully determines a demo run.
- `generatedAt` fixes "today" so calendars, slots, and tenure are deterministic.
- Persona name is "Ibu Clara"; "Siti Rahma" only ever appears as an
  `ArisanMember` / message contact.
- No real names, phone numbers, addresses, or bill data.
- Numbers match the screenshots where a screen shows them; the credit inputs are
  tuned to produce exactly 82 (§4.1).

## 6. Mutability & lifecycle

| Entity | Seeded | Mutated in-session | How |
| --- | --- | --- | --- |
| UserProfile, ImpactMetrics, RoofScanResult, EnergyInsight, SolarDay, ArisanGroup (structure), CreditScoreInputs, LoanParams | ✅ | ❌ | read-only |
| SolarBooking | `[]` | ✅ append | SC-06 confirm |
| ArisanGroup.ledger | ✅ | ✅ append only | booking (optional), quota publish / take |
| QuotaOffer | ✅ (member offers) | ✅ append (user's) / status → `taken` | SC-13 / SC-14 |
| QuotaRequest | `[]` | ✅ append | SC-14 |
| EnergyQuota (available / needed kWh) | ✅ | ✅ recomputed on offer/take | §3.10 rules |
| CreditScore | — | recomputed on demand | pure function of `CreditScoreInputs` |
| LoanSimulation | — | recomputed on demand | pure function of inputs; transient view state, never persisted |
| MessageThread.unreadCount / Message.read | ✅ | ✅ | opening a thread |
| AppNotification.read | ✅ | ✅ | opening a notification |

**Demo reset** = discard all in-session mutations, re-parse the scenario asset.
