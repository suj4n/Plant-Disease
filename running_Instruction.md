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

The app sends scans to `POST /predict`. The URL is set in **`flutter/.env`**:

```env
API_BASE_URL=http://127.0.0.1:8000
```

For **release APK / production**, use your cloud HTTPS URL (see `docs/CLOUD_SETUP.md`).

Default for USB dev:

```env
API_BASE_URL=http://127.0.0.1:8000
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
3. In `flutter/.env`, set your PC IP:

```env
API_BASE_URL=http://192.168.1.75:8000
```

4. Rebuild the app: `flutter run`.

Phone and PC must be on the same network. Allow port **8000** through Windows Firewall if requests fail.

### Android permissions

Configured in `flutter/android/app/src/main/AndroidManifest.xml`:

- `INTERNET`, `CAMERA`, `READ_MEDIA_IMAGES`
- `android:usesCleartextTraffic="true"` (for HTTP during development only)

---

## 4. Build a release APK (cloud ML)

1. Deploy the backend with your model (see **`docs/CLOUD_SETUP.md`**).
2. Set in `flutter/.env`:

```env
API_BASE_URL=https://your-deployed-api.example.com
```

3. Build:

```powershell
cd flutter
flutter build apk --release
```

4. Install `build/app/outputs/flutter-apk/app-release.apk` on the phone.

Auth uses Supabase over the internet; scans use `API_BASE_URL` — **not** `127.0.0.1` on a standalone APK.

---

## 5. Test a scan in the app

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
| 4. API URL    | `API_BASE_URL` in `flutter/.env` (USB / Wi‑Fi / cloud HTTPS)                                 |
| 5. APK        | `flutter build apk --release` after setting cloud `API_BASE_URL`                               |


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