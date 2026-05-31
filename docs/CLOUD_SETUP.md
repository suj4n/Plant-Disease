# Cloud-based plant disease detection (APK + your model)

Supabase handles **login/register** in the cloud. **Photo analysis** uses your **Keras model on a FastAPI server** — the phone only uploads the image and shows the JSON result. The model does not run inside the APK.

## Why the APK showed wrong results before

| Feature | Where it runs | Works on standalone APK? |
|---------|---------------|---------------------------|
| Auth | Supabase (HTTPS) | Yes |
| Scan / ML | FastAPI + `plant_best_model.keras` | Only if `API_BASE_URL` points to a **public server** |

A release APK built with `API_BASE_URL=http://127.0.0.1:8000` talks to the **phone itself**, not your PC. The app used to hide that failure and show **random fake diseases**. That fallback is removed — you now get a clear error until the cloud URL is set.

## Architecture

```
[Flutter APK]  --HTTPS-->  [Supabase]           (auth)
[Flutter APK]  --HTTPS-->  [Your FastAPI API]   (POST /predict + model)
```

## Step 1 — Put your model on the server

Your trained file and labels must be on the machine/container that runs the API:

| File | Location in repo |
|------|------------------|
| Model | `model/plant_best_model.keras` |
| Class names | `Resources/class_names.json` |

To use **your own** retrained model:

1. Replace `model/plant_best_model.keras` with your `.keras` file (same 224×224 RGB + softmax output).
2. Update `Resources/class_names.json` so class order matches the model output indices.
3. Adjust `backend/app/data/disease_metadata.py` if you added new disease labels.

## Step 2 — Deploy FastAPI (Docker)

From the repo root, ensure `model/plant_best_model.keras` exists, then:

```powershell
docker compose up --build
```

For production (Railway, Render, Fly.io, AWS, etc.):

1. Push the repo (`backend/`, `model/`, `Resources/` must be present).
2. Build from the **repository root** `Dockerfile` (default paths are already set in the image).
3. Expose the platform **PORT** (usually mapped to HTTPS at the edge).
4. Set env vars from `backend/.env.example` (`SECRET_KEY`, optional Supabase service role for scan storage).

| Platform | Notes |
|----------|--------|
| **Railway** | New service → Deploy from repo → Dockerfile path: `Dockerfile` (root). Add `SECRET_KEY` in Variables. |
| **Render** | Web Service → Docker → Root directory `.` → Health check path `/health`. |
| **Fly.io** | `fly launch` then set `internal_port` to match `PORT` (8000) in `fly.toml`, or run `fly deploy` with this Dockerfile. |

Verify:

```bash
curl https://YOUR_API_HOST/health
curl -X POST "https://YOUR_API_HOST/predict?top_k=5" -F "file=@leaf.jpg"
```

You should get JSON with `disease`, `confidence`, `isHealthy`, `recommendations`.

## Step 3 — Point the Flutter app at the cloud API

Edit `flutter/.env`:

```env
API_BASE_URL=https://YOUR_API_HOST
```

(Use `https://` in production; no trailing slash.)

`.env` is listed in `pubspec.yaml` assets, so it is **bundled into the APK** when you build.

## Step 4 — Build the release APK

```powershell
cd flutter
flutter pub get
flutter build apk --release
```

Optional override at build time:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_HOST
```

APK output: `flutter/build/app/outputs/flutter-apk/app-release.apk`

Install on a phone (same steps you use today), sign in with Supabase, open **Scan** → camera/gallery → **Analyze leaf**. The image is sent to your server; the real model response appears on the result screen.

## Development on a physical phone (no cloud yet)

**USB:**

```powershell
.\scripts\dev-usb.ps1
```

**Wi‑Fi:** set `API_BASE_URL=http://YOUR_PC_IP:8000` in `flutter/.env`, start backend with `--host 0.0.0.0`, allow port 8000 in the firewall.

## Optional — save scans to Supabase

Auth already uses Supabase. To store scan rows in the `scans` table from the backend, set in `backend/.env`:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

The Flutter app currently saves history locally (`ScanStorage`). Wiring `ScanHistoryService` after each successful scan is a separate enhancement.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| “Cannot reach the analysis server” | Wrong `API_BASE_URL`, API down, or HTTP blocked — use HTTPS in production |
| 503 / model not loaded | `plant_best_model.keras` missing on server; check container logs |
| Wrong class names | `class_names.json` order must match model output |
| Camera won’t open | Reinstall APK after manifest permission update; grant camera in Android settings |
