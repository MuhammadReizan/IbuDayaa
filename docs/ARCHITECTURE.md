# IbuDaya — Architecture

> Constraint from the brief: **do not overengineer.** This is a single-user,
> offline, demo-first Android app. The architecture below is the minimum that
> keeps features isolated, logic testable, and a future backend swappable.

## 1. Stack

| Concern | Choice | Notes |
| --- | --- | --- |
| UI | Flutter, Material 3 | Portrait, Android, 360 dp+ |
| Language | Dart 3.8+ | repo pins `sdk: ^3.8.1` |
| State management | **Riverpod** (`flutter_riverpod` + `riverpod_annotation` optional) | No other state lib. |
| Navigation | **GoRouter** | `ShellRoute` for bottom nav; typed route helpers. |
| Immutability | hand-written `copyWith`, or `freezed` **only if** boilerplate becomes painful | Start without codegen; add `freezed`/`json_serializable` later if justified. |
| Local data | JSON assets + in-memory repositories | No SQLite/Hive for MVP. |
| Localization | `flutter_localizations` + ARB (`intl`) or a simple typed `AppStrings` class | Indonesian only; must be centralised either way. |
| Testing | `flutter_test`, `ProviderContainer` unit tests, widget tests | Focus: scoring + loan math + golden-path smoke. |

**Dependencies to add (with justification):**

| Package | Why | Class |
| --- | --- | --- |
| `flutter_riverpod` | required state management | P0 |
| `go_router` | required navigation | P0 |
| `intl` | number/date formatting for `id_ID`, ARB support | P0 |
| `google_fonts` *(optional)* | if the design font isn't bundled; otherwise bundle the .ttf and skip | P1 |
| `image_picker` | real camera/gallery for bill & roof scan | P1 |
| `freezed` + `build_runner` + `json_serializable` | cut model boilerplate once models stabilise | P1, defer |
| `uuid` | ids for bookings/applications (or use a counter and skip) | P1, optional |

Nothing else without a written reason in the PR.

## 2. Layering

```
Presentation  (widgets, screens)         lib/features/<f>/presentation/
      │  watches
      ▼
Application    (Riverpod notifiers,       lib/features/<f>/application/
               view-models, form state)
      │  calls
      ▼
Domain         (entities, value objects,  lib/features/<f>/domain/
               pure services, repo
               interfaces)
      │  implemented by
      ▼
Data           (DemoRepository reading    lib/features/<f>/data/
               seed; future Remote impl)
```

Rules:

- **Widgets never call a repository or a data source directly.** They watch a
  provider.
- **Domain has no Flutter import** except `foundation` (for `@immutable`).
- Pure services (credit score, loan simulation, CO2) are plain Dart classes with
  no Riverpod dependency — injected via providers, tested directly.
- The credit score lives behind an interface: `CreditScoringEngine` (domain) with
  `DemoCreditScoringEngine` (`IMPLEMENTED`, rule-based, deterministic) as the MVP
  implementation. A future validated ML engine implements the same interface and
  the credit-score UI does not change (decision #7).
- Cross-feature access goes through a feature's **public providers**, not its
  internal files.

## 3. Feature-first folder structure

```
lib/
  app/
    app.dart                 # ProviderScope + MaterialApp.router
    router.dart              # GoRouter config, ShellRoute, route names
    bootstrap.dart           # load seed, then hand off to router
  core/
    design/
      app_theme.dart         # ThemeData from tokens
      tokens.dart            # colors, spacing, radius, durations
      components/             # shared widgets (see DESIGN_SYSTEM.md)
    demo/
      demo_scenario.dart     # DemoScenario model + JSON parse
      demo_repository.dart    # holds current scenario + in-session mutations
      demo_controller.dart    # load / reset providers
    l10n/
      app_id.arb             # (or app_strings.dart) Indonesian strings
      strings.dart           # typed accessor
    format/
      money.dart             # Rp formatting
      energy.dart            # kWh formatting
      dates.dart             # id_ID dates, slot labels
    result/
      async_view.dart        # AsyncValue -> loading/empty/error/success
    utils/
  features/
    home/            { presentation/ application/ domain/ data/ }
    bill_scan/       { ... }        # SC-02, SC-03
    solar_hub/       { ... }        # SC-04..SC-07
    arisan/          { ... }        # SC-08, SC-12..SC-15 (SC-12..15 = P0-Lite quota sharing)
    credit_score/    { ... }        # SC-09 — domain: CreditScoringEngine + DemoCreditScoringEngine
    financing/       { ... }        # SC-10, SC-11 — "Simulasi Pembiayaan" (simulation only)
    messages/        { ... }        # SC-16, SC-17  (P1)
    profile/         { ... }        # SC-18, SC-19, SC-21
    notifications/   { ... }        # SC-20  (P1)
    onboarding/      { ... }        # SC-22  (P1)
assets/
  demo/scenario_happy_path.json
  images/            # illustrations, icons
test/
  unit/demo_credit_scoring_engine_test.dart   # asserts Ibu Clara = 82 (30/24/18/10)
  unit/loan_simulation_test.dart              # asserts the 3/6/12-month rows
  widget/golden_path_smoke_test.dart
  ...
```

A feature folder only creates the sub-layers it needs (e.g. `home` may have no
`domain/` of its own and just read other features' providers).

## 4. Repository abstraction

Each feature that owns data defines an interface in `domain/`:

```dart
abstract interface class ArisanRepository {
  ArisanGroup watchGroup();                 // sync read from in-memory scenario
  void appendLedgerEntry(LedgerEntry e);
  QuotaOffer publishOffer(NewOfferDraft d);
  // ...
}
```

Implementations:

| Impl | Location | Used by | Behaviour |
| --- | --- | --- | --- |
| `DemoArisanRepository` | `features/arisan/data/` | the demo build (only one wired) | reads `DemoRepository.current`, applies in-session mutations, appends to the local ledger |
| `RemoteArisanRepository` | *not built for MVP* | future production flavor | HTTP; **must not be referenced by the demo build** |

Providers pick the implementation:

```dart
final arisanRepositoryProvider = Provider<ArisanRepository>((ref) {
  // MVP: always demo. Future: switch on a build flavor / AppConfig.
  return DemoArisanRepository(ref.watch(demoRepositoryProvider));
});
```

Keep interfaces **small and feature-scoped**. Do not build a generic
"DataSource<T>" abstraction — it is not needed.

## 5. Demo Mode (local-first)

- `bootstrap.dart` loads `assets/demo/scenario_happy_path.json`, parses it into a
  `DemoScenario`, and puts it in `DemoRepository` (a `StateNotifier`/`Notifier`
  holding `current` + methods to mutate/reset).
- All feature repositories read from `DemoRepository.current`. Session mutations
  (bookings, ledger appends, applications) are stored back in `DemoRepository`.
- **Reset** (`SC-21`): `demoControllerProvider.reset()` → re-parse the asset →
  replace `current` → router goes to Home.
- There is no persistence: killing the app is also a reset. That is acceptable
  and desirable for the competition.
- **No `dio`/`http` in the dependency tree for the demo flavor.** A lint/CI check
  can assert this.

## 6. State & async conventions

- Screen state = a `Notifier`/`AsyncNotifier` in `application/`, exposed as a
  provider. Widgets `ref.watch` it.
- Even though reads are synchronous, wrap screen loads in `AsyncValue` (via a
  tiny helper) so **loading / empty / error / success** are uniform. Simulated
  latency (150–1200 ms) is added deliberately on scan/analyse screens for demo
  realism and lives in the repository, not the widget.
- Forms (SC-06, SC-10, SC-13) use a `Notifier` holding an immutable form model
  with `copyWith`; the CTA's enabled state is a derived getter.
- Navigation is triggered from widgets (`context.go`/`context.push`) using route
  name constants from `router.dart`, never string literals scattered around.

## 7. Navigation map

```
/ (splash)  ──▶  /onboarding (P1, once)  ──▶  ShellRoute
ShellRoute (bottom nav, keeps state per tab):
  /home                     SC-01
  /solar                    SC-04
  /messages                 SC-16   (P1)
  /profile                  SC-18
Pushed on top of the shell:
  /bill-scan                SC-02
  /bill-scan/result         SC-03
  /solar/roof-result        SC-05
  /solar/booking            SC-06
  /solar/booking/confirmed  SC-07
  /arisan                   SC-08
  /arisan/trade             SC-12   (P0-Lite)
  /arisan/trade/share       SC-13   (P0-Lite)
  /arisan/trade/request     SC-14   (P0-Lite)
  /arisan/trade/published   SC-15   (P0-Lite)
  /credit-score             SC-09   ("Skor Kredit Energi")
  /financing                SC-10   ("Simulasi Pembiayaan" — input)
  /financing/result         SC-11   ("Hasil Simulasi Pembiayaan" — no submission)
  /messages/:threadId       SC-17   (P1)
  /profile/about            SC-19
  /profile/settings         SC-21
  /notifications            SC-20   (P1)
```

Deep-linking is not required (offline demo), but route names must be stable for
notification taps (SC-20).

## 8. Error handling

- **Expected empty** (no insight, empty ledger, filtered-out list) → the screen's
  own empty state. Not an error.
- **Developer/data error** (seed asset missing or unparseable) → a single global
  `ErrorScreen` with retry. Only reachable from bootstrap in practice.
- **No uncaught exceptions in the golden path.** `FlutterError.onError` logs to
  console in debug; in the demo build a `runZonedGuarded` wrapper shows the
  `ErrorScreen` rather than a red screen.
- No crash reporting SDK in the MVP.

## 9. Testing strategy

| Level | What | Must-have |
| --- | --- | --- |
| Unit | `DemoCreditScoringEngine` (asserts Ibu Clara = 82 / 30·24·18·10), `LoanSimulation` (asserts the 3/6/12-month rows in `DATA_MODEL.md §4.3`), formatters, scenario JSON parse | ✅ P0 |
| Provider/unit | form notifiers (SC-06, SC-10, SC-13) enable/validate logic | ✅ P0 |
| Widget | each P0 screen renders its success + empty + error state without overflow at 360 dp | ✅ P0 (at least success state) |
| Widget flow | golden-path smoke test: pump app, tap through SC-01→SC-11, assert key texts | ✅ P0 |
| Golden images | optional, only if the team has bandwidth | P2 |

`flutter analyze` must be clean before any task is called done (per `CLAUDE.md`).

## 10. Build flavors / config

- Single flavor for the MVP: **demo**. An `AppConfig` object (`isDemo = true`)
  exists so the repository providers have a switch point, but there is no second
  flavor to build.
- App id `com.baswaramusi.ibudaya`, display name "IbuDaya" (decision #5 —
  confirmed). Icon + splash set once.
- No secrets, no `.env`, no API keys anywhere in the repo.

## 11. What we are deliberately NOT doing

- No clean-architecture use-case classes for every action (services + repos are
  enough).
- No DI framework beyond Riverpod.
- No global event bus / redux / bloc.
- No local database or encrypted storage.
- No code generation until models are stable (then only `freezed`/json).
- No multi-module / melos setup.
- No network layer wired into the demo build.
- No blockchain / distributed-ledger library. The Energy Arisan ledger is an
  in-memory append-only `List<LedgerEntry>` (decision #8).
