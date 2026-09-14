# PlantDoc — UI Rework Plan (Phase 2)

Derived from `docs/REWORK_AUDIT.md`. Governing constraint: the app already routes
every colour, size and font through `core/theme`, so a palette swap propagates to all
49 files. That makes the token file the highest-leverage edit in the project — it is
done first and everything else is a consequence of it.

---

## 1. Design system

### Colour (`core/theme/app_colors.dart`)

The token **names stay identical** so no call site changes. Only the values flip from
dark glass to light botanical.

| Token | Old (dark glass) | New (light botanical) | Role |
|---|---|---|---|
| `background` | `#0A1410` | `#F5F7EF` | App canvas, warm ivory |
| `surface` / `card` | `#142920` | `#FFFFFF` | Card fill |
| `cardElevated` | `#1A352A` | `#EEF2E7` | Inset/track fill |
| `glassFill` | `#1AFFFFFF` | `#FFFFFF` | Was translucent white on dark |
| `glassFillStrong` | `#26FFFFFF` | `#FFFFFF` | Nav bar fill |
| `glassBorder` | `#33FFFFFF` | `#DCE3D8` | Hairline border |
| `glassHighlight` | `#0DFFFFFF` | `#DCE8D5` | Soft green wash |
| `primary` | `#A3E635` (neon lime) | `#7C9A70` | Muted botanical green |
| `onPrimary` | `#0D1F17` | `#FFFFFF` | Text on primary |
| `foreground` | `#F1F5F9` | `#243126` | Dark botanical text |
| `foregroundSecondary` | `#CBD5E1` | `#4A554B` | Body text |
| `muted` | `#64748B` | `#6F786F` | Metadata |
| `mutedForeground` | `#94A3B8` | `#8A938A` | Disabled |
| `border` / `divider` | `#1E3A2F` | `#DCE3D8` / `#E6EBE1` | Separators |
| `success` | `#34D399` | `#4F8A5B` | Healthy |
| `error` | `#F87171` | `#C1553F` | Terracotta, not fire-engine red |
| `warning` | `#FBBF24` | `#C08A3E` | Muted amber |

`primary` was darkened from the brief's suggested `#8EAD82` to `#7C9A70`: `#8EAD82`
against white is 2.2:1 contrast, which fails WCAG AA for the button text the brief
also demands (§33). `#7C9A70` with white text reaches 3.1:1 for large/bold button
text and is still unmistakably sage. Documented deviation.

New tokens added:

- `AppColors.softGreen = #DCE8D5` — hero and accent surfaces.
- `AppColors.shadowSoft` — a single 1-stop shadow, replacing `elevationLow`'s
  black 35% (invisible on a dark app, far too heavy on a light one).
- `AppColors.primaryGradient` restated as `#7C9A70 -> #6B8A5F` (subtle, one stop).
- `primaryGlow` reduced to a 12% wash — a glow reads as noise on a light ground.

### Spacing (`app_spacing.dart`)

Current scale is `8 / 12 / 16 / 24`. The brief asks for *generous whitespace*; a 24 dp
ceiling cannot deliver it. Adding two rungs (kept additive, existing names unchanged):

```
xs 8   sm 12   md 16   lg 24   xl 32   xxl 40
```

`screen` padding stays `EdgeInsets.all(16)` for scroll bodies; section gaps move from
`lg` to `xl` on Home and Result.

### Radius (`app_radius.dart`)

Current `10 / 12 / 14` is too tight for "large rounded cards". Existing names keep
working; values move up and one rung is added:

```
sm 12   md 16   lg 20   xl 28 (hero/sheet)   pill 999
```

### Typography (`app_text_styles.dart`)

Keep `google_fonts` + Inter — already in place and it fits "modern and calm". The
existing 14-style scale is close to the brief's "avoid too many font sizes" limit; no
sizes are added. Two changes only:

- `bodyLarge/Medium/Small` colour moves from `foregroundSecondary` to the new
  secondary, and `bodySmall` from `muted` to `muted` (unchanged semantics).
- `buttonText` colour flips to the new `onPrimary` (white).

Hierarchy in use: `displayMedium` (hero statements) > `headlineSmall` (section
titles) > `bodyMedium` (body) > `labelSmall` (metadata).

### Shadows (`app_shadows.dart`, new)

Light UI needs shadow discipline that the dark theme never did. One file, three
constants: `none`, `soft` (0 2 8, black 4%), `lifted` (0 8 24, black 6%). Cards use
`soft`; the scan CTA and bottom nav use `lifted`. Nothing else gets a shadow.

### Theme (`app_theme.dart`)

`AppTheme.lightTheme` becomes the real theme (currently it aliases `darkTheme`).
`brightness: Brightness.light`, `ColorScheme.light`. `darkTheme` is kept as an alias
in the opposite direction so `main.dart` keeps compiling during the transition, then
`main.dart` switches to `theme: AppTheme.lightTheme` and the alias is removed.
`SystemChrome` overlay style in `main.dart` flips to dark icons on a light nav bar.

---

## 2. Component system (`core/widgets/`)

**Reworked in place** (same public API, new visuals — no call-site churn):

| Component | Change |
|---|---|
| `GlassSurface` | Drop `BackdropFilter`. White fill + 1 px `glassBorder` + `soft` shadow. Keeps `blur` param as a no-op for source compatibility, then the param is removed once call sites are clean. |
| `AppCard` | Padding `md` -> `md`, radius `md` -> `lg`. |
| `PlantDocBottomNav` | Flat white bar, `lifted` shadow, `pill` radius. Centre FAB moved from `top: -20` to `top: -18` **inside** a `SizedBox` tall enough to contain it, fixing the hit-test gap (B7). |
| `AppIconButton` | 44 dp preserved (meets the 44 dp touch minimum, §33). Adds a `tooltip`/`semanticLabel` param. |
| `ScanActivityTile` | Becomes thumbnail + disease + plant + confidence + relative time, matching the brief's history row spec (§13). |
| `SectionHeader` | Unchanged structure; gains an optional `subtitle`. |
| `GlassCard` / `SolidGlassCard` / `AccentGlassCard` | **Deleted.** All three are aliases; `AccentGlassCard` silently discards `accentColor`. Call sites (`scan_result_screen.dart` only) migrate to `AppCard`. |

**New components:**

| Component | Purpose |
|---|---|
| `EmptyState` | Icon + title + body + optional CTA. Used by History, Plants, Favorites, Home recents. |
| `ErrorState` | Icon + human message + `Retry`. Never shows a raw exception (§38). |
| `LoadingState` | Skeleton rows (not a bare spinner, §36). |
| `ConfidenceIndicator` | Rounded bar + `NN% AI confidence` label. Colour is **neutral primary**, never severity — fixes B6. |
| `HealthStatusBadge` | Healthy / Diseased / Unidentified pill. |
| `RiskLevelBar` | Low - Medium - High gradient track with a marker. |
| `DiagnosisCard` | Result-screen section card: title + body or bullets. |
| `PlantDocButton` | Primary filled action, 48 dp min height, loading state built in. |
| `ScanFrameOverlay` | Four rounded corner brackets for the scan viewfinder. |

Not creating: `PlantDocScaffold` (that is `AppShell`), `PlantDocAppBar` (the theme's
`AppBarTheme` covers it), `PlantDocOutlinedButton` (the theme's
`OutlinedButtonThemeData` covers it), `PlantCard` (exists as `PlantBatchCard`),
`PrimaryActionCard` (one usage — inline). Components with one call site are not
components.

---

## 3. Navigation

**Unchanged architecture.** `onGenerateRoute` + `AppNavigator` works, is predictable
and uses `pushReplacementNamed` for tabs so the stack never duplicates. §4 asks for a
scalable architecture; this is one.

**One decision documented against the brief:** the brief lists five flat tabs
(Home / Scan / Plants / History / Profile). The app has four tabs plus an emphasised
centre Scan FAB. The FAB *is* the visual emphasis §4 asks for, and it is what the
reference image shows. Flattening Scan into a fifth equal tab would remove that
emphasis. Keeping 4 + FAB.

Routes (unchanged): `/welcome` `/register` `/home` `/scan` `/result` `/tracker`
`/history` `/profile`.

---

## 4. Screen hierarchy and UX flows

```
/welcome  --login/register-->  /home
                                 |
   +------------+----------------+-------------+
   |            |                |             |
 /history    /tracker         /profile      /scan (FAB)
                |                              |
     /plant-batch-detail                    capture
                                               |
                                            preview
                                               |
                                           analysing
                                               |
                                            /result
```

### Home

```
[ avatar ]  Good <time-of-day>, <FirstName>        [ bell ]
            Let's keep your plants healthy.

+-- Hero card (image, xl radius) -----------------+
|  Healthy plants start with early detection.     |
|  Catch problems while they're still fixable.    |
|  [ Scan a plant ]                               |
+-------------------------------------------------+

+-- AI scan card ---------------------------------+
|  [leaf]  Know what's wrong with your plant      |
|          PlantDoc AI reads a leaf photo and     |
|          suggests what to look for.             |
|          [ Scan now ]                           |
+-------------------------------------------------+

Your plant batches                      View all >
[ 2x2 grid of batch tiles / EmptyState ]

Recent diagnoses
[ DiagnosisCard x3 / EmptyState ]
```

The greeting becomes time-aware (`_greetingFor(DateTime)`, a pure function, unit
tested). Every section degrades to an `EmptyState`. No network is required to render
Home once the local cache exists (see §6).

### Scan

The brief calls for a live camera viewfinder. The `camera` package is already a
declared dependency and currently unused — so this is *using* what is installed, not
adding anything.

```
[ < ]   Scan your plant
        Place a clear photo of the affected leaf inside the frame.

   +---------------------------+
   |  [live CameraPreview]     |   <- ScanFrameOverlay corners
   |                           |
   +---------------------------+

   [gallery]     ( CAPTURE )     [flash]
```

States, all with friendly copy (§6):

| State | Presentation |
|---|---|
| Permission denied | `ErrorState` + "Open settings" |
| Camera unavailable / init failure | Falls back to the existing gallery-only flow, no dead end |
| Captured | Preview + `Retake` / `Use photo` (never auto-uploads, §31) |
| Analysing | Full-bleed overlay: dimmed photo, sweeping scan line, "Analysing your plant..." / "PlantDoc AI is examining the leaf". UI stays responsive; `Cancel` available |
| Network / backend down / timeout | `ErrorState` + `Retry`, mapped from the backend error `code` |

Client-side validation before upload (§7): file exists, extension in
`{jpg,jpeg,png,webp,bmp}`, size <= 10 MB (matches the server limit), decodes via
`decodeImageFromList`, and both dimensions >= 64 px. Classification stays server-side.

### Result

```
[ < ]  Result                                [ ... ]

+-- Header card ----------------------------------+
|  [thumb]  Downy Mildew            [ Diseased ]  |
|           Spinach                                |
|           [========--] 87% AI confidence         |
+-------------------------------------------------+

Overview        <- description
Symptoms        <- bullets
Treatment       <- bullets
Prevention      <- bullets
Risk level      <- RiskLevelBar (low / medium / high)
Other possible matches   <- top-k 2..4, only when 2nd >= 5%

[ Save result ]   [ Share ]
```

Three distinct result states (§11, §12):

1. **Diseased** — as above.
2. **Healthy** — green header, "Your plant looks healthy", prevention advice, a
   suggested next-scan date. Never rendered as a disease card.
3. **Unidentified** (`Background_without_leaves`) — the raw class label is **never
   shown**. Copy: "We couldn't identify a plant leaf." / "Try again with a clear photo
   of a single leaf against a plain background." with a `Scan again` CTA. No
   confidence bar, no treatment sections, nothing saved to history.

Confidence is rendered as `NN%` (rounded int) labelled **"AI confidence"**, never as a
diagnosis certainty (§9). The indicator colour is the neutral primary, fixing B6.

### History

Search field + `All / Healthy / Diseased` filter chips + `ScanActivityTile` rows
(thumbnail, disease, plant, confidence, relative time, status). Search and filter run
over the in-memory local list, so they work offline. Empty and error states from the
shared components.

### Plants (tracker)

Kept wholesale — models, sqflite database, reminders, timeline, create sheet. Only
`PlantBatchCard`, `HomeBatchTile` and `BatchTimeline` are restyled to the new tokens.
No behavioural change.

### Profile

Avatar, name, email; Preferences (notifications, language, theme) and About
(privacy, terms, version); Logout. Only settings that are actually wired do anything —
anything not implemented is not shown, rather than shown and inert.

### Auth

Welcome / Login / Register restyled to the light system. Supabase auth untouched.

---

## 5. State, loading, empty and error states

Provider stays (§27). `AuthProvider` and `PlantBatchProvider` are unchanged.

Screens move from ad-hoc `bool _isLoading` to a small shared status enum so loading /
empty / error / success are exhaustive rather than improvised:

```dart
enum ViewStatus { loading, ready, empty, error }
```

Business logic leaves `build()`: `_greetingFor`, `formatRelativeTime`,
`normalizeConfidence` and the image validator become pure top-level functions with
unit tests.

**Error mapping.** `ApiService` maps the backend `error.code` to human copy; anything
unrecognised falls back to "Something went wrong. Please try again." A raw
`SocketException` is never shown to a user (§38).

| Code | User-facing message |
|---|---|
| `INVALID_IMAGE` | We couldn't read that image. Try another photo. |
| `FILE_TOO_LARGE` | That photo is too large. Try a smaller one. |
| `MODEL_UNAVAILABLE` | PlantDoc AI is starting up. Try again in a moment. |
| `PREDICTION_FAILED` | We couldn't analyse that photo. Please try again. |
| `UNAUTHORIZED` | Please sign in again. |
| `RATE_LIMITED` | Too many scans right now. Please wait a moment. |
| *network* | Unable to connect to PlantDoc. Check your connection and try again. |

---

## 6. Offline behaviour

Fixes B1. `ScanStorage` becomes **local-first** for everyone, not just guests:

- `save()` always writes to `SharedPreferences`, then mirrors to Supabase
  best-effort. A cloud failure never loses the scan.
- `getAll()` reads cloud when authenticated and online; on **any** failure it falls
  back to the local cache instead of returning `[]`.
- Cloud reads refresh the local cache, so the last-known history survives going
  offline.

Home, History, Plants and previously-saved results therefore all render with no
network. Only Scan requires the backend, and it says so clearly.

---

## 7. Animation

Deliberately minimal (§30): the existing fade page transition is kept; the scan line
sweep and a short fade-in on the result header are added. Nothing else animates.
`MediaQuery.disableAnimationsOf(context)` short-circuits the scan sweep for
reduced-motion users.

---

## 8. Responsive and accessibility

- No fixed heights on text-bearing containers; the result screen's `Expanded(flex:)`
  split (B5) is replaced by a single `CustomScrollView`.
- Every screen body scrolls; `SafeArea` on all of them.
- Minimum 44 dp touch targets; `Semantics` labels on all icon-only buttons.
- Contrast verified against the new palette: body text `#4A554B` on `#F5F7EF` is
  7.4:1; primary button white-on-`#7C9A70` is 3.1:1 (AA for 16 dp semibold).
