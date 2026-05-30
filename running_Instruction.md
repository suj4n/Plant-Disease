# PlantDoc — How to Run the Backend and Flutter App

Practical run order on **Windows** with a **physical Android phone** (USB debugging or Wi‑Fi).

---

## Smoothest way (one command)

**First time only:**

```powershell
cd C:\Users\ASUS\Documents\GitHub\Plant-Disease
.\scripts\setup.ps1
Copy-Item scripts\config.example.ps1 scripts\config.ps1
# Edit scripts\config.ps1 → set your Wi‑Fi IP in LanIp
```

**Every day — USB (phone plugged in):**

```powershell
cd C:\Users\ASUS\Documents\GitHub\Plant-Disease
.\scripts\dev-usb.ps1
```

This will:

1. Open the **backend** in a new PowerShell window  
2. Wait until `/health` responds  
3. Run **`adb reverse`**  
4. Start **`flutter run`** with the correct API URL (no editing `api_service.dart`)

**Every day — Wi‑Fi (no adb):**

```powershell
.\scripts\dev-wifi.ps1
```

Backend only (one terminal):

```powershell
.\scripts\backend.ps1
```

---

## Manual steps (if you prefer)

## 1. Backend (FastAPI)

Open a terminal in the repo root:

```powershell
cd C:\Users\ASUS\Documents\GitHub\Plant-Disease\backend
```

### First time only

```powershell
py -3.11 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
```

### Every time you develop

```powershell
cd C:\Users\ASUS\Documents\GitHub\Plant-Disease\backend
.venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Leave this terminal open. When it’s ready, Uvicorn listens on port **8000**.

### Quick check (on your PC)


| URL                                                          | Expected               |
| ------------------------------------------------------------ | ---------------------- |
| [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health) | `{"status":"healthy"}` |
| [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)     | Swagger UI             |


**Requirements**

- Model file: `model/plant_best_model.keras` (repo root)
- Class labels: `Resources/class_names.json`
- First startup may take a minute while TensorFlow loads the model

### Test predict from terminal (optional)

```powershell
$img = "C:\path\to\your_leaf.jpg"
curl.exe -X POST "http://127.0.0.1:8000/predict?top_k=5" -F "file=@$img"
```

---

## 2. Flutter app

Open a **second** terminal:

```powershell
cd C:\Users\ASUS\Documents\GitHub\Plant-Disease\flutter
flutter pub get
```

Connect the phone with **USB debugging** enabled, then:

```powershell
flutter devices
flutter run
```

---

## 3. Connect the phone to the backend

The app sends scans to `POST /predict`. The URL is set in:

`flutter/lib/core/services/api_service.dart`

Default (USB):

```dart
static const baseUrl = usbBaseUrl;  // http://127.0.0.1:8000
```

### Option A — USB debugging (recommended)

With the phone plugged in, in a **third** terminal:

```powershell
adb reverse tcp:8000 tcp:8000
```

Then `http://127.0.0.1:8000` on the phone forwards to your PC’s port 8000.

> Run `adb reverse` again if you unplug the phone, restart adb, or reboot the device.

Backend can use:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Option B — Same Wi‑Fi

1. On PC, run `ipconfig` and note your **IPv4** address (e.g. `192.168.1.42`).
2. Start the backend with `--host 0.0.0.0` (see above).
3. In `api_service.dart`, set your IP and use LAN mode:

```dart
static const lanBaseUrl = 'http://192.168.1.75:8000';  // your PC IP
static const baseUrl = lanBaseUrl;
```

1. Rebuild the app: `flutter run`.

Phone and PC must be on the same network. Allow port **8000** through Windows Firewall if requests fail.

### Android permissions

Already configured in `flutter/android/app/src/main/AndroidManifest.xml`:

- `INTERNET`
- `android:usesCleartextTraffic="true"` (for HTTP during development)

---

## 4. Test a scan in the app

1. Backend is running.
2. `adb reverse tcp:8000 tcp:8000` (if using USB).
3. Open the app → **Scan** → camera or gallery → **Analyze leaf**.

Use a **clear photo of a single leaf**; busy or non-leaf images may return “No leaf detected”.

---

## Troubleshooting


| Problem                        | What to check                                                   |
| ------------------------------ | --------------------------------------------------------------- |
| Analysis fails / no connection | Backend running? Correct `baseUrl`? USB: `adb reverse` again    |
| `SocketException` on phone     | Wi‑Fi: PC IP correct? Firewall allows port 8000                 |
| Backend won’t start            | Python 3.11+, venv activated, `pip install -r requirements.txt` |
| Model error on startup         | `model/plant_best_model.keras` exists                           |


---

## Quick reference


| Step          | Command / action                                                                             |
| ------------- | -------------------------------------------------------------------------------------------- |
| 1. Backend    | `cd backend` → activate `.venv` → `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000` |
| 2. USB bridge | `adb reverse tcp:8000 tcp:8000`                                                              |
| 3. Flutter    | `cd flutter` → `flutter pub get` → `flutter run`                                             |
| 4. API URL    | `usbBaseUrl` (USB) or `lanBaseUrl` with your PC IP (Wi‑Fi)                                   |


**Order:** start **backend** → run **adb reverse** (USB) → run **flutter run**.

---

## API endpoints (reference)


| Method | Path                    | Description                     |
| ------ | ----------------------- | ------------------------------- |
| GET    | `/health`               | Health check                    |
| POST   | `/predict?top_k=5`      | Flutter scan (multipart `file`) |
| POST   | `/api/v1/detect`        | Structured detection response   |
| POST   | `/api/v1/auth/register` | Register user                   |
| POST   | `/api/v1/auth/login`    | Login                           |
| GET    | `/api/v1/history`       | Scan history (JWT required)     |


Full details: `backend/README.md`