# IbuDaya — Design System

> **There is no authoritative Figma/design source (decision #4).** The prototype
> screenshots are the *provisional* visual source. **Every** inferred value below
> — colour, typography, spacing, radius, shadow, component style — is a
> `PROTOTYPE_DECISION` and must be centralised so it can be replaced later
> without touching screen code. The **structure** (tokens, components, states) is
> fixed; the **values** are tunable in one file (`core/design/tokens.dart`).

## 1. Brand & tone

- **Identity:** warm, trustworthy, community-first. Green = clean energy + growth.
- **Voice:** plain Indonesian, short sentences, second person ("Anda"), no
  finance/tech jargon. Explain every number.
- **Imagery:** flat vector illustrations of Indonesian women running small
  businesses, solar panels, community scenes. Illustrations are bundled assets;
  in planning they are placeholders.

## 2. Color tokens  `PROTOTYPE_DECISION` (confirm hex with design source)

Define once in `core/design/tokens.dart`; never inline a hex in a widget.

| Token | Value (start) | Usage |
| --- | --- | --- |
| `primary` | `#1E8E4E` (medium green) | primary buttons, active nav, key figures |
| `primaryDark` | `#14663A` | pressed state, headings on light green |
| `primaryContainer` | `#E7F4EC` | card headers, selected chips, section tints |
| `onPrimary` | `#FFFFFF` | text/icons on `primary` |
| `secondary` | `#F4A623` (amber) | "Dapatkan Kuota" CTA, warnings, highlights |
| `surface` | `#FFFFFF` | cards |
| `background` | `#F5F7F5` | screen background behind cards |
| `outline` | `#E2E6E2` | dividers, card borders, input borders |
| `textPrimary` | `#1B1F1D` | body text |
| `textSecondary` | `#5E655F` | captions, helper text, labels |
| `success` | `#1E8E4E` | positive factor, "Lunas" |
| `warning` | `#F4A623` | "Alat Usaha Standby", non-blocking notes |
| `danger` | `#D8412F` | "Lonjakan Energi Terdeteksi", added-cost figures |
| `dangerContainer` | `#FBEBE9` | alert card background |
| `info` | `#2F6FE0` | "Aman & Terpercaya" trust notes |
| `infoContainer` | `#E9F0FC` | info card background |

- Build a Material 3 `ColorScheme` from these; do not use Flutter's default
  purple.
- Dark mode: **not in MVP**. Do not spend time on it; if it renders acceptably
  from M3 theming, fine, but it is untested.
- Contrast: body text on `background`/`surface` must be ≥ 4.5:1; large text and
  UI components ≥ 3:1. Check `textSecondary` on `background` specifically.

## 3. Typography  `PROTOTYPE_DECISION`

- Font: a friendly humanist sans (screenshots look like Poppins / Plus Jakarta
  Sans). Bundle the `.ttf` (preferred) or use `google_fonts`.
- Scale (map to M3 roles):

| Role | Size / weight | Use |
| --- | --- | --- |
| `displayScore` | 40 / 700 | the big credit-score number, "Rp 245.000" hero |
| `headlineSmall` | 22 / 700 | screen titles ("Analisis Energi") |
| `titleMedium` | 16 / 600 | card titles, section headers |
| `bodyLarge` | 15 / 400 | primary body |
| `bodyMedium` | 14 / 400 | secondary body |
| `label` | 12 / 500 | chips, qualifiers ("estimasi"), captions |
| `button` | 15 / 600 | button labels |

- Line height ≥ 1.35 for body. Support OS text scaling up to ~1.3× without
  breaking layouts (test at `textScaleFactor` 1.3).
- Never hardcode `TextStyle` in widgets — use `Theme.of(context).textTheme`.

## 4. Spacing & layout

- **4 dp base grid.** Scale: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`.
- Screen horizontal padding: `lg (16)`.
- Card padding: `lg (16)`; gap between cards: `md (12)`.
- Section vertical rhythm: `xl (24)` between major sections.
- Min interactive target: **48 dp** (never below 44).
- All screens wrapped in `SafeArea`; scrollable body (`CustomScrollView` /
  `ListView`) so small devices never overflow.
- Content max width not required (phone-only), but avoid full-bleed text lines >
  ~60 chars.
- **No `Row` of flexible text without `Expanded`/`Flexible`** — the top cause of
  RenderFlex overflow; enforce in review.

## 5. Shape & elevation

| Token | Value | Use |
| --- | --- | --- |
| `radiusCard` | 16 | cards, sheets |
| `radiusButton` | 12 | buttons, inputs |
| `radiusPill` | 999 | chips, toggles, status badges |
| `elevationCard` | 0–1 + `outline` border | cards are flat with a hairline border, matching screenshots |
| `elevationSheet` | 2 | bottom sheets, dialogs |

## 6. Core components (`core/design/components/`)

Build these once; every screen composes them.

| Component | Purpose | Key props / variants |
| --- | --- | --- |
| `AppScaffold` | consistent screen frame: title, optional back, `SafeArea`, scroll body, optional bottom CTA bar | `title`, `onBack`, `bottomBar`, `scrollable` |
| `BottomNavShell` | 4-tab shell (Beranda / Solar Hub / Pesan / Profil) | active index, keeps per-tab state |
| `SectionCard` | white rounded card with hairline border, optional header row + trailing action ("Lihat Semua") | `title`, `trailing`, `child` |
| `StatTile` | label + big value + optional delta/qualifier | `label`, `value`, `qualifier`, `tone` |
| `PrimaryButton` / `SecondaryButton` / `TextLinkButton` | actions | full-width by default; `loading`; `enabled` |
| `ChoiceChipRow` / `SegmentedToggle` | single-select options (tenor, kWh amount, filter chips) | `options`, `selected`, `onChanged` |
| `SelectableTile` | appliance / slot / purpose option with icon, label, sublabel, selected ring | `selected`, `disabled`, `badge` ("penuh", "Rekomendasi") |
| `StepHeader` | numbered step label for stepped forms ("1. Nominal Pinjaman") | `index`, `title` |
| `ScoreGauge` | semicircular 0–100 gauge with value + band | `score`, `band` |
| `FactorRow` | icon + category label + direction + **points / maxPoints** + one-line reason (credit score breakdown) | `direction`, `points`, `maxPoints`, `reason` |
| `CalendarStrip` | month row highlighting rotation/turn dates (read-only) | `month`, `markedDates`, `todayDate` |
| `InfoBanner` | inline callout in 4 tones: `success` / `warning` / `danger` / `info` | `tone`, `icon`, `text` |
| `QualifierLabel` | small pill for `DEMO_SIMULATION` values: "estimasi" / "estimasi awal" / "simulasi" / "ilustrasi" / "data contoh" | `kind` |
| `TrustNote` | "Aman & Terpercaya" style reassurance strip with shield icon | `text` |
| `SimulationDisclaimer` | full-width `InfoBanner` (info tone) used on the financing screens: "Ini simulasi, bukan penawaran resmi. IbuDaya tidak menyalurkan pinjaman." | — |
| `VerificationNotice` | `InfoBanner` (warning tone) for the roof screen: "estimasi awal … perlu verifikasi teknis …" | `text` |
| `AmountSlider` | rupiah slider with min/max, ticks, clamped value + helper text | `min`, `max`, `value`, `helper` |
| `LedgerRow` | transaction row: member, type, amount (Rp or kWh), time, status | `type`, `status` |
| `EmptyState` | icon + title + body + optional CTA | `icon`, `title`, `message`, `action` |
| `ErrorState` | icon + message + "Coba lagi" | `message`, `onRetry` |
| `LoadingState` | centered spinner + optional label; or skeleton list variant | `label`, `skeleton` |
| `ConfirmDialog` | title + body + confirm/cancel | destructive variant for discard/logout |

## 7. State pattern (every data screen)

Exactly four visual states, driven by `AsyncValue` (see `ARCHITECTURE.md §6`):

| State | Widget | When |
| --- | --- | --- |
| Loading | `LoadingState` (spinner or skeleton) | initial load, after demo reset, simulated scan latency |
| Empty | `EmptyState` with a relevant CTA | no insight, empty ledger, filtered list with 0 results |
| Error | `ErrorState` with retry | seed/data failure only |
| Success | the real content | data present |

Never show a blank screen or a raw exception. Never leave a spinner with no
timeout path.

## 8. Iconography

- Material Icons (`Icons.*`) for UI affordances.
- Feature/decorative icons (solar, arisan, energy) as bundled SVG/PNG assets in
  a single `assets/images/` set with consistent stroke weight.
- One icon size scale: 20 (inline), 24 (default), 32 (tile), 48 (empty state).

## 9. Content & number formatting

- Currency: `Rp` + thousands separator with `.` (`id_ID`): `Rp 245.000`. Helper
  in `core/format/money.dart`. Never format inline.
- Energy: `12 kWh`, `3,2 kWh` (comma decimal, `id_ID`).
- Percent: `45%` (no decimal unless needed).
- Dates: `id_ID` (`Jumat, 10 Mei`), slot labels `10.00–12.00` (en-dash, dots).
- Every estimated/simulated figure is followed by a `QualifierLabel`.
- Avoid ALL-CAPS words except short status pills.

## 10. Accessibility checklist (per screen)

- [ ] Interactive targets ≥ 48 dp.
- [ ] Text contrast ≥ 4.5:1 (body) / ≥ 3:1 (large, components).
- [ ] Renders at `textScaleFactor` 1.0 and 1.3 with no overflow.
- [ ] Renders at 360 dp and 412 dp width.
- [ ] Meaningful `Semantics` labels on icon-only buttons (back, bell, add).
- [ ] Color is never the only signal (pair with icon/text: e.g. danger + ⚠ + label).
- [ ] Primary action reachable without horizontal scrolling.

## 11. Do / Don't

**Do**
- Compose screens from `SectionCard` + the shared components.
- Put every color, size, radius, duration in `tokens.dart`.
- Keep one CTA per screen visually dominant.
- Use `InfoBanner`/`QualifierLabel` to keep AI outputs honest.

**Don't**
- Introduce a second card style, button style, or green.
- Hardcode `EdgeInsets.all(16)` / `Color(0xFF...)` in feature widgets.
- Redesign a screen not in the current task's scope.
- Use the default Material purple or default `ThemeData()`.
- Ship a screen without its empty + error states.

## 12. Theme wiring

```
core/design/
  tokens.dart        # raw values (this doc §2–§5)
  app_theme.dart     # ColorScheme + TextTheme + component themes from tokens
  components/         # §6 widgets, each using Theme.of(context)
```

`app.dart` sets `theme: AppTheme.light` and `themeMode: ThemeMode.light` for the
MVP.
