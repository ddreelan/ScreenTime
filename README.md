# ScreenTime — Screen Time Management App

A comprehensive cross-platform mobile app for managing daily screen time. Users receive a configurable daily screen time budget that can be grown through real-world activities or diminished by using high-penalty apps.

## Overview

ScreenTime empowers users to take control of their device usage through:

- **Daily Screen Time Budget** — configurable per-day allocation
- **Reward System** — use productivity/health apps to earn extra minutes
- **Penalty System** — time-wasting apps cost extra screen time
- **Activity Verification** — sensor-based verification (accelerometer, tap count, scroll detection, GPS)
- **Analytics Dashboard** — daily and weekly usage insights
- **Achievements & Gamification** — streaks, badges, and milestones
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
│       │   ├── Models/      # Data models
│       │   ├── Services/    # DataStore, ScreenTimeService, etc.
│       │   ├── ViewModels/  # MVVM view models
│       │   └── Views/       # SwiftUI views
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
│           │   ├── ui/      # Compose screens and theme
│           │   ├── service/ # Background tracking service
│           │   └── notification/
│           └── test/
│
└── backend/                 # Node.js/Express REST API
    ├── src/
    │   ├── routes/          # Auth, users, app-configs, screen-time, activities, analytics
    │   ├── middleware/       # JWT auth, error handler
    │   └── utils/           # SQLite database, logger
    └── tests/
```

---

## iOS App

**Requirements:** iOS 16+, Xcode 15+, Swift 5.9

**Architecture:** MVVM with Combine

**Key screens:**
| Screen | Description |
|--------|-------------|
| Dashboard | Animated time ring, stats, quick-start activities |
| Activities | Start & verify real-world activities to earn time |
| Analytics | Bar chart history, achievement gallery |
| Settings | Configure reward/penalty apps with sliders |
| Profile | User name, age, goals |

**Services:**
- `DataStore` — UserDefaults persistence, central state
- `ScreenTimeService` — Real-time countdown timer
- `ActivityVerificationService` — CoreMotion + CoreLocation verification
- `NotificationService` — UNUserNotificationCenter alerts

---

## Android App

**Requirements:** Android 8.0+ (API 26), Kotlin 1.9+

**Architecture:** MVVM + Repository with Room + Coroutines/Flow

**Key screens:** Dashboard, Activities, Analytics, Profile, Settings

**Features:**
- Room database with full CRUD for all entities
- Accelerometer-based physical activity verification
- Foreground service for background screen time tracking
- Material 3 dynamic color theming

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
# Set a strong JWT_SECRET in .env
npm install
npm run dev
```

### API Base URL
`http://localhost:3000/api/v1`

### Core Endpoints

| Category | Endpoints |
|----------|-----------|
| Auth | `POST /auth/register`, `POST /auth/login` |
| Profile | `GET/PUT /users/me` |
| App Configs | `GET/POST/PUT/DELETE /app-configs` |
| Screen Time | `GET/PUT /screen-time/summary/today`, `GET /screen-time/summaries` |
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
