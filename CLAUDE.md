# IbuDaya Flutter Project

## Product

IbuDaya is an **offline-first Android app** that women-led micro-businesses in
Indonesia use to track what their electricity actually costs them, log the
energy they take from a shared community solar hub, and keep their arisan
(rotating savings circle) as a transparent book.

It is a real, usable app — not a demo. A fresh install starts **empty**: the
person records their own bills, appliances, hub sessions, and arisan
transactions, and every figure on screen is computed from those records.

Three pillars:
1. Communal Solar Hub — log energy taken from the shared installation.
2. Energy Score — IbuDaya's own internal score from recorded behaviour.
3. Energy Arisan — the circle's ledger, plus quota-sharing agreements.

The competition brief in `/docs` is the origin of the product idea, but the
shipped app is narrower and more honest than the brief's pitch. Where the two
disagree, **the honesty rules below win.**

## Honesty rules (non-negotiable)

These exist because the users are financially vulnerable. Breaking one causes
real harm, not just a bad review.

- **No lending.** IbuDaya has no OJK licence and no licensed partner. It must
  never offer, submit, approve, or disburse a loan. The financing screen is a
  calculator; words like "Ajukan", "Pengajuan", "Disetujui" are banned there.
- **No AI claims.** There is no trained model. Every number is arithmetic over
  user-entered data, and the formula is shown. Never label a rule "AI".
- **No invented data.** Nothing is seeded at install. If a value has not been
  recorded, show an empty state — never a placeholder dressed as insight.
- **Say "belum cukup data".** The score is withheld until there are at least
  `kMinBillsForScore` bills. A confident number built on one entry is a lie.
- **Label assumptions.** The grid CO₂ factor is an assumption and is stated as
  one wherever it appears.
- **Quota sharing moves no electricity.** It records an agreement between
  members. Never imply an energy transfer.
- **No data leaves the device.** No network calls, no accounts, no analytics.

`test/widget/app_flow_test.dart` and `test/unit/data/insights_test.dart` guard
several of these; keep them passing.

## Tech Stack

- Flutter · Dart · Material 3
- Riverpod for state management
- GoRouter for navigation
- `path_provider` for the storage location
- Feature-first project structure

Do not introduce another state management or routing framework. Do not add a
dependency without explaining why.

## Architecture

```
UI → derived providers → AppDataController → AppStore → JSON file on device
```

- `lib/core/data/models.dart` — the user's records, all immutable + JSON.
- `lib/core/data/app_data.dart` — the single root document.
- `lib/core/data/app_store.dart` — `AppStore` interface; `FileAppStore` writes
  atomically (temp file + rename). Swap this for a synced implementation later
  without touching anything above it.
- `lib/core/data/app_data_controller.dart` — owns the document; every mutation
  publishes new state then persists.
- `lib/core/data/derived_providers.dart` — read-only views. Screens watch these,
  never the raw document.
- `lib/core/data/insights.dart` — all derived arithmetic.

Widgets must not touch the store directly.

**Riverpod pause gotcha:** subscriptions pause while a route is off-screen, and
a provider that changed meanwhile is flushed *during* the resuming build, which
trips a setState-during-build assertion. `keepDerivedProvidersWarm()` is called
once from `IbuDayaApp` to prevent this. Add any new derived provider to the
`_derived` list there.

## UI Rules

- Indonesian is the only user-facing language.
- Preserve IbuDaya's green visual identity.
- Use the design system in `lib/core/design`. Never inline a hex, radius, or
  spacing value in feature code.
- Use SafeArea where required; avoid RenderFlex overflow.
- Support widths from 360 dp upward. A label must never be squeezed narrower
  than its longest word (guarded by `responsiveness_test`-style assertions).
- Minimum interactive target ~48 logical pixels.
- Write for someone with limited digital literacy: short sentences, concrete
  words, no jargon.
- Every screen needs loading / empty / error / success states where relevant.
- Destructive actions need a confirmation dialog.
- Do not redesign unrelated screens while implementing one feature.

## Coding Rules

- Prefer small reusable widgets.
- Immutable state; `copyWith` for updates.
- Comment only where the reasoning is not obvious from the code.
- No secrets, credentials, or API keys in the repository.

## Workflow

Before changing code:
1. Inspect the existing implementation.
2. State which files will change.
3. Preserve existing working behaviour.

After changing code:
1. `dart format lib/ test/`
2. `flutter analyze`
3. `flutter test`
4. Fix everything the change broke.
5. Summarise exactly what changed.

Never mark a task complete while `flutter analyze` fails.

## Known limits (things that need outside work, not code)

- Multi-device arisan, chat, and real member-to-member quota transfer need a
  backend. The repository interfaces are ready; the server is not built.
- Real lending needs an OJK-licensed partner.
- Automatic bill reading needs OCR; automatic energy data needs metering
  hardware. Today the user types both.
