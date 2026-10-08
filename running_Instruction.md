# PlantDoc — Running Instructions

Step-by-step guide to run the Flutter app and the FastAPI backend on your machine or phone.

Scans run **on the phone** with the bundled TensorFlow Lite model, and accounts are
stored on the phone too. The backend is only a **fallback**: the app sends a photo to
it only if on-device inference fails. You can run the app without the backend.

---

## 1. Prerequisites

Install and verify:

```powershell
python --version    # 3.11+ recommended
flutter doctor      # Android toolchain OK
adb version         # optional; needed for the USB dev script
```

The repository already contains:

1. **Model file**: `model/plant_best_model.keras`, used by the backend.
2. **Phone model**: `flutter/assets/models/plant_model.tflite` and `disease_info.json`, used by the app.
3. **Class labels**: `Resources/class_names.json`. The order must match the model output.

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
# Optional for local use. For production, set DEBUG=false and a real SECRET_KEY.
```

### Flutter `.env`

```powershell
cd flutter
copy .env.example .env
```

`flutter/.env` has one setting, the address of the fallback server:

```env
API_BASE_URL=http://127.0.0.1:8000
```

> `.env` is bundled into the APK, so never put secrets in it.

### Dev scripts config (optional, for the Wi‑Fi script)

```powershell
cd scripts
copy config.example.ps1 config.ps1
# Edit LanIp to your PC IPv4 (ipconfig → Wireless/Ethernet IPv4)
```

---

## 3. Run the backend manually (optional)

```powershell
cd backend
. .venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Check:

- http://127.0.0.1:8000/health → `{"status":"healthy","model_loaded":true,...}`
- http://127.0.0.1:8000/docs → Swagger UI

Stop with `Ctrl+C`.

---

## 4. Run the Flutter app

### Option A — USB + one script (Windows)

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

```powershell
cd flutter
flutter pub get
flutter run
```

### Android emulator

To reach a backend on the host, use `http://10.0.2.2:8000` (the host's loopback):

```powershell
cd flutter
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

---

## 5. Release APK

1. Optionally, set the fallback server in `flutter/.env` to a public HTTPS address:

```env
API_BASE_URL=https://your-api.example.com
```

2. Build:

```powershell
cd flutter
flutter pub get
flutter build apk --release --split-per-abi   # per-device APKs (arm64 is ~39 MB)
flutter build apk --release                   # universal APK (~85 MB)
```

3. The APKs are in `flutter\build\app\outputs\flutter-apk\`. Copy one to the phone, or:

```powershell
adb install -r flutter\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

4. On the phone, allow **Camera** and **Notifications** (plant reminders) when prompted.

Ready-built APKs are on the [GitHub Releases](https://github.com/suj4n/Plant-Disease/releases) page.

### After retraining the model

Copy the new `plant_best_model.keras` to `model/`, then regenerate the phone model
and knowledge base. The script also checks the phone model against the Keras one:

```powershell
backend\.venv\Scripts\python scripts\export_tflite.py
```

Then rebuild the APK.

---

## 6. Docker (backend in a container)

From repo root:

```powershell
docker compose up --build
```

- API: http://localhost:8000
- Make sure `model/plant_best_model.keras` exists before you build.

---

## 7. Using the app

1. Open the app. On the **Welcome** screen, either:
   - **Sign up**: full name (this becomes your username), password, confirm password.
   - **Log in**: your name and password.
   - **Continue as guest**: no account. Guests can track one plant batch.
2. Optional: **Profile → Security → Fingerprint login**. Once it's on, the login
   screen shows a fingerprint button next to **Log in**.
3. **Home → Scan**: take or pick a leaf photo. The diagnosis runs on the phone.
4. **History**: past scans, stored on the phone.
5. **Plant tracker**: create a batch and get a reminder to re-scan every 14 days.

Accounts, scans and plants are stored only on the phone. Passwords are stored as
a one-way hash.

---

## 8. Troubleshooting

| Problem | What to do |
|---------|------------|
| "Unable to connect to PlantDoc" | On-device inference failed and the fallback server is unreachable. Check `API_BASE_URL`, and that the backend is running |
| Backend not ready / connection refused | Wait for the model to load; check http://127.0.0.1:8000/health |
| `adb not found` | Install Android SDK platform-tools; set `AdbPath` in `scripts/config.ps1` |
| `adb reverse` fails | Authorise USB debugging; make sure only one device shows in `adb devices` |
| Wi‑Fi: phone can't reach PC | Same Wi‑Fi; correct `LanIp`; firewall allows port 8000 |
| 503 / model not loaded (backend) | Add `model/plant_best_model.keras`; check backend logs |
| Wrong disease names | Fix the order in `Resources/class_names.json` to match the model, then re-run `scripts/export_tflite.py` |
| "Add a fingerprint in your phone's Settings first" | Register a fingerprint in the phone's security settings, then turn fingerprint login on again |
| Can't add a second plant batch | Guests are limited to one. Create an account (Profile → Create an account) |
| "That name is already registered on this phone" | Log in with that name, or sign up with a different one |
| Install fails with "app not installed" over an older version | An arm64 install can only be updated with another arm64 APK; don't switch between arm64 and universal |
| Plant reminders not firing | Grant notification permission; open the app once after install |

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
cd backend; .venv\Scripts\python -m pytest -q
cd flutter; flutter test

# Regenerate the phone model after retraining
backend\.venv\Scripts\python scripts\export_tflite.py

# Release APKs
cd flutter; flutter build apk --release --split-per-abi
```

For backend endpoints and configuration, see [backend/README.md](backend/README.md).
