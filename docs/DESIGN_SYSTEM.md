> **DOKUMEN V1 — sudah digantikan.** Redesign v2 (role anggota/admin, pinjaman ditinjau admin koperasi, scan OCR, lokal lalu Supabase) dijelaskan di `CLAUDE.md`, `docs/SCREENS.md`, dan `docs/SUPABASE.md`. Isi di bawah hanya untuk riwayat.

# IbuDaya — Design System

> **v2 — full visual redesign applied.** The master mockup
> (`docs` image reference) is the visual north star: warm, premium, human,
> community-driven. Every value below lives in `lib/core/design/tokens.dart`
> (colour, spacing, radius, shadow, motion) or `typography.dart`. Brand assets
> (logo, illustrations, avatars) are code-drawn in `lib/core/brand/`.

## 1. Brand & tone

- **Identity:** warm, trustworthy, community-first, empowering. Green = clean
  energy + growth; solar-yellow accent = optimism / the sun.
- **Voice:** plain Indonesian, short sentences, second person ("Anda"), no
  finance/tech jargon. Explain every number. Numbers are hero information.
- **Mark:** a rising sun cradled by a growing leaf (`IbuDayaMark`). Wordmark
  `IbuDaya` with the "Daya" half in primary green (`IbuDayaLogo`).
- **Imagery:** editorial geometric spot illustrations (`BrandArt`) — sun, house,
  panels, community, coins — drawn with `CustomPainter`, no image assets. The
  persona avatar (`IbuClaraAvatar`) is a painted head-scarf glyph on a warm
  gradient. A licensed illustration set can replace these later 1:1.

## 2. Color tokens  `PROTOTYPE_DECISION` (confirm hex with design source)

Define once in `core/design/tokens.dart`; never inline a hex in a widget.

| Token | Value | Usage |
| --- | --- | --- |
| `primary` | `#18864B` growth green | primary buttons, active nav, key figures |
| `primaryDark` | `#0E5D35` deep forest | headings on light green, hero-card gradient end |
| `primaryDarker` | `#0A4527` | snackbars, deepest wash |
| `primaryContainer` | `#EAF6EF` soft mint | card headers, selected chips, mint cards |
| `secondary` | `#F4B63E` solar yellow | accent, "sun" motifs, chart bars, delta arrows |
| `secondaryContainer` | `#FDF3DE` | solar-tone cards, warning fills |
| `surface` | `#FFFFFF` | cards |
| `surfaceAlt` | `#F4F1E9` | input fill, subtle panels, progress track |
| `background` | `#FAF9F5` warm cream | screen background |
| `outline` / `outlineSubtle` | `#E7E3D6` / `#F0ECE0` | dividers, hairline borders |
| `textPrimary` | `#17211B` | body text |
| `textSecondary` / `textTertiary` | `#5B655F` / `#8B948D` | captions / de-emphasised |
| `textOnDark` / `textOnDarkDim` | `#F3F7F3` / `#B9D4C4` | text on forest surfaces |
| `success` | `#18864B` | positive factor, "Lunas" |
| `warning` / `warningText` | `#E39A1F` / `#8A5A00` | non-blocking notes / text on solar |
| `danger` / `dangerText` | `#D8412F` / `#A5291B` | spikes, added-cost figures |
| `info` / `infoText` | `#2F6FE0` / `#1B4DA6` | trust / explanatory notes |

- Gradients (`AppGradients`): `brand` (green hero cards), `forest` (splash /
  success), `mint` (input & score panels), `solar`.
- Material 3 `ColorScheme` is built from these in `app_theme.dart`. Never the
  default purple, never a raw `Color(0xFF…)` in feature code.
- Dark mode: not in the MVP (light-only theme).
- Contrast: body ≥ 4.5:1, large text / components ≥ 3:1.

## 3. Typography  (`typography.dart`)

- **Face:** Plus Jakarta Sans (SIL OFL). Not bundled in this environment — see
  `assets/fonts/README.md`; the platform humanist sans + the tuned scale below
  is the current fallback. `AppTypography.fontFamily` is the single switch.
- **Numbers are hero information.** `AppTypography.numeric(size)` → w800,
  tabular figures, negative tracking. Used for every Rp / % / score / kWh figure.

| Role | Size / weight | Use |
| --- | --- | --- |
| `displayLarge` / `displayMedium` | 44·800 / 34·800 | score, hero rupiah |
| `headlineMedium` | 24·700 | big amounts inside screens |
| `headlineSmall` | 21·700 | screen titles / greeting |
| `titleLarge` / `titleMedium` / `titleSmall` | 18·700 / 16·600 / 14·600 | headers, card titles, list titles |
| `bodyLarge` / `bodyMedium` / `bodySmall` | 15·400 / 14·400 / 12.5·400 | body (1.4–1.5 line height) |
| `labelLarge` / `labelMedium` / `labelSmall` | 15·600 / 12.5·600 / 11·600 | buttons, chips, captions |

- Support OS text scaling to ~1.3× (structural check in `responsiveness_test`).
- Never hardcode a `TextStyle`; use `Theme.of(context).textTheme` or
  `AppTypography.numeric`.

## 4. Spacing & layout

- **4 dp grid.** `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · lgPlus 18 · gutter 20 ·
  xl 24 · xxl 32 · xxxl 44`.
- Screen horizontal padding: `20`. Card padding: `AppSpacing.card` (18);
  hero-card padding: `AppSpacing.hero` (20). Card gap: `md`; section rhythm: `xl`.
- Min interactive target: **≥ 44 dp** (48 preferred).
- Scrollable body (`SingleChildScrollView` / `ListView`) inside `SafeArea`;
  a `ListView` body must use `AppScaffold(scrollable: false)`.
- **No `Row` of flexible text without `Expanded`/`Flexible`.**

## 5. Shape & elevation

| Token | Value | Use |
| --- | --- | --- |
| `AppRadius.sm` | 14 | inputs, tiles, chips-as-cards |
| `AppRadius.card` | 20 | standard cards |
| `AppRadius.lg` / `xl` | 26 / 32 | hero cards / sheets |
| `AppRadius.button` | 16 | buttons |
| `AppRadius.pill` | 999 | chips, status badges |
| `AppShadows.sm` / `md` / `lg` | soft green-tinted | resting card / hero / floating |
| `AppShadows.button` | coloured glow | under enabled `PrimaryButton` |

Cards carry a **soft shadow** (`AppShadows.sm`) + a barely-there
`outlineSubtle` border — not a hard hairline. Depth, not outline.

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
| `EmptyState` | `BrandArt` motif + title + body + optional CTA | `motif`, `title`, `message`, `action` |
| `ErrorStateView` | round danger badge + message + "Coba lagi" | `message`, `onRetry` |
| `LoadingState` | pulsing brand disc + optional label | `label` |

### v2 additions

| Component | Purpose | Key props |
| --- | --- | --- |
| `IbuDayaLogo` / `IbuDayaMark` | wordmark / symbol, code-drawn | `height`/`size`, `variant` (color/onDark/mono), `tagline` |
| `BrandArt` | editorial spot illustration | `motif` (community/solar/scan/inbox/success/finance/roof), `size`, `onDark` |
| `IbuClaraAvatar` / `MemberAvatar` | persona glyph / initials avatar | `size`, `ring` / `name` |
| `ScoreRing` | animated 0–max gauge with tabular centre value | `score`, `max`, `size`, `stroke`, `caption` |
| `StepDots` | numbered step header (1 · 2 · 3) | `labels`, `current` |
| `FeatureBadge` | rounded-square feature icon container | `icon`, `tone` (mint/solar/sky/forest), `size` |
| `StatTile` | label + hero number + optional delta / qualifier | `label`, `value`, `delta`, `qualifier`, `onDark` |
| `SectionCard` | soft-shadow card; header (leading icon + title + trailing) | `title`, `trailing`, `leadingIcon`, `tone` (plain/mint/solar/forest), `onTap` |
| `PrimaryButton` | filled CTA with glow + press-scale | `label`, `icon`, `loading`, `expand` |

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

- **One family, one style:** Material Symbols **rounded outline** — use the
  `Icons.*_rounded` / `Icons.*_outlined` variants consistently; never mix in a
  filled glyph next to an outline one.
- Feature / category icons are always wrapped in a `FeatureBadge` (rounded-square
  tinted container) so they read as one system.
- Size scale (`AppIconSize`): `sm 18` (inline) · `md 22` (default) · `lg 28`
  (tile) · `xl 40` (hero). Illustration-scale art uses `BrandArt`.

## 9. Content & number formatting

- Currency: `Rp` + thousands separator with `.` (`id_ID`): `Rp 245.000`. Helper
  in `core/format/money.dart`. Never format inline.
- Energy: `12 kWh`, `3,2 kWh` (comma decimal, `id_ID`).
- Percent: `45%` (no decimal unless needed).
- Dates: `id_ID` (`Jumat, 10 Mei`), slot labels `10.00–12.00` (en-dash, dots).
- Every estimated/simulated figure is followed by a `QualifierLabel`.
- Avoid ALL-CAPS words except short status pills.

## 10. Accessibility checklist (per screen)

- [ ] Interactive targets ≥ 44 dp (48 preferred).
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
