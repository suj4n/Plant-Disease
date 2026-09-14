# PlantDoc — Rework Audit (Phase 1)

Audited commit: `37da0d2`. Working tree clean at audit time.

## TL;DR

The repository is **in far better shape than the rework brief assumes**. The FastAPI
backend already has the versioned `/api/v1` router, Pydantic schemas, a singleton
model service loaded once at startup, Alembic migrations and a centralised exception
handler. The Flutter app already has `core/theme` design tokens, a component layer
(`core/widgets`), a navigation helper and Provider state.

So this is **not a rewrite**. It is a bounded delta:

| Area | Status |
|---|---|
| Backend architecture (§17, §18, §21, §23) | Already done |
| Backend response shape (§19), health (§22), error codes (§25) | Gaps |
| Design tokens exist (§2) | Wrong palette — app is **dark glass**, brief wants **light sage** |
| Scan UX (§6, §31) | Weakest screen — no camera preview, no analysing state |
| Result UX (§8–§12) | Weak — no symptoms/prevention/risk/top-k/healthy/no-leaf states |
| Offline history (§24, §35) | **Broken** — real bug, see B1 |
| Tests (§41) | No Flutter test directory at all |

---

## 1. Current architecture

### Flutter (`flutter/lib`, 6,812 LOC, 49 files)

```
main.dart                     MultiProvider + MaterialApp(onGenerateRoute)
core/theme/                   AppColors, AppSpacing, AppRadius, AppTextStyles, AppTheme
core/widgets/                 GlassSurface, AppCard, AppShell, PlantDocBottomNav, ...
core/navigation/              AppNavigator (index -> route), AppPageRoute (fade)
core/providers/               AuthProvider (ChangeNotifier)
core/services/                ApiService, AuthService, SupabaseService,
                              ScanStorage, ScanHistoryService, UserDataSync
features/plant_tracker/       models / providers / services (sqflite) / widgets
screens/                      9 flat screen files
```

Routing is `onGenerateRoute` over named routes with `pushReplacementNamed` for tabs.
Bottom nav is 4 tabs plus a centre scan FAB (Home / History / Plants / Profile).

### Backend (`backend/app`, 1,985 LOC)

```
main.py                       create_app(), lifespan(load model + seed), 6 exception handlers
core/config.py                pydantic-settings Settings, @lru_cache get_settings()
api/routes/                   health, auth, detect (+ legacy /predict), diseases,
                              favorites, history, plants  -> api_router @ /api/v1
services/disease_detection.py Singleton DiseaseDetectionService: load() once, preprocess,
                              predict(top_k), to_legacy_response()
services/supabase_service.py  Optional server-side Supabase (service-role key)
data/disease_metadata.py      Static knowledge base keyed by class label
models/ schemas/              SQLAlchemy + Pydantic, 5 tables
alembic/versions/001_...      Initial schema
tests/                        conftest, test_health, test_auth (3 tests)
```

### ML pipeline (verified, **not to be touched**)

- `model/plant_best_model.keras`, 60 MB, loaded once in `lifespan` via
  `load_model(..., compile=False)`.
- `Resources/class_names.json`, 20 labels, order preserved and indexed directly.
- Preprocess: `cv2.resize(224, 224, INTER_AREA)` -> `float32` ->
  `mobilenet_v2.preprocess_input`.
- Output: softmax over 20 classes, `argsort[::-1][:top_k]`.

This is correct and matches the brief's constraints. **No change planned.**

---

## 2. Problems found

### Bugs (correctness)

**B1 — Offline history is broken for signed-in users.** `ScanStorage.getAll()`
(`core/services/scan_storage.dart:20`) routes to Supabase whenever authenticated and
returns `[]` on *any* exception. With no network a logged-in user sees an empty
history and an empty home screen. `save()` likewise throws into the void. There is no
local cache for authenticated users — only for guests. Directly contradicts §24/§35.

**B2 — CORS `allow_origins=["*"]` with `allow_credentials=True`.** `main.py:60`.
Browsers reject this combination outright; the wildcard is ignored when credentials
are on. Broken for any web client, and wide open by intent (§39).

**B3 — Uploaded images are stored permanently and never cleaned up.**
`detect.py:54` and `detect.py:112` write every upload to `backend/uploads/` and keep
it forever, even for anonymous requests that are never recorded. Unbounded disk
growth; contradicts §20. `backend/uploads/` is also not git-ignored.

**B4 — `.gitignore` contains one line (`notuseful.txt`).** `backend/.env` is not
ignored — the next person to create one commits their service-role key. `uploads/`,
`__pycache__/`, `*.db` likewise unignored. (Build artefacts happen not to be tracked
today; that is luck, not configuration.)

**B5 — Result screen can overflow.** `scan_result_screen.dart` splits the viewport
with `Expanded(flex: 4)` / `Expanded(flex: 5)` and draws fixed 160/200/240 px
concentric rings inside the flex-4 region. On a small phone (<= 640 dp tall) the rings
exceed their box.

**B6 — `_confidenceBarColor` is inverted.** `scan_result_screen.dart:51`: high
confidence -> coral (red), low -> emerald (green). For a *healthy* result, 95%
confidence renders red. The colour encodes "disease severity" using a variable that
means "model certainty".

### Duplication / dead code

**D1 — `/detect` and `/predict` duplicate ~50 lines each** of upload -> save file ->
persist SQLite -> mirror to Supabase (`detect.py`). §18 explicitly forbids two
implementations. The *inference* is shared; the *persistence* is copy-pasted.

**D2 — `ScanHistoryService` is a pass-through wrapper over `SupabaseService`** with
six methods nobody calls (`getStatistics`, `searchByDisease`, `getRecentScans`,
`exportAsJson`, `getScanCount`, `getScan`). `exportAsJson` builds JSON by string
concatenation — it produces invalid JSON for any disease name containing a quote.

**D3 — `GlassCard` / `SolidGlassCard` / `AccentGlassCard`** are all aliases of
`AppCard`; `AccentGlassCard` accepts `accentColor` and discards it.

**D4 — `ApiService` has two near-identical methods** (`analyzePlant`, `detectPlant`)
differing only in path. Only `analyzePlant` (legacy `/predict`) is ever called.

**D5 — `AppTheme.lightTheme => darkTheme`.** Placeholder.

**D6 — `configure()` dead branch:** `_baseUrl = kDebugMode ? usbBaseUrl : usbBaseUrl`.

### Unused dependencies

- `camera: ^0.12.0+1` — declared, never imported. The scan screen uses `image_picker`.
- `fl_chart`, `percent_indicator`, `flutter_svg`, `cached_network_image`,
  `flutter_animate` — need per-file verification before removal (see plan).

### UI problems

1. **Palette is the opposite of the brief.** Current: `background #0A1410` (near
   black), accent `#A3E635` (neon lime) — precisely the "overly saturated / neon" the
   brief rules out. Target is light sage/ivory.
2. **Glassmorphism is used everywhere** (`GlassSurface` = `BackdropFilter` blur 12 on
   every card). Brief: "avoid excessive glassmorphism". Also a real perf cost —
   one `BackdropFilter` per list row.
3. **Scan screen has no scanner.** Static `AppCard` preview, two outlined buttons and
   an `ElevatedButton`. No camera feed, no frame overlay, no analysing state; the
   loading state is a 20 px spinner inside a button.
4. **Result screen drops most of the payload.** The backend returns `description`,
   `treatment`, `prevention`, `top_predictions`, `plant`, `is_healthy`; the screen
   shows only a flattened `recommendations` list and confidence. No symptoms, no risk
   level, no plant name, no alternatives.
5. **No healthy / no-leaf states.** `Background_without_leaves` surfaces as the string
   "No leaf detected" inside a red disease card (§11, §12).
6. **`_HomeHeader` greeting is hardcoded "Good morning"** regardless of time of day.
7. **Centre scan FAB sits at `top: -20` inside its `Stack`.** `clipBehavior: Clip.none`
   fixes rendering, not hit-testing; the top edge of the button may not receive taps.
8. **No empty/error/loading component vocabulary.** Every screen improvises its own.

### Backend problems

1. `/health` returns `{"status": "healthy"}` only — no `model_loaded`, no DB check (§22).
2. `DetectResponse` has no `alternatives`, no `risk_level`, no `metadata`
   (`model_version`, `processing_time_ms`) (§19).
3. Errors carry no machine-readable `code` — Flutter cannot map them (§25).
4. `disease_metadata.py` has no `symptoms` and no `risk_level`, both required by §8/§19.
5. `print()` used for error reporting in `detect.py:86` and `detect.py:141`.
6. Function-local `from datetime import ...` in two route bodies.
7. `HealthResponse` is a single literal field.

### Security problems

1. `secret_key` default is a literal in `config.py` and `debug: bool = True` by
   default. If `.env` is missing in production the app runs in debug with a known key.
2. CORS wildcard (B2).
3. `.gitignore` gap (B4).
4. Uploads retained indefinitely, file suffix taken from client input (B3). The
   suffix is appended to a server-generated timestamp stem, so there is no path
   traversal, but the extension is still untrusted.
5. `flutter/.env` is committed. It holds only `SUPABASE_URL`, `SUPABASE_ANON_KEY` and
   `API_BASE_URL` — all legitimately public per §39. **No server secret is exposed.**
   No service-role key, JWT secret or credential was found in any tracked file.

### Performance problems

1. `BackdropFilter` in `GlassSurface` on every card and every list row.
2. `ScanHistoryService.getScanCount()` fetches 100 rows to call `.length`.
3. `ScanStorage.clearAll()` deletes cloud scans one HTTP request at a time.
4. `HomeScreen._loadData()` fetches *all* history in order to `.take(3)`.
5. `Image.file` with no `cacheWidth` on the result screen for a 120 px circle.

---

## 3. Recommended architecture

Keep what exists. The recommended changes are additive and local.

**Flutter**

- Rewrite `core/theme/app_colors.dart` to the light botanical palette, keeping every
  token *name*, so all 49 files pick the new palette up for free.
- Replace `GlassSurface`'s blur with a flat surface plus hairline border and soft
  shadow. Keep the class and its API — zero call-site churn.
- Add state components to `core/widgets/`: `EmptyState`, `ErrorState`, `LoadingState`,
  `ConfidenceIndicator`, `HealthStatusBadge`, `DiagnosisCard`.
- Add a typed `data/models/detection_result.dart` and have `ApiService` return it, so
  screens stop reading `Map<String, dynamic>`.
- Fix B1 by making `ScanStorage` **cache-first**: always write local, mirror to cloud
  best-effort, fall back to local when cloud reads fail.
- Keep Provider. Keep named routes. Keep the 4-tab + centre-FAB nav — the FAB *is* the
  emphasised Scan tab the brief asks for, and adding a fifth flat tab would be worse.

**Backend**

- Extract the shared persist-detection step out of `/detect` and `/predict` into one
  helper, so the two routes differ only in response serialisation.
- Extend `DetectResponse` with `alternatives`, `information` and `metadata`; extend
  `PredictionResult` with `risk_level`; add `symptoms` and `risk_level` to the KB.
- Add `code` to the error envelope and `error_code` to `AppException`.
- Expand `/health` to report `model_loaded`, `model_version` and `database`.
- Delete uploaded temp files unless the detection is persisted for a user.
- Tighten CORS and secret defaults behind `debug`.

**Explicitly NOT doing** (documented rejections):

- Not migrating to Riverpod/BLoC — §27 says keep Provider, and it works.
- Not restructuring `screens/` into `features/*/screens/` — 9 files, pure churn (§45).
- Not touching the model, class order, preprocessing or input size (§42).
- Not removing Supabase auth or backend JWT auth: they serve different clients
  (Flutter <-> Supabase; backend <-> its own `/api/v1` surface). See
  `BACKEND_REWORK_PLAN.md`, Authentication.
