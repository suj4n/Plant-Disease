# PlantDoc — Backend Rework Plan (Phase 3)

Derived from `docs/REWORK_AUDIT.md`. The backend already has the architecture the
brief asks for (§17, §18, §21, §23): versioned `/api/v1` router, Pydantic schemas,
a model service loaded once at startup, Alembic migrations, centralised exception
handling. This plan closes the remaining gaps and deletes dead code. It does not
restructure anything that works.

---

## 1. API architecture

**Unchanged.** `app/api/routes/__init__.py` already composes
`auth, detect, history, plants, diseases, favorites` into `api_router`, mounted at
`settings.api_v1_prefix`. `/health` is mounted at the root, and `/predict` is kept as
the legacy compatibility route required by §18.

Endpoints after this phase:

| Method | Path | Change |
|---|---|---|
| GET | `/health` | Expanded payload (§22) |
| GET | `/api/v1/health` | **New** — same handler, also mounted under the versioned prefix |
| POST | `/api/v1/detect` | Response extended with `alternatives`, `information`, `metadata` (§19) |
| POST | `/predict` | Unchanged shape (legacy Flutter compatibility) |
| GET | `/api/v1/history`, `/plants`, `/diseases`, `/diseases/{id}`, `/favorites` | Unchanged |
| POST/DELETE | `/api/v1/favorites`, `/favorites/{id}` | Unchanged |

**Deduplication (fixes D1).** `/detect` and `/predict` currently each repeat ~50
lines of read-upload -> write file -> persist SQLite -> mirror to Supabase. Both
routes will call one shared `_run_detection(file, top_k)` helper that returns
`(prediction, tops, elapsed_ms)` plus one shared `_persist_detection(...)`. The two
routes then differ only in which response schema they serialise into. One inference
service underneath, as §18 requires.

---

## 2. Detection response (§19)

`PredictionResult` gains `risk_level: Literal["low", "medium", "high"]`, `symptoms:
list[str]` and `scientific_name`. `DetectResponse` becomes:

```json
{
  "prediction": {
    "disease": "Early blight", "plant": "Tomato",
    "confidence": 0.87, "is_healthy": false, "risk_level": "medium",
    "class_label": "Tomato___Early_blight"
  },
  "alternatives": [ { "disease": "Late blight", "plant": "Tomato", "confidence": 0.08 } ],
  "information": { "description": "...", "symptoms": [], "treatment": [], "prevention": [] },
  "metadata": { "model_version": "mobilenetv2-20c-v1", "processing_time_ms": 123 }
}
```

`alternatives` excludes the top prediction and is capped at 4 (§10). `model_version`
is a config value derived from the model filename and class count — it does not read
or modify the model file.

**Knowledge base.** `app/data/disease_metadata.py` gains, per class:

- `symptoms: list[str]` — currently missing entirely, required by §8.
- `risk_level` — a static severity per disease (e.g. Late blight `high`,
  Cedar apple rust `low`), **not** derived from model confidence. Confidence means
  model certainty; risk means agronomic severity. Conflating them is bug B6.

Healthy classes get `risk_level: "low"`; `Background_without_leaves` gets a dedicated
`is_identifiable: false` marker so the client can render the §12 recovery state
without string-matching a class name.

---

## 3. Error model (§25)

`AppException` gains `error_code: str`. The exception handlers in `main.py` emit:

```json
{ "success": false, "error": { "code": "INVALID_IMAGE", "message": "..." } }
```

`success` and a top-level `message` are retained alongside `error` so the existing
Flutter `_parseJsonResponse` (which reads `message`) keeps working during the
transition. Codes: `INVALID_IMAGE`, `FILE_TOO_LARGE`, `MODEL_UNAVAILABLE`,
`PREDICTION_FAILED`, `UNAUTHORIZED`, `NOT_FOUND`, `DATABASE_ERROR`, `RATE_LIMITED`,
`INTERNAL_ERROR`, `VALIDATION_ERROR`.

`RATE_LIMITED` is defined in the enum but **no rate limiter is added** — there is no
deployment requiring one, and a hand-rolled limiter is a liability. The code exists so
a reverse proxy or future middleware can use it.

---

## 4. Health endpoint (§22)

```json
{ "status": "healthy", "model_loaded": true,
  "model_version": "mobilenetv2-20c-v1", "classes": 20, "database": "connected" }
```

`database` is probed with `SELECT 1`. `status` degrades to `"degraded"` when the model
is not loaded or the DB is unreachable, but the endpoint still returns 200 so the
probe itself never looks like an outage. No configuration, paths or secrets are
exposed (§22).

**Existing `tests/test_health.py` asserts exact equality with
`{"status": "healthy"}` and will be updated** to assert the fields it cares about
rather than the whole dict.

---

## 5. Authentication (§16) — finding and decision

The audit uncovered a **dead integration**, which §16 asks to be documented:

- The Flutter app authenticates against **Supabase** and, in
  `ApiService._authHeaders`, sends the **Supabase** JWT as `Authorization: Bearer`.
- The backend's `get_current_user` decodes that token with **its own** `SECRET_KEY`
  using HS256 (`app/core/security.py:decode_token`).
- A Supabase-issued token can never validate against the backend's own secret, so
  `OptionalUser` is **always `None`** for the real client.
- Consequently the `if current_user:` branch in both `/detect` and `/predict` —
  SQLite persistence *and* the server-side Supabase mirror — is **never executed in
  production**. It is dead code, and nothing depends on it.
- Flutter never calls `/api/v1/auth/*` at all (verified by grep: zero call sites).

**Decision:**

1. **Keep** Supabase auth in Flutter — it works and owns the user session and history.
2. **Keep** the backend's own JWT auth and `/api/v1/auth/*`. It is exercised by
   `tests/test_auth.py` and is the credential scheme for the backend's own API
   surface (history / favorites / plants). Removing it would delete a working,
   tested feature for no gain, which §43 forbids.
3. **Delete the server-side Supabase mirror from the detect routes.** It is dead
   (point 4 above), and even if auth were wired it would *duplicate* what the Flutter
   client already writes through `ScanStorage`. Removing it also takes
   `SUPABASE_SERVICE_ROLE_KEY` out of the request path.
   `app/services/supabase_service.py` itself is retained for operational use.
4. **Do not** bridge Supabase JWTs into the backend. That means adding JWKS fetching,
   caching and rotation to validate a token the backend has no current need for —
   substantial machinery for a feature nobody asked for. Documented as the deliberate
   non-goal it is; the bridge belongs in a follow-up if cloud detection history via
   the backend is ever actually wanted.

This is the "unnecessary duplication" §16 anticipates: two auth systems, only one of
which the mobile client uses. Nothing Supabase-related in Flutter is touched.

---

## 6. Database (§23)

**No schema change, so no new Alembic migration.** The existing
`001_initial_schema.py` covers `users`, `detections`, `plants`, `diseases`,
`favorites`. Foreign keys use `ondelete="CASCADE"` with matching ORM cascades, and
`user_id` is indexed on both `detections` and `favorites`. Inspected and sound.

One note recorded, not acted on: `main.py` calls `Base.metadata.create_all()` in
`lifespan` *and* Alembic manages the same schema. For SQLite development this is
harmless (create_all is a no-op on existing tables), but production should run
`alembic upgrade head` and not rely on `create_all`. This is documented in the README
rather than changed, because changing it would break the current one-command local
start that the Windows dev scripts depend on (§43).

---

## 7. Image handling and security (§20, §39)

| Issue | Fix |
|---|---|
| B3 — uploads kept forever | Write to a `tempfile.NamedTemporaryFile`; promote to `uploads/` **only** when the detection is persisted for a user, otherwise delete in a `finally`. |
| Untrusted extension | Extension derived from the **decoded** image format (Pillow `Image.format`), not from `file.filename`. |
| Dimension check missing | Add min 32x32 / max 8000x8000 in `validate_image_bytes` (§20). |
| Decompression bomb | Set `Image.MAX_IMAGE_PIXELS`; `verify()` already guards malformed data. |
| B2 — CORS wildcard + credentials | `allow_credentials` only when `cors_origins` is not `["*"]`; default origins become the local dev hosts, with production origins supplied via env. |
| Secret defaults | `Settings` validates on startup: if `debug` is false and `secret_key` is still the placeholder, refuse to boot. Dev default unchanged so local start keeps working. |
| B4 — `.gitignore` | Add `backend/.env`, `uploads/`, `*.db`, `__pycache__/`, `.dart_tool/`, `build/`, `.gradle/`. `flutter/.env` stays tracked — it holds only public values (§39). |
| `print()` for errors | Replaced with `logger.exception`. |

No uploaded path is ever returned to a client; `history` responses expose ids, not
filesystem paths.

---

## 8. Documentation (§40)

- FastAPI `summary` and `description` on every route, plus `responses={...}` examples
  for the error envelope, so `/docs` is genuinely usable.
- `backend/README.md`: install, env vars, DB and migrations, endpoint reference, auth,
  error codes, model requirements, Docker deployment.
- `backend/.env.example` updated with every variable the code actually reads.

---

## 9. Testing (§41)

Backend (`pytest`), added to the existing 3 tests:

- `test_health` — updated for the new payload.
- `test_detect_rejects_non_image` -> 400 `INVALID_IMAGE`.
- `test_detect_rejects_oversized` -> 400 `FILE_TOO_LARGE`.
- `test_error_envelope_has_code`.
- `test_metadata_has_symptoms_and_risk_for_every_class` — iterates all 20 labels from
  `Resources/class_names.json`, so the KB can never silently fall out of sync with the
  model's classes.
- `test_class_order_unchanged` — pins the 20 labels and their order, making §42's
  "do not change class ordering" a test failure rather than a code review hope.

Inference itself is **not** unit-tested with the real 60 MB model: loading TensorFlow
in CI to assert a float is slow and brittle. The detect routes are tested with the
model service patched, which is what the route logic actually needs covered.

Flutter (`flutter test`) — no test directory exists today:

- `test/confidence_test.dart` — normalisation (1.0 vs 100 vs string forms).
- `test/greeting_test.dart` — time-of-day greeting.
- `test/image_validation_test.dart` — client-side upload validator.
- `test/error_mapping_test.dart` — backend error code -> user-facing message.

Small and pure by design: widget-tree golden tests on a UI being actively redesigned
would be churn, not coverage.

---

## 10. Order of work

1. `.gitignore`, config/CORS/secret validation — smallest, highest security value.
2. `disease_metadata.py`: add `symptoms` + `risk_level` for all 20 classes.
3. `exceptions.py` + `main.py` handlers: error codes.
4. `schemas/detection.py` + `disease_detection.py`: new response fields, timing.
5. `detect.py`: deduplicate the two routes, temp-file handling, drop the dead
   Supabase mirror.
6. `health.py`: expanded payload.
7. Backend tests, then `pytest`.
8. Hand off to Flutter (Phase 4).
