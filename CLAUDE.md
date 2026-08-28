# IbuDaya Flutter Project

## Product

IbuDaya is a competition MVP for an AI-powered community solar and
micro-financing cooperative focused on women-led MSMEs.

The product has three core pillars:
1. Communal Solar Hub
2. Alternative Credit Scoring
3. Energy Arisan

The competition brief in /docs is the authoritative source of product claims.

Prototype screenshots are visual references, not immutable specifications.

Never invent business requirements, datasets, AI model performance,
legal compliance claims, or financial partnerships.

If information is missing, explicitly label it as an assumption.

## Tech Stack

- Flutter
- Dart
- Material 3
- Riverpod for state management
- GoRouter for navigation
- Feature-first project structure

Do not introduce another state management or routing framework.

## Architecture

UI -> Controller/Provider -> Repository -> Data Source

Widgets must not directly call APIs.

Each external service must have an interface so a demo implementation
can be swapped with a production implementation.

The competition build must work in Demo Mode without network access.

## UI Rules

- Indonesian is the primary user-facing language.
- Preserve IbuDaya's green visual identity.
- Use a centralized design system.
- Do not hardcode colors repeatedly.
- Do not hardcode duplicated spacing values.
- Use SafeArea where required.
- Avoid RenderFlex overflow.
- Support common Android widths from 360px upward.
- Minimum interactive target approximately 44-48 logical pixels.
- Keep text readable for users with limited digital literacy.
- Every screen must support loading, error, empty, and success states
  where relevant.
- Do not redesign unrelated screens while implementing one feature.

## AI Rules

Do not claim an AI model exists unless it is implemented.

Prototype or simulated outputs must be explicitly represented in code
as demo/mock implementations.

Credit scoring must expose explainable contributing factors.

Roof analysis must be described as an initial estimation unless a
validated measurement pipeline exists.

Financial outputs are simulations unless an actual regulated provider
integration exists.

## Coding Rules

- Prefer small reusable widgets.
- Avoid files larger than necessary.
- Avoid duplicate business logic.
- Use immutable state where practical.
- Add comments only where logic is not obvious.
- No secrets or credentials in the repository.
- Never commit API keys.
- Do not add dependencies without explaining why.

## Workflow

Before changing code:
1. Inspect existing implementation.
2. State which files will change.
3. Preserve existing working behavior.

After changing code:
1. Run dart format.
2. Run flutter analyze.
3. Run relevant tests.
4. Fix all errors introduced by the change.
5. Summarize exactly what changed.

Do not mark a task complete when flutter analyze fails.

## Competition Goal

The application should deliver a stable 3-5 minute live demo showing:

Home
-> Energy Bill Scan
-> AI Energy Insight
-> Solar Hub
-> Energy Arisan
-> Alternative Credit Score
-> Financing Simulation
-> Impact/Profile

Reliability is more important than adding non-essential features.