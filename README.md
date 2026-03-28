# ScreenTime — Screen Time Management App

A comprehensive cross-platform mobile app for managing daily screen time. Users receive a configurable daily screen time budget that can be grown through real-world activities or diminished by using high-penalty apps.

## Overview

ScreenTime empowers users to take control of their device usage through:

- **Daily Screen Time Budget** — configurable per-day allocation
- **Reward System** — use productivity/health apps to earn extra minutes
- **Penalty System** — time-wasting apps cost extra screen time
- **Default Penalty for Unconfigured Apps** — configurable rate (default −1.0 min/min) for apps not in reward/penalty lists
- **Self-App Exemption** — ScreenTime itself is treated as neutral (zero penalty/reward)
- **Activity Verification** — sensor-based verification (accelerometer, tap count, scroll detection, GPS)
- **Enhanced Analytics** — per-app reward/penalty breakdown, daily usage timeline line graph with color-coded segments and interactive touch/drag tooltips
- **Timeline Data Model** — `TimelineDataPoint` snapshots every 30 s during active tracking
- **24 Achievements** — both platforms share 24 achievements with bonus screen time rewards (`timeRewardSeconds`)
- **Email/Password Authentication** — SHA-256 + salt hashing, iOS Keychain / Android SharedPreferences, auth gates the app
- **OAuth Sign-in (Stubs)** — Google, Apple (iOS), Facebook OAuth redirect flow stubs with TODO markers for real client IDs
- **Loading Splash Screen** — animated ring progress, app name, dark gradient background, auto-advances after ~2.2 s
- **Quick Start Buttons** — dashboard buttons open timer sheets, track elapsed time, and save verified activities with earned rewards
- **Native App Tracking (Android)** — `UsageStatsManager` polling via `AppUsageTrackingWorker`
- **Official App Logos** — SF Symbols (iOS) and Material Icons (Android); Android loads real app icons via `PackageManager`
- **Decimal Input for Time Effect** — TextField alongside Slider for precise 0.1–5.0 input in app config settings
- **Notifications** — break reminders and usage alerts

---

## Project Structure

```
ScreenTime/
├── AGENT_PROMPT.md          # Original design specifications
├── README.md                # This file
│
├── ios/                     # iOS app (Swift/SwiftUI, iOS 16+)
│   └── ScreenTime/
│       ├── Package.swift
│       ├── Sources/
│       │   ├── App/         # Entry point, ContentView
│       │   ├── Models/      # Data models (incl. TimelineDataPoint.swift)
│       │   ├── Services/    # DataStore, ScreenTimeService, AuthService.swift, etc.
│       │   ├── ViewModels/  # MVVM view models
│       │   └── Views/       # SwiftUI views (SignInView, SplashView, …)
│       └── Tests/
│
├── android/                 # Android app (Kotlin/Jetpack Compose, API 26+)
│   ├── build.gradle
│   ├── settings.gradle
│   └── app/
│       └── src/
│           ├── main/java/com/screentime/app/
│           │   ├── data/    # Models, Room DB, DAOs, Repository
│           │   ├── viewmodel/
│           │   ├── ui/      # Compose screens (SignInScreen, SplashScreen, …)
│           │   ├── service/ # Background tracking, AppUsageTrackingWorker, AchievementChecker
│           │   └── notification/
│           └── test/
│
└── backend/                 # Node.js/Express REST API
    ├── src/
    │   ├── routes/          # Auth (incl. OAuth), users, app-configs, screen-time, activities, analytics
    │   ├── middleware/       # JWT auth, error handler
    │   └── utils/           # SQLite database, logger
    └── tests/               # screenTime.test.js, …
```

---

## iOS App

**Requirements:** iOS 16+, Xcode 26+, Swift 6.2+

**Quick Start:** A pre-built `ScreenTime.xcodeproj` is included — open it directly in Xcode and hit ⌘R to run on your iPhone. No need to create a host project manually.

```bash
open ios/ScreenTime/ScreenTime.xcodeproj
```

**Architecture:** MVVM with Combine

**Key screens:**
| Screen | Description |
|--------|-------------|
| Splash | Animated ring progress with app name; auto-advances after ~2.2 s |
| Sign In | Email/password login + OAuth stubs (Google, Apple, Facebook) |
| Dashboard | Animated time ring, stats, quick-start activity buttons (open timer sheets) |
| Activities | Start & verify real-world activities to earn time |
| Analytics | Per-app breakdown, daily timeline line graph with color-coded segments & tooltips, achievement gallery |
| Settings | Configure reward/penalty apps with sliders + decimal TextField (0.1–5.0), default penalty rate |
| Profile | User name, age, goals |

**Services:**
- `DataStore` — UserDefaults persistence, central state
- `ScreenTimeService` — Real-time countdown timer
- `ActivityVerificationService` — CoreMotion + CoreLocation verification
- `NotificationService` — UNUserNotificationCenter alerts
- `AuthService` — SHA-256 + salt password hashing, Keychain storage

---

## Android App

**Requirements:** Android 8.0+ (API 26), Kotlin 1.9+

**Architecture:** MVVM + Repository with Room + Coroutines/Flow

**Key screens:** Dashboard, Activities, Analytics, Profile, Settings

**Features:**
- Room database with full CRUD for all entities
- Accelerometer-based physical activity verification
- Foreground service for background screen time tracking
- Native app tracking via `UsageStatsManager` (`AppUsageTrackingWorker`)
- `AchievementChecker` evaluates 24 achievements with `timeRewardSeconds`
- `AuthService` with SHA-256 + salt hashing; credentials in SharedPreferences
- Splash screen and sign-in screen (email/password + OAuth stubs)
- Material 3 dynamic color theming
- Real app icons loaded via `PackageManager`

### Running Tests
```bash
cd android
./gradlew test
```

---

## Backend API

**Requirements:** Node.js 18+

**Stack:** Express 4, SQLite3, JWT, bcrypt, helmet

### Quick Start
```bash
cd backend
cp .env.example .env
```

Open `.env` and replace the `JWT_SECRET` placeholder with a real secret. You can generate one with:
```bash
openssl rand -base64 64
```

Then install dependencies and start the server:
```bash
npm install
npm run dev
```

> **Note:** The server will refuse to start if `JWT_SECRET` is not set. Make sure you edit `.env` before running `npm run dev`.

### API Base URL
`http://localhost:3000/api/v1`

### Core Endpoints

| Category | Endpoints |
|----------|-----------|
| Auth | `POST /auth/register`, `POST /auth/login` |
| OAuth | `POST /auth/oauth/google`, `POST /auth/oauth/apple`, `POST /auth/oauth/facebook` |
| Profile | `GET/PUT /users/me` |
| App Configs | `GET/POST/PUT/DELETE /app-configs` |
| Screen Time | `GET/PUT /screen-time/summary/today`, `GET /screen-time/summaries` |
| Timeline | `POST /screen-time/timeline`, `GET /screen-time/timeline?date=YYYY-MM-DD` |
| Activities | `GET/POST /activities`, `PUT /activities/:id` |
| Analytics | `GET /analytics/overview?days=7` |
| Achievements | `GET /achievements`, `PUT /achievements/:id` |

### Running Tests
```bash
cd backend
npm test
```

---

## Core Concepts

### Reward/Penalty System

Each app can be configured as:
- **Reward** (`minutesPerMinute > 0`): Using this app for 1 minute earns N extra minutes
- **Penalty** (`minutesPerMinute < 0`): Using this app for 1 minute costs N extra minutes
- **Neutral**: No effect on screen time budget

**Example:** If Duolingo is set to `+1.0 min/min`, spending 20 minutes on Duolingo earns 20 extra minutes of screen time.

### Activity Verification

Activities are verified through device sensors:

| Activity Type | Verification Method |
|---------------|---------------------|
| Walking/Running/Exercise | Accelerometer motion detection |
| Reading | Scroll distance tracking |
| Meditation | Tap count (mindful tapping) |
| Custom | Manual completion |
| Outdoor | GPS location updates |

### Daily Budget Calculation

```
remaining = allocated + earned - used - penalty
```

---

## Security

- JWT authentication with configurable expiry
- Passwords hashed with bcrypt (12 rounds)
- Rate limiting (100 req/15 min per IP)
- Helmet security headers
- Input validation on all endpoints
- Parameterized SQL queries (no injection risk)
- User data isolation via foreign keys

---

## License

MIT
