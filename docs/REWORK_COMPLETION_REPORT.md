# PlantDoc — Rework Completion Report

Companion to `REWORK_AUDIT.md`, `UI_REWORK_PLAN.md` and `BACKEND_REWORK_PLAN.md`.

---

## 0. Read this first — action required

**The Supabase service-role key was committed to this repository.**
`backend/.env.example` is a *tracked* file and contained real values for
`SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` and `SECRET_KEY`. It has been
in git history since commit `d1230ad` ("supabase initial setup") and is present
in `ed90dc0` and `45f4b82`.

The file has been sanitised to placeholders, but **that does not undo git
history**, and the repository is on GitHub. The service-role key bypasses every
row-level security policy on the project.

Required, by you, outside this repo:

1. Supabase dashboard → Project Settings → API → **roll the `service_role` key**
   (and the anon key while you are there).
2. Generate a new backend `SECRET_KEY` (`openssl rand -hex 32`) and put it in
   `backend/.env`, which is now git-ignored.
3. Optionally purge history with `git filter-repo`, but rotation is what
   actually protects you — assume the old key is compromised.

No other secret was found in tracked files. `flutter/.env` holds only
`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `API_BASE_URL`, all legitimately public
for a mobile client.

---

## 1. Summary of changes

This was a **bounded delta, not a rewrite**. The backend already had the
versioned API, Pydantic schemas, a singleton model service and Alembic that the
brief asked for; the Flutter app already had design tokens, a component layer
and Provider state. The work went into the gaps those layers left:

| Theme | What changed |
|---|---|
| Visual system | Dark glassmorphism → light botanical, contrast-verified |
| Scan | Static image picker → live camera viewfinder with a real analysing state |
| Result | One flattened card → three distinct outcomes with full disease information |
| Offline | **Fixed a real bug** — signed-in users lost their history without a network |
| Backend | Structured detection response, error codes, real health probe, dedup, upload hygiene |
| Security | Leaked secrets sanitised, CORS fixed, `.gitignore` written, secret validation |
| Tests | 3 → 61 (15 backend, 46 Flutter; Flutter had no test directory at all) |

---

## 2. UI changes

### Design system

Grounded in the "Organic Biophilic" style profile and the "Geometric Modern"
type pairing, then adjusted for the reference image and for contrast.

- **Palette flipped** from `#0A1410` + neon lime `#A3E635` to ivory `#F5F7EF` +
  sage. Token *names* were preserved, so all 49 files re-skinned without
  call-site churn.
- **Every colour pair was measured, not eyeballed.** The first pass failed WCAG
  AA in six places — including white-on-primary at 3.1:1 on the app's main CTA.
  The palette was darkened until all 18 measured pairs pass:

  | Token | First pass | Shipped | White/BG contrast |
  |---|---|---|---|
  | `primary` | `#7C9A70` | `#5C7852` | 3.13 → **4.93** |
  | `muted` | `#6F786F` | `#5F685F` | 4.23 → **5.35** |
  | `success` | `#4F8A5B` | `#40734A` | 4.10 → **5.57** |
  | `warning` | `#C08A3E` | `#946627` | 3.02 → **5.01** |
  | `error` | `#C1553F` | `#B04A35` | 4.53 → **5.42** |
  | `border` | `#DCE3D8` | `#C9D4C2` | 1.31 → 1.54 (separation) |

  The brief's suggested `#8EAD82` is 2.2:1 against white and could not carry the
  button label it was meant for. Documented deviation.
- **Typography:** Outfit (headings) + Inter (body), via the existing
  `google_fonts`. The recommended pairing was Outfit + Work Sans; Inter was kept
  for body as it was already bundled and is equally legible, saving a font
  download. Smallest text raised 11px → 12px.
- **Glassmorphism removed.** `GlassSurface` was a `BackdropFilter` on every card
  and every list row. It now renders a flat surface, hairline border and soft
  shadow — same class, same constructor, no call-site changes, one fewer render
  layer per row.
- **New token file** `app_shadows.dart` (none / soft / lifted). Spacing gained
  `xl`/`xxl`; radii grew to 12/16/20/28/pill for the "large rounded cards" the
  direction calls for.

### Navigation

Tabs were four separate routes swapped with `pushReplacementNamed` — rebuilding
each screen on every switch, losing scroll position, re-fetching history, and
leaving the back button with nothing sensible to do. They now live in one
`MainShell` over an `IndexedStack`, with `PopScope` so back returns to Home from
a deep tab rather than exiting the app.

Scan stays a raised centre action rather than a fifth flat tab — that emphasis
is what §4 asks for and what the reference shows. Its hit-test bug is fixed: the
button used to overhang its `Stack`, so its top edge was drawn but not tappable.

### Screens

- **Home** — time-aware greeting (was hardcoded "Good morning" at any hour),
  avatar with initial fallback, botanical hero card, AI scan card, plant grid,
  recent diagnoses. Every section degrades to a designed empty state; the whole
  screen renders with no history, no plants, no network and no profile image.
- **Scan** — live `CameraPreview` with a painted corner-bracket frame, gallery
  and flash controls, explicit Retake / Use-this-photo confirmation (never
  auto-uploads), and a full-bleed analysing overlay with a sweeping scan line.
  Handles permission denial, no camera, init failure, picker failure, invalid
  image, timeout and backend outage — each with its own copy, and the camera is
  released and rebuilt across lifecycle changes.
- **Result** — three genuinely different screens:
  1. **Diseased**: header card, overview, symptoms, numbered treatment,
     prevention, risk level, other possible matches, disclaimer, actions.
  2. **Healthy**: its own green panel, "keep it that way" advice, next-check
     date. Not a disease card that happens to say "Healthy".
  3. **Unidentified**: `Background_without_leaves` never reaches the user as a
     string. Shows "We couldn't identify a plant leaf", four photo tips and a
     Scan-again CTA — and no confidence bar, because "97% sure there is no leaf"
     helps nobody. Not saved to history.
- **History** — search plus All/Healthy/Diseased filters over the in-memory
  local list, so both work offline. `ListView.builder` rows with thumbnail,
  disease, plant, confidence and relative time.
- **Plants / Profile / Welcome / Register** — restyled to the new system.
  Tracker behaviour, sqflite storage and reminders are untouched.

### Accessibility and layout

Run against the skill's pre-delivery checklist:

- All 18 measured colour pairs pass AA (above).
- Touch targets ≥44dp; history filter chips raised 40 → 48dp for Android.
- `Semantics` labels and tooltips on every icon-only control; `AppIconButton`
  now *requires* a `semanticLabel`.
- Status is never colour-only — badges and the risk bar state it in words.
- Reduced motion respected: the scan sweep and skeleton shimmer both check
  `MediaQuery.disableAnimationsOf`.
- Bottom-nav clearance now includes the device's bottom safe-area inset; it was
  a fixed 104dp against a bar that is ~102dp **plus** the inset, so the last row
  hid behind the bar on gesture-navigation phones.
- Nav labels capped at 1.2× text scale (fixed-height chrome only; page content
  scales freely) with ellipsis.
- Autofill hints on login and registration so password managers work.
- Result screen's fixed `Expanded(flex: 4/5)` split replaced with one scroll
  view — it overflowed on short screens.
- 14 widget tests assert no overflow at 320px, 375px and 2× text scale.

**Single theme by design.** The app ships light-only (`darkTheme` aliases
`lightTheme`), so the system dark setting cannot produce an untested surface.
A real dark palette is a follow-up, not a half-applied one.

---

## 3. Backend changes

- **Deduplicated `/detect` and `/predict`** — ~50 duplicated lines each became
  one `_run_detection` + `_persist_detection`. One inference path, one
  persistence path; the routes differ only in serialisation.
- **Structured response**: `alternatives` (top-k minus the winner, capped at 4),
  `information`, `metadata` (`model_version`, `processing_time_ms`), and
  `risk_level` / `symptoms` / `is_identifiable` on the prediction.
- **Knowledge base rebuilt**: per-disease `symptoms` and a static `risk_level`
  for all 13 diseases, plus disease-specific treatment and prevention where the
  generic list was wrong (a virus cannot be cured by a fungicide). `risk_level`
  is deliberately independent of confidence.
- **Error codes**: `AppException.error_code` plus one `error_envelope()`. Six
  near-identical handlers became five that share it. Top-level `message` kept so
  older clients keep working.
- **`/health`** reports `model_loaded`, `model_version`, `classes` and a
  `SELECT 1` database probe; degrades to `"degraded"` but still returns 200 so
  the probe is not mistaken for an outage. Also mounted under `/api/v1`.
- **Upload hygiene**: anonymous scans no longer touch the disk at all; files are
  written only when persisted for a user, and the extension comes from the
  *decoded* format, never the client's filename. Added dimension bounds and a
  decompression-bomb guard.
- **Dead code removed**: the server-side Supabase mirror in the detect routes.
  It could never run (see §6) and duplicated what the client already writes.
- `print()` → `logger`; function-local imports hoisted.

**ML pipeline untouched**, as required: same `.keras` file, same 20 classes in
the same order, same 224×224 MobileNetV2 preprocessing, same single load at
startup. `test_class_names_and_order_are_unchanged` now pins the class list so
reordering it becomes a test failure instead of silent mislabelling.

---

## 4. API changes

| Endpoint | Change |
|---|---|
| `GET /health` | Expanded payload; also mounted at `/api/v1/health` |
| `POST /api/v1/detect` | Gains `alternatives`, `information`, `metadata`, `risk_level`, `symptoms`, `is_identifiable`, `top_k` |
| `POST /predict` | Response shape unchanged; marked `deprecated` in OpenAPI |
| all | Errors gain `error.code`; `message` retained for compatibility |

Flutter now calls `/api/v1/detect`. `/predict` stays for older installs; the
typed Dart model parses both.

**Breaking change:** `test_health.py` asserted exact equality with
`{"status": "healthy"}` and was updated. No client-visible break — the legacy
endpoint and the legacy error field are both intact.

---

## 5. Database changes

**None.** The existing schema was inspected and is sound: five tables, cascade
deletes matching between ORM and DDL, `user_id` indexed on `detections` and
`favorites`. No migration was needed, so none was written.

One thing recorded rather than changed: `main.py` calls `create_all()` at
startup *and* Alembic manages the same schema. Harmless for SQLite development
and relied on by the Windows dev scripts; production should run
`alembic upgrade head`. Documented in `backend/README.md`.

---

## 6. Authentication changes

**No behaviour changed. A dead integration was documented.**

Flutter authenticates against Supabase and sends its *Supabase* JWT to a backend
that validates with its own `SECRET_KEY` (`security.py:decode_token`). Those can
never match, so `OptionalUser` is **always `None`** for the real client — the
`if current_user:` branch in both detect routes never executed in production.
Flutter also never calls `/api/v1/auth/*` (verified: zero call sites).

Decision, per §16's instruction to document rather than guess:

1. **Kept** Supabase auth in Flutter — it works and owns session and history.
2. **Kept** the backend's own JWT auth — it is tested and is the credential
   scheme for `/api/v1` history, plants and favorites.
3. **Removed** only the unreachable Supabase mirror inside the detect routes,
   which also took `SUPABASE_SERVICE_ROLE_KEY` out of the request path.
4. **Did not** bridge Supabase JWTs into the backend. That needs JWKS fetching,
   caching and rotation to validate a token nothing currently needs. It is a
   deliberate non-goal, not an oversight.

---

## 7. ML changes

**None.** Model file, class order, preprocessing and input size are all
byte-identical. The only additions are a `model_version` label and inference
timing, both outside the prediction path.

Verified end to end: model loads at startup, `/health` reports
`model_loaded: true` with 20 classes, and a flat non-leaf image correctly
returns `is_identifiable: false` with `class_label: Background_without_leaves`.

---

## 8. Files created

**Docs:** `docs/REWORK_AUDIT.md`, `docs/UI_REWORK_PLAN.md`,
`docs/BACKEND_REWORK_PLAN.md`, `docs/REWORK_COMPLETION_REPORT.md`,
`backend/README.md` (rewritten).

**Flutter:** `core/theme/app_shadows.dart`, `core/navigation/main_shell.dart`,
`core/widgets/state_views.dart`, `core/widgets/diagnosis_widgets.dart`,
`core/widgets/scan_frame_overlay.dart`, `core/utils/formatting.dart`,
`core/services/api_error.dart`, `core/services/image_validation.dart`,
`data/models/detection_result.dart`,
`test/{detection_result,formatting,api_error,layout}_test.dart`.

**Backend:** `tests/test_detect.py`, `tests/test_metadata.py`.

**Root:** `.gitignore` (was one line).

## 9. Files modified

**Flutter:** all five theme files; `main.dart`; `app_navigator.dart`;
`app_shell.dart`, `bottom_nav.dart`, `glass_surface.dart`, `app_card.dart`,
`app_icon_button.dart`, `scan_activity_tile.dart`; all nine screens;
`api_service.dart`, `scan_storage.dart`, `scan_history_service.dart`,
`auth_service.dart`, `supabase_service.dart`; `app_assets.dart`,
`app_stats.dart`; `home_batch_tile.dart`; `pubspec.yaml`.

**Backend:** `main.py`, `core/config.py`, `core/exceptions.py`,
`data/disease_metadata.py`, `schemas/detection.py`, `schemas/common.py`,
`services/disease_detection.py`, `api/routes/detect.py`, `api/routes/health.py`,
`utils/image.py`, `tests/test_health.py`, `.env.example` (**sanitised**).

## 10. Files removed

`core/widgets/glass_card.dart` (three aliases of `AppCard`; one silently
discarded its `accentColor`), `page_background.dart`, `crop_grid_tile.dart`,
`highlight_chip.dart`, `stat_widgets.dart`, `progress_widgets.dart` — each
verified to have zero call sites before deletion.

Also removed: six unused methods on `ScanHistoryService` (including an
`exportAsJson` that built JSON by string concatenation and broke on any quote),
two unused `ApiService` methods, and a dead `_tokenKey` field.

## 11. Dependencies

**Removed** (all verified unused): `fl_chart`, `percent_indicator`,
`flutter_svg`, `cached_network_image`.

**Added:** none. `camera` was already declared but never imported — the new
viewfinder uses what was already there.

---

## 12. Tests performed

| Suite | Before | After | Result |
|---|---|---|---|
| Backend `pytest` | 3 | 15 | pass |
| Flutter `flutter test` | **0** (no test dir) | 46 | pass |
| `flutter analyze` | 8 issues | 0 | clean |
| `flutter build apk --debug` | — | — | builds |

Backend: health payload and no-secret-leakage, auth round trip, detect response
shape, legacy shape stability, invalid/tiny/oversized upload rejection with the
right codes, anonymous uploads not written to disk, class-order pin, metadata
completeness for all 20 classes.

Flutter: confidence normalisation, response parsing for both API shapes, no-leaf
handling, error-code mapping (including "no raw exception ever reaches a user"),
greeting and relative-time formatting, and layout at 320/375px and 2× text scale.

**Verified by execution:** backend boots, model loads, `/health` is healthy,
`/api/v1/detect` and `/predict` both return 200 against the real model, and a
non-leaf image is correctly classified as unidentifiable.

**Not verified — needs a device.** Everything below is reasoned-and-compiled,
not observed: camera capture and flash, gallery picking, permission denial,
notification reminders, Supabase login/registration/logout against the live
project, and cloud history sync. Run through §14 before the demo.

---

## 13. Remaining issues

1. **Rotate the leaked Supabase keys** (§0). Highest priority; outside the repo.
2. **Backend JWT auth is unreachable from the app** (§6). Detection works;
   backend-side per-user history does not. Documented, not bridged.
3. **No dark theme.** Light-only by choice; `darkTheme` aliases `lightTheme`.
4. **Device paths untested** (§12).
5. `usesCleartextTraffic="true"` in the Android manifest — needed for local HTTP
   development, should be removed for a release build over HTTPS.
6. **The disease knowledge base is hand-written** and not agronomically
   reviewed. The result screen carries a disclaimer, but a domain expert should
   read `backend/app/data/disease_metadata.py` before this advises real farmers.
7. `flutter/.env` is committed. Fine (public values only), but it means the API
   URL is baked into the repo rather than the build.

---

## 14. How to run

### Backend

```bash
cd backend
py -3.11 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Check <http://localhost:8000/health> shows `"model_loaded": true` before
scanning. API docs at `/docs`. From the repo root, `.\scripts\backend.ps1` does
the same. Tests: `.venv\Scripts\python -m pytest -q`.

### App

```bash
cd flutter
flutter pub get
flutter run
```

Point the app at the backend via `flutter/.env`:

- USB debugging: `API_BASE_URL=http://127.0.0.1:8000` plus
  `adb reverse tcp:8000 tcp:8000`
- Same Wi-Fi: `API_BASE_URL=http://<your-pc-ip>:8000`
- Deployed: the HTTPS URL

Tests: `flutter test`. Analyzer: `flutter analyze`.

### APK

```bash
cd flutter
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Split per ABI with
`--split-per-abi` for a smaller download. The `--dart-define` overrides `.env`,
so a release build need not ship the development URL.

### Manual demo checklist

Launch → register → home → scan (camera) → scan (gallery) → diseased result →
healthy result → non-leaf result → history search and filter → add a plant →
plant detail → reminder → profile → logout → airplane mode (home, history and
plants still load; scan shows a readable message) → backend stopped (scan shows
a readable message, nothing crashes).
