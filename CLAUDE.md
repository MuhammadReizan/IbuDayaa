# IbuDaya Flutter Project

## Product

IbuDaya is an Android app used by a **cooperative (koperasi)** and its
members — women-led micro-businesses in Indonesia — to:

1. **Scan PLN bills/tokens** (camera + on-device ML Kit OCR, always checked by
   the member) and see what each appliance costs.
2. **Book the cooperative's Solar Hub** within slot capacity and a monthly
   member quota; **share quota** with other members (Perdagangan Energi).
3. **Estimate a roof's solar potential** (Radar Atap) from the member's own
   measurements.
4. Run **Arisan Energi** (dues submitted by members, confirmed by an admin).
5. Get a transparent **Skor Kredit Energi** and **apply for a loan** that a
   **cooperative admin reviews, approves/rejects, disburses and tracks**.
6. **Message** the admin, the arisan group, or other members; get notifications.

Two roles: `member` and `admin`. An admin registers and creates the
cooperative, which gets a 6-character invite code; members register with that
code. Login is phone number + 6-digit PIN.

The backend is **local-first today** (one JSON database file on the phone) and
moves to **Supabase** later — see `docs/SUPABASE.md` and
`supabase/migrations/`. Laravel is not part of the plan.

## Honesty rules (non-negotiable)

The users are financially vulnerable. Breaking one of these causes real harm.

- **No AI claims.** There is no trained model. The score is a fixed rule set
  (`RuleBasedCreditScoringEngine`) with its four factors shown on screen; OCR
  is "scan", not "AI". Never write "AI", "kecerdasan buatan", or an accuracy %.
- **People decide loans.** The app never approves anything. Copy says "Skor
  Anda mendukung pengajuan ini" / "Menunggu review admin", and
  `LoanDecisionNotice` appears wherever a loan is discussed.
- **Server-style rules in repositories.** Authorization, eligibility, capacity,
  quota and loan status transitions are enforced in the repository layer (and
  in SQL functions for Supabase), never only in the UI.
- **Score needs history.** Withheld until `kMinMonthsForScore` months recorded.
- **Label assumptions.** CO₂ factor (0.87 kg/kWh), roof assumptions, hub
  sun-curve split and appliance estimates are stated where they appear.
- **OCR is a suggestion.** Scanned numbers are always editable before saving.
- **Quota sharing moves no electricity.** It records an agreement.
- **Sample data is opt-in and labelled.** A fresh install is empty; "Coba
  dengan data contoh" creates a clearly marked sample cooperative.

## Tech Stack

- Flutter · Dart · Material 3
- Riverpod (state) · GoRouter (navigation, `StatefulShellRoute` per role)
- `path_provider`, `camera`, `image_picker`, `google_mlkit_text_recognition`,
  `crypto` — each justified in `pubspec.yaml`

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
- `lib/core/logic/` — pure arithmetic: bill parser, loan math & status machine,
  roof estimator, hub capacity, quota ledger, energy insights, credit signals.
- `LocalSnapshotRepository.load` mirrors RLS: a member sees her own rows; an
  admin sees her whole cooperative.
- Side effects that will be DB triggers in Supabase (notifications, system
  messages in the support thread) live in the local repositories.
- `lib/app/router.dart` — `guard()` is the role gate; keep it pure and tested.

**Riverpod pause gotcha:** routes that are off-screen have paused
subscriptions; a *derived provider chain* that changed meanwhile is flushed
during the resuming build and throws. Screens therefore watch only
`appStateProvider` and derive with selectors. Do not add derived `Provider`s
that screens watch. `test/widget/app_flow_test.dart` guards push → save → pop.

Widgets must not touch repositories or the database directly — go through
`actionsProvider`.

## UI Rules

- Indonesian is the only user-facing language; short, concrete sentences.
- Green identity; use `lib/core/design` tokens and components (`ui_kit.dart`,
  `SuccessPanel`, `AppScaffold` with centred titles). Never inline a hex,
  radius or spacing value in feature code.
- Support 360 dp width; minimum tap target 48 dp.
- Every screen handles empty / error / success states; mutations go through
  `runAction` so failures show a readable message.
- Destructive or money-related actions need a confirmation dialog.

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

- Until Supabase is connected, data lives on one phone: admin and members only
  "meet" when they use the same device (e.g. the sample cooperative).
- The Supabase migration is written but not yet run against a live project;
  the `submit-loan` Edge Function and Supabase repositories are not built.
- Lending must be run by a legally registered savings-and-loan cooperative.
- The Solar Hub "best production window today" panel (`lib/core/weather/`)
  calls BMKG's public forecast API directly — the one place in the app that
  needs network access. It is opt-in (admin sets a `weatherAdm4Code` on the
  hub in Hub Settings) and hides itself on any failure; nothing else
  depends on it. Verified against a live response on 2026-09-17: the `tcc`
  cloud-cover field and the rest of the parsed shape are correct as coded.
  `16.71.05.1001` (Kelurahan Delapan-belas Ilir, Kec. Ilir Timur Satu, Kota
  Palembang) is a real adm4 code — usable as the pilot/demo default.
