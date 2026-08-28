# IbuDaya Agent Instructions

Read these files before implementing features:

- CLAUDE.md
- docs/PRODUCT_SPEC.md
- docs/MVP_SCOPE.md
- docs/USER_FLOWS.md
- docs/SCREEN_INVENTORY.md
- docs/DATA_MODEL.md
- docs/ARCHITECTURE.md
- docs/DESIGN_SYSTEM.md

These documents are the current source of truth.

## Project

IbuDaya is a Flutter competition MVP for:
1. Communal Solar Hub
2. Energy Arisan
3. Alternative Credit Scoring

Primary demo persona:
Ibu Clara

## Stack

- Flutter
- Dart
- Material 3
- Riverpod
- GoRouter
- feature-first architecture

Do not introduce another state-management or routing framework.

## Architecture

UI
→ Provider / Controller
→ Repository
→ Data Source

Widgets must not directly read assets, JSON, APIs, or external services.

The competition application must remain fully functional in local Demo Mode.

## Product honesty

Never fabricate production capabilities.

Respect these labels:

- IMPLEMENTED
- DEMO_SIMULATION
- PROTOTYPE_DECISION
- ASSUMPTION
- FUTURE_IMPLEMENTATION

The current credit scoring implementation is deterministic rule-based logic,
not a trained AI/ML model.

User-facing name:
"Skor Kredit Energi"

Canonical score:
30/35 + 24/30 + 18/20 + 10/15 = 82/100.

Financing is simulation only.

No:
- loan approval
- loan application submission
- real underwriting
- blockchain
- production AI claims

## UI

Use the existing design system.

Prototype screenshots are the provisional visual reference.

Preserve:
- IbuDaya green visual identity
- Indonesian UI
- centralized design tokens
- responsive Android layouts
- readable hierarchy
- minimum comfortable touch targets

Do not redesign unrelated screens.

## Development workflow

Before editing:
1. Inspect existing implementation.
2. Read relevant planning docs.
3. Reuse existing architecture and shared components.

After editing:
1. dart format .
2. flutter analyze
3. flutter test

Fix all introduced errors before completion.

Do not implement unrelated features automatically.