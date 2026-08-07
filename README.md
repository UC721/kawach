# 🛡️ KAWACH

> **Your personal safety shield. Always on, wherever you are.**

**KAWACH** (*कवच* — meaning **armour** / **shield** in Hindi) is a Flutter-based
women & personal safety system that turns an everyday smartphone into an
always-ready guardian. It blends **real-time emergency response**, **proactive
risk prediction**, **offline-first resilience** and a **community safety
network** into one calm, fast app — built for moments when a second really counts.

<div align="center">

```
        ██╗  ██╗ █████╗ ██╗    ██╗ █████╗  ██████╗██╗  ██╗
        ██║ ██╔╝██╔══██╗██║    ██║██╔══██╗██╔════╝██║  ██║
        █████╔╝ ███████║██║ █╗ ██║███████║██║     ███████║
        ██╔═██╗ ██╔══██║██║███╗██║██╔══██║██║     ██╔══██║
        ██║  ██╗██║  ██║╚███╔███╔╝██║  ██║╚██████╗██║  ██║
        ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

**Your Shield. Always.**

</div>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.29+-02569B?style=flat-square&logo=flutter&logoColor=white">
  <img alt="Platform: Web / Android / iOS" src="https://img.shields.io/badge/Platforms-Web%20%7C%20Android%20%7C%20iOS-4285F4?style=flat-square">
  <img alt="State" src="https://img.shields.io/badge/State%20Mgmt-Provider-7B61FF?style=flat-square">
  <img alt="Backend" src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white">
  <img alt="Maps" src="https://img.shields.io/badge/Maps-OpenStreetMap%20%2F%20flutter_map-7AB55C?style=flat-square&logo=openstreetmap&logoColor=white">
  <img alt="Routing" src="https://img.shields.io/badge/Routing-OSRM%20%2F%20Nominatim-4C9A2A?style=flat-square">
  <img alt="Offline-first" src="https://img.shields.io/badge/Offline-first-SharedPreferences-FF6D00?style=flat-square">
  <img alt="Quality" src="https://img.shields.io/badge/analyze-0%20issues-success?style=flat-square">
</p>

---

## 🧭 Table of Contents

- [Highlights](#-highlights)
- [Core Features](#-core-features)
- [How it works](#-how-it-works)
- [Architecture](#-architecture)
- [Project structure](#-project-structure)
- [Data model](#-data-model)
- [Getting started](#-getting-started)
- [Environment variables](#-environment-variables)
- [Maps — no API key required](#-maps--no-api-key-required)
- [Testing & quality](#-testing--quality)
- [Deployment](#-deployment)
- [Known integration notes](#-known-integration-notes)

---

## ✨ Highlights

- 🆘 **One-tap, shake, or voice-triggered SOS** with stealth mode & a full multichannel panic broadcast.
- 🧠 **Proactive safety AI** — risk scoring, panic-phrase listening, snatch / fall / sprint detection.
- 🗺️ **Real maps** on OpenStreetMap with OSRM "safest-path" routing — **no API key needed**.
- 🛰️ **Offline-first** — emergencies & locations queue locally and auto-sync, with mesh relay when there's no network at all.
- 👨‍👩‍👧 **Guardian network** with approval lifecycle, live monitoring, and a unified incident timeline.
- 🔐 **Privacy console** — export your data, wipe your local footprint, or erase everything.
- ⚡ **Everyday escapes** — fake calls, flash siren + torch, safe-walk timers.

---

## 🚀 Core Features

### 🆘 Emergency (SOS) core
- **Trigger SOS 3 ways:** one-tap, **shake-to-activate** (accelerometer), or **panic phrase** ("help me", "bachao", "chhodo"...).
- A **5-second pre-activation countdown** gives you the default to back out; confirm and the app moves fast.
- **Full multi-channel broadcast** fires in parallel:
  - Notify **guardians** with live location
  - Send an **SMS** alert
  - Start a **live stream**
  - Capture **audio + video evidence**
  - Alert **nearby volunteers**
  - Relay the packet over **mesh** device-to-device
- **Stealth mode** hides the app UI while help is already on the way.
- **Background SOS service** keeps live tracking running even when the app is backgrounded or on lock screen.

### 📍 Location, Maps & Safe Routes
- **Real-time location streaming** to guardians during an emergency.
- **Live OpenStreetMap** maps via `flutter_map` flytiles (no Google, no key).
- **Safe Route** — OSRM computes real street navigation and the engine **scores each candidate path against known danger zones**, picking the safest path and rendering it with danger heat-circle overlays.
- **Safe Walk** — set a timer; if you don't confirm arrival, an SOS auto-triggers.
- **Danger-zone aggregation** from community reports, visualised as overlay circles.

### 🧠 Proactive & proactive safety (AI-Guardian)
- **Risk analysis** scores your context (time-of-day, location, nearby danger zones).
- **Predictive danger service** warns you before trouble is likely.
- **Panic detection & motion heuristics** — snatch/spin, **fall detection**, **impact detection**, **sprint/Run** thresholds can auto-trigger an emergency signal.

### 🛰️ Offline-first & sync
- `SosQueueManager` queues emergencies & location payloads locally when offline, **auto-syncing** when connectivity returns.
- Active emergencies are **cached** so a running call survives app restarts.
- **Mesh relay** broadcasts emergency packets to nearby devices when there's no network.
- A **conflict resolver** deduplicates and reconciles local ↔ server state (server wins for status, local wins to compensate missing fields).

### 👨‍👩‍👧 Guardians, safety & community
- **Guardian network** — add trusted contacts with a **request → approval lifecycle**.
- **Guardian live monitor** — watch a protected user's live location & emergency banner.
- **SOS acknowledgements** — guardians can ack a rescue and indicate who's responding.
- **Community safety** — report incidents; reports aggregate into shared danger-zone heatmaps.
- **Unified Incident History** — a coloured timeline of emergencies, evidence, acks, and activity.

### 📋 Profile, Emergency & Privacy
- **Onboarding** — 4-step welcome & guided setup.
- **Emergency profile** — medical conditions, allergies, blood group, insurance, legal holder, organ-donor status + emergency contact info.
- **Privacy console** — export your full data set, rotate the local cipher key, or **erase all data** with a single action.
- **Sync status** — see pending offline items and sync health at a glance.

### ⚡ Everyday helpers
- **Fake call** — schedule a believable incoming call.
- **Flash + torch/siren** for visibility.
- **Stealth mode UI**, evidence vault, profile & settings.

---

## ⚙️ How it works

**1. Onboarding → Splash → Auth.** The splash screen restores offline sync-state and
gates into onboarding for new users before landing on the dashboard.

**2. Dashboard Hub.** Five tabs ([Home, Safety Map, SOS Core, Guardian Network, Settings])
radar the current risk profile, live SOS state, and quick-access feature tiles.

**3. The SOS flow.**
```
Trigger (tap / shake / voice)
      │ 5s countdown (cancel-able)
      ▼
Broadcast (parallel):
   guardians notify  + SMS  + livestream
   + audio/video evidence  + nearby volunteers  + mesh relay
      ▼
Offline? ──yes──► SosQueueManager queues locally
      │                 └─► auto-sync + conflict-resolve on reconnect
      ▼
   Guardians see the live emergency & location; acks recorded → incident history.
```

**4. Offline & sync.** Every emergency/location payload is encrypted, queued with
crypto (`payload_cipher`), and reconciled server or local "wins" per field — no
data is trivially lost when you drop off then back on.

**5. Safe routing.** Pick a destination on the OpenStreetMap map → OSRM returns
candidate routes → the engine scores each against the current danger circles →
the safest polyline is highlighted and framed with `CameraFit.bounds`.

---

## 🏗️ Architecture

Clean, layered Flutter app using **Provider** for DI + state, **Supabase** for
the backend, and `flutter_map`/OSM for maps. All shared services are constructed
and injected in `lib/main.dart`.

```
UI (lib/screens, lib/widgets)
        ▼
Providers (ChangeNotifier via Provider)
    ┌──────────┬──────────────┬───────────────┐
    ▼          ▼              ▼               ▼
 Services  Services  Services   ├─────────────────▲ Sync/Offline layer
 (SOS,      (Maps)    (AI)      │                 │ SosQueueManager,
  Guardian,  RouteSafety  MotionDetection       │ OfflineEmergencyService,
  Evidence...) + OSRM    PanicDetection         │ ConflictResolver
    │          └── Nominatim    RiskAnalysis     ▼
    ▼                        MeshRelayService ── ► Encrypted local cache
Database (Supabase)                        (SharedPreferences)
Storage   (evidence bucket)
```

**Key services** (all injected via `MultiProvider`):

| Layer | Services |
| --- | --- |
| **SOS / Emergency** | `EmergencyService`, `SosQueueManager`, `OfflineEmergencyService`, `BackgroundSosService`, `SirenService`, `LiveStreamService`, `SmsService` |
| **Location & maps** | `LocationService`, `RouteSafetyService` (OSRM + Nominatim), `DangerZoneService`, `SafetyStreamerService` |
| **Proactive / AI** | `RiskAnalysisService`, `PredictiveDangerService`, `MotionDetectionService`, `PanicDetectionService`, `AiGuardianService` |
| **Guardians / Community** | `GuardianNetworkService`, `GuardianLifecycleService`, `IncidentHistoryService` |
| **Account & data** | `AuthService`, `UserService`, `EmergencyProfileService`, `PrivacyService`, `OnboardingService`, `EvidenceVaultService`, `CameraEvidenceService`, `ConflictResolver` |
| **Utilities** | `NotificationService`, `VoiceService`, `MeshRelayService`, `AudioService`, `FakeCallService` |

---

## 📁 Project structure

```
lib/
├── main.dart                  # Supabase init + Provider wiring
├── app.dart                   # MaterialApp theme, fonts, routes
├── config/
│   └── env_config.dart        # dart-define driven config (Supabase)
├── models/                    # domain models (emergency, report, user guardian…)
│   ├── emergency_profile_model.dart  guardian_request_model.dart
│   ├── incident_event_model.dart     danger_zone_model.dart  …and more
├── services/                  # all business logic (SOS, mesh, risk, sync…)
│   ├── conflict_resolver.dart        offline_emergency_service.dart
│   ├── route_safety_service.dart     (OSRM + Nominatim)
│   └── … 30+ services
├── screens/                   # 23+ Flutter screens
│   ├── onboarding_screen.dart  dashboard_screen.dart  sos_screen.dart
│   ├── map_screen.dart         safe_route_map_screen.dart
│   ├── guardian_approval_screen.dart  incident_history_screen.dart
│   ├── privacy_console_screen.dart    sync_status_screen.dart
│   └── emergency_profile_screen.dart  …and more
├── utils/
│   ├── constants.dart         # AppColors/Routes/Strings/Keys/Thresholds/Collections
│   └── permission_manager.dart helpers.dart
└── widgets/                   # reusable UI (SOS button, RealMap, guardian tile…)
    └── real_map.dart          # the OSM map widget (danger circles, polyline, markers)

test/
  ├── widget_test.dart
  └── conflict_resolver_test.dart
```

The **routes** registered in `AppRoutes` (see `lib/utils/constants.dart`): splash,
login, onboarding, dashboard, sos, map, safe-route-map, safe-walk, fake-call,
guardian-monitor, report, community, stealth-mode, emergency-dashboard,
guardian-network, risk-alert, profile, settings, emergency-profile,
guardian-approval, incident-history, privacy-console, sync-status.

---

## 🗄️ Data model (Supabase / collections)

All tables live under one Supabase project, referenced by the constants in
`FSCollection` (see `lib/utils/constants.dart`).

| Collection | Purpose |
| --- | --- |
| `users` | user profiles / auth linkage |
| `guardians` / `guardian_requests` | trusted contacts + **request → approve** lifecycle |
| `sos_alerts` | emergencies triggered; `sos_acknowledgements` = responses & resolves |
| `locations` | location update stream |
| `reports` / `dangerzone` | community incident reports + aggregated danger zones |
| `emergency_profiles` | medical conditions, allergies, contacts, insurance, organ-donor |
| `evidence` | evidence-vault media metadata (bucket: `evidence_bucket`) |
| `activity_logs` | audit trail fed into the unified incident timeline |
| `volunteer_alerts`, `mesh_packets`, `mesh_acknowledgements` | nearby volunteers + mesh relay |

> Local mirror: `shared_preferences` caches emergency profile, offline queue,
> active-emergency snapshot, onboarding state, and privacy keystore.

---

## 🚀 Getting started

**Prerequisites:** Flutter **3.x** (with Android, Web, iOS toolchains).

```bash
# 1. Install Flutter & platform toolchains (Android/iOS/Web)
# 2. Fetch dependencies
flutter pub get

# 3. (Optional) Provide your Supabase config via --dart-define
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# 4. Run locally
flutter run

# Useful: pick a platform
flutter run -d chrome          # Web
flutter run -d <android-id>    # Android device
```

> 💡 No Maps API key is required — the map and routing are OSM/OSRM and key-free.

---

## 🔑 Environment variables

Set via `--dart-define=` at build/run time (never hard-code secrets in source).

| Variable | Used for | Notes |
| --- | --- | --- |
| `SUPABASE_URL` | Supabase project URL | replace placeholder |
| `SUPABASE_ANON_KEY` | Supabase anon key | replace placeholder |
| `MAPS_API_KEY` *(legacy)* | — | **no longer required** — maps now use OSM/OSRM |

Placeholders live in `lib/config/env_config.dart`; in CI, inject them as secrets.

---

## 🗺️ Maps — no API key required

The map layer uses **free, keyless** providers:

| Need | Provider | Why |
| --- | --- | --- |
| Tile rendering | **OpenStreetMap** via `flutter_map` | real cross-platform coverage, zero key, zero cost |
| Directions | **OSRM** (`router.project-osrm.org`) | real street/cycling geometry, keyless |
| Safe-places geocoding | **Nominatim** (OSM) | find nearest police / hospital |

The reusable map widget is `lib/widgets/real_map.dart` (`RealMap`): renders tiles,
danger circles, a safe-route polyline, markers, and a live user location
(and it shines on Web — ours runs in the browser without any key).

---

## 🧪 Testing & quality

```bash
flutter analyze                   # expect: No issues found!
flutter test                      # full suite (incl. conflict-resolver tests)
flutter build web --release       # PWA-ready
flutter build apk --release       # Android
```

The codebase is maintained in a **clean-analyzer state** (`0 issues`), with a
growing unit suite that covers the offline sync & conflict-resolution logic.

---

## 🌍 Deployment

### Web → Netlify (current)
1. Build: `flutter build web --release`
2. Deploy the `build/web` folder with the included `netlify.toml` (handles the
   **SPA fallback** so Flutter routes like `/dashboard` resolve to `index.html`):

```bash
netlify deploy --prod --dir=build/web
```

> Deployed example: **https://kawach-safety.netlify.app**

### Android (`android/`)
```bash
flutter build appbundle --release   # Play Store
flutter build apk --release         # side-load
```
Sign with a release keystore via `key.properties`. **Note:** using your own
keystore is required for store release.

### Web for other hosts
Host `build/web` on any static/CDN host (Vercel, Firebase Hosting, etc.). Just make
sure to include an SPA redirect to `index.html`.

### Supabase backend
1. Create a project.
2. Run the SQL migration (`supabase/migrations/*.sql`).
3. Set `SUPABASE_URL` / `SUPABASE_ANON_KEY` for production builds.
4. Enable the storage bucket for evidence (e.g. `evidence_bucket`).

---

## ⚠️ Known integration notes

- **SMS gateway & streaming server** are still placeholders (`AppKeys.smsGatewayUrl`,
  `AppKeys.streamingServerUrl`) — wire real endpoints before a public release.
- **Ringtone** asset (`assets/audio/ringtone.mp3`) referenced by the fake-call
  feature isn't committed yet — drop an MP3 in `assets/audio/` (no code change).
- **Supabase anon key** is a placeholder by default; bake real creds in with
  `--dart-define` for production so DB-backed features work.
- The **Netlify site** may sit behind edge/access-protection until you toggle its
  site to **public** in the Netlify dashboard (Site configuration → Security protection).

---

## 📄 License

Private/internal — contact the project maintainers for usage.

---

<p align="center"><sub>Built with ❤️ by the VAPORLOGIC team · <b>Your Shield. Always.</b></sub></p>
