# KAWACH 🛡️

**Your personal safety shield. Always on, wherever you are.**

KAWACH (meaning *armour* / *shield* in Hindi) is a Flutter-based women & personal
safety system that turns a smartphone into an always-ready guardian. It blends
real‑time emergency response, proactive risk prediction, offline‑first
resilience and a community safety network into one calm, fast app.

---

## ✨ Features

### 🆘 Emergency (SOS) core
- **One‑tap / shake‑to‑trigger SOS** with a pre‑activation countdown and stealth mode
  (the app hides itself while help is already on the way).
- **Full‑scale multi‑channel emergency broadcast** — notify guardians, send SMS,
  start a live stream, capture audio + video evidence, alert nearby volunteers,
  and relay over mesh — all at once.
- **Background SOS service** keeps live tracking running even when the app is
  backgrounded.

### 📍 Location & route safety
- Live location tracking during emergencies, streamed to guardians.
- **Safe‑route map** that scores routes against known danger zones and reroutes
  you to the safest path (Google Maps Directions + danger heatmap).
- **Safe Walk** — schedule a timer; if you don't confirm arrival, SOS auto-triggers.
- Danger‑zone aggregation from community reports with visual heat‑map overlays.

### 🧠 Predictive & proactive safety
- **Risk analysis** based on time/location/danger zones.
- **Panic‑phrase listening** (voice triggers like "help me", "bachao") to auto‑SOS.
- **Motion detection** — snatch/shake detection, sprint & fall detection
  (AI‑Guardian heuristics) that can auto‑signal.
- **Predictive danger service** to warn you before trouble.

### 🛰️ Offline‑first resilience
- Emergency & location payloads are **queued locally** (`SharedPreferences`) when
  there is no network and **auto‑synced** the moment connectivity returns.
- Active emergency is **cached locally** so an active call survives app restarts.
- **Mesh relay** broadcasts emergency packets device‑to‑device when the network is
  unavailable.

### 👨‍👩‍👧 Family & community
- **Guardian network** — add trusted contacts, they can monitor your live state.
- **Community safety** — report incidents; incidents aggregate into shared
  danger‑zone heatmaps.
- **Nearby volunteer alerts** so good Samaritans can help fast.

### ⚡ Everyday helpers
- **Fake call** — schedule a believable incoming call to defuse sticky situations.
- **Flash siren + torch** for visibility.
- **Stealth mode UI**, evidence vault and profile/emergency details.

---

## 🧠 What the app really needs (gaps called out in the codebase)

The checklist below is derived from the current state of `lib/` and the Supabase
migration, and represents the must‑do before going to production:

1. **Secrets management** — `lib/config/env_config.dart` and `lib/utils/constants.dart`
   contain **default/placeholder Google Maps and Supabase keys**. Inject them via
   `--dart-define=` at build time and keep them out of source control.
2. **SMS gateway & streaming server** are placeholders (`AppKeys.smsGatewayUrl`,
   `AppKeys.streamingServerUrl`). Wire real endpoints before release.
3. **Ringtone asset** referenced by `FakeCallManager` (`assets/audio/ringtone.mp3`)
   does not exist yet — drop an MP3 in `assets/audio/` (no code change needed).
4. **Google Maps** requires your Maps API key configured for **Android + Web**
   (the web map relies on the JS interop in `safe_route_web_impl.dart`).
5. **Run the Supabase migration** in `supabase/migrations/20260425_001_kawach_core.sql`
   against your project before first use.
6. **Amazon stack flavour**: the app was written leaning on Supabase; keep your
   project URL & anon key uniform across the `web/` and `android/` config.

---

## 🚀 Getting started

```bash
# 1. Install Flutter (3.x) and platform toolchains (Android/iOS/Web)

# 2. Get dependencies
flutter pub get

# 3. Provide your keys (pick one method)
#    a) via dart-define (recommended for CI)
flutter run --dart-define=MAPS_API_KEY=YOUR_KEY \
            --dart-define=SUPABASE_URL=YOUR_URL \
            --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
#    b) or copy .env.example -> .env and fill real values (local only)

# 4. Run locally
flutter run
```

> `.env` is gitignored — never commit real secrets.

---

## 🔑 Environment variables

| Variable              | Used for                    | Default in repo (replace it!) |
| --------------------- | --------------------------- | ----------------------------- |
| `MAPS_API_KEY`        | Google Maps (Android/iOS/Web) | placeholder                |
| `SUPABASE_URL`        | Supabase project URL        | placeholder                |
| `SUPABASE_ANON_KEY`   | Supabase anon key           | placeholder                |

---

## 🧱 Architecture

```
lib/
├── app.dart                 # MaterialApp theme + routes
├── main.dart                # Supabase init + Provider wiring
├── config/env_config.dart   # dart-define driven config
├── models/                  # domain models (emergency, report, user…)
├── services/                # all business logic (SOS, mesh, risk…)
├── screens/                 # Flutter UI screens
├── utils/                   # constants, helpers, permissions
└── widgets/                 # reusable UI pieces (SOS button, map…)
```

All shared services are injected via `Provider`, e.g.
`EmergencyService`, `OfflineEmergencyService`, `MeshRelayService`,
`GuardianNetworkService`, `RiskAnalysisService`, `PanicDetectionService`.

---

## 🧪 Testing & quality

```bash
flutter analyze          # 0 issues expected
flutter test             # widget smoke test
flutter build apk        # Android
flutter build web        # Web (PWA-ready)
```

The whole codebase has been refactored to a **clean analyzer** state
(`No issues found!`), on top of the Android and Web builds passing.

---

## 🗺️ Deployment

### Android (`android/`)
1. Add the Maps API key to `android/app/src/main/AndroidManifest.xml`
   `<meta-data>` and the Android `google_maps_api_key` (android/app/src/main/res/values/*.xml).
2. `flutter build appbundle --release` for Play Store / `flutter build apk --release`.
3. Sign with a release keystore (`key.properties`).

### Web (`web/`)
1. Build with `flutter build web --release` (Wasm is supported).
2. Host the `build/web` folder on any static host (Firebase Hosting, Netlify,
   Vercel, S3+CloudFront).
3. Add a Google Maps JS API key if the web map is used.

### Backend (Supabase)
1. Create a project, run the SQL migration.
2. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` for production builds.
3. Enable storage bucket `incident-photos` etc. per the migration.

---

## 📄 License

Private/internal — contact the project maintainers for usage.