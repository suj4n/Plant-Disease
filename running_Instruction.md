# PlantDoc — Running Instructions

Step-by-step guide to run the Flutter app and FastAPI backend on your machine or phone.

---

## 1. Prerequisites

Install and verify:

```powershell
python --version    # 3.11+ recommended
flutter doctor      # Android toolchain OK
adb version         # optional; needed for USB dev script
```

You need:

1. **Model file** — `model/plant_best_model.keras` (repo root). Without it, `/health` may work but scans return 503.
2. **Class labels** — `Resources/class_names.json` (must match model output order).
3. **Supabase project** — Dashboard → Project Settings → API → `URL` and `anon` key.

---

## 2. First-time setup

Open PowerShell at the **repository root** (`Plant-Disease`):

```powershell
.\scripts\setup.ps1
```

This script:

- Creates `backend/.venv`, installs Python dependencies, runs `alembic upgrade head`
- Runs `flutter pub get` in `flutter/`

### Backend `.env`

```powershell
cd backend
copy .env.example .env
# Edit .env: set SECRET_KEY (random string). Add Supabase keys if using server-side scan storage.
```

### Flutter `.env`

```powershell
cd flutter
copy .env.example .env
```

Edit `flutter/.env`:

```env
SUPABASE_URL=https://xxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
API_BASE_URL=http://127.0.0.1:8000
```

> Do not commit real keys. `.env` is bundled into release APKs via `pubspec.yaml` assets.

### Dev scripts config (optional, for Wi‑Fi script)

```powershell
cd scripts
copy config.example.ps1 config.ps1
# Edit LanIp to your PC IPv4 (ipconfig → Wireless/Ethernet IPv4)
```

---

## 3. Run the backend manually

```powershell
cd backend
. .venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Check:

- http://127.0.0.1:8000/health → `{"status":"ok",...}`
- http://127.0.0.1:8000/docs → Swagger UI

Stop with `Ctrl+C`.

---

## 4. Run the Flutter app

### Option A — USB + one script (recommended on Windows)

Phone: **Developer options** → USB debugging ON, connect via USB.

```powershell
# From repo root
.\scripts\dev-usb.ps1
```

This will:

1. Open a new window with the FastAPI server (`0.0.0.0:8000`)
2. Wait for `/health`
3. Run `adb reverse tcp:8000 tcp:8000`
4. Start `flutter run` with `API_BASE_URL=http://127.0.0.1:8000`

### Option B — Wi‑Fi (same network, no USB)

1. Set `LanIp` in `scripts/config.ps1` to your PC IP (e.g. `192.168.1.75`).
2. Allow port **8000** in Windows Firewall for private networks.
3. Run:

```powershell
.\scripts\dev-wifi.ps1
```

4. Set `API_BASE_URL=http://YOUR_PC_IP:8000` in `flutter/.env` if you run Flutter manually later.

### Option C — Manual Flutter

Backend must already be running.

```powershell
cd flutter
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Android emulator

Emulator can use `http://10.0.2.2:8000` (host loopback). Start backend on the host, then:

```powershell
cd flutter
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

---

## 5. Release APK (install on any phone)

1. Deploy the API to a server with HTTPS, or use Docker on a VPS. See [docs/CLOUD_SETUP.md](docs/CLOUD_SETUP.md).
2. Set production URL in `flutter/.env`:

```env
API_BASE_URL=https://your-api.example.com
```

3. Build:

```powershell
cd flutter
flutter pub get
flutter build apk --release
```

4. Install APK:

```text
flutter\build\app\outputs\flutter-apk\app-release.apk
```

Copy to the phone or:

```powershell
adb install -r flutter\build\app\outputs\flutter-apk\app-release.apk
```

5. On the phone: allow **Camera** and **Notifications** (plant reminders) when prompted.

> A release APK built with `API_BASE_URL=http://127.0.0.1:8000` cannot reach your PC’s API. Use a public HTTPS URL.

---

## 6. Docker (API in container)

From repo root:

```powershell
docker compose up --build
```

- API: http://localhost:8000
- Ensure `model/plant_best_model.keras` exists before build.

Point `flutter/.env` `API_BASE_URL` at `http://YOUR_PC_IP:8000` for phone testing on LAN, or at your deployed URL for APK.

---

## 7. Using the app

1. Open app → **Welcome** → register/login (Supabase).
2. **Home** → **Scan** → take or pick a leaf photo → analyze.
3. **History** — past scans (local storage).
4. **Plant tracker** — create a batch, log growth stages, set reminders (local notifications).

---

## 8. Troubleshooting

| Problem | What to do |
|---------|------------|
| `Cannot reach the analysis server` | Wrong `API_BASE_URL`; API not running; release APK still using `127.0.0.1` |
| Backend not ready / connection refused | Wait for model load; check http://127.0.0.1:8000/health |
| `adb not found` | Install Android SDK platform-tools; set `AdbPath` in `scripts/config.ps1` |
| `adb reverse` fails | USB debugging authorized; only one device: `adb devices` |
| Wi‑Fi: phone can’t reach PC | Same Wi‑Fi; correct `LanIp`; firewall allows port 8000 |
| 503 / model not loaded | Add `model/plant_best_model.keras`; check backend logs |
| Wrong disease names | Fix order in `Resources/class_names.json` to match model |
| Supabase auth errors | Check `SUPABASE_URL` (project URL, not REST path) and `SUPABASE_ANON_KEY` in `flutter/.env` |
| Cleartext HTTP blocked | Dev: `android:usesCleartextTraffic="true"` in manifest; production: use HTTPS |
| Plant reminders not firing | Grant notification permission; open app once after install |

---

## 9. Useful commands (cheat sheet)

```powershell
# Setup once
.\scripts\setup.ps1

# Dev with phone (USB)
.\scripts\dev-usb.ps1

# Dev with phone (Wi‑Fi)
.\scripts\dev-wifi.ps1

# Backend only (current terminal)
.\scripts\backend.ps1

# Tests
cd backend; . .venv\Scripts\activate; pytest -q

# Release APK
cd flutter; flutter build apk --release
```

For API endpoints, model paths, and deployment platforms, see [backend/README.md](backend/README.md) and [docs/CLOUD_SETUP.md](docs/CLOUD_SETUP.md).
