# ScreenTime Android App

A Kotlin/Jetpack Compose Android application for managing daily screen time with a configurable reward and penalty system.

## Architecture

- **MVVM + Repository Pattern**
- **Jetpack Compose** for declarative UI
- **Room Database** for local persistence
- **Kotlin Coroutines + Flow** for async data streams
- **WorkManager** for background scheduling

## Key Components

### Data Layer
- **Room Database** (`AppDatabase`) with type-safe entities
- **DAOs**: UserProfileDao, AppConfigDao, ScreenTimeDao, ActivityDao, AchievementDao
- **Repository**: `ScreenTimeRepository` — single source of truth

### ViewModel Layer
- `DashboardViewModel` — daily summary, motivational messages
- `SettingsViewModel` — app config CRUD, daily limit management
- `ActivityViewModel` — activity lifecycle, sensor-based verification

### UI Layer (Compose Screens)
- `DashboardScreen` — animated time ring, stats, quick start
- `ActivitiesScreen` — activity picker, verification flow, history
- `SettingsScreen` — reward/penalty app configuration with sliders
- `AnalyticsScreen` — usage trends and app breakdown
- `ProfileScreen` — user profile and goals management

### Services & Background
- `ScreenTimeTrackingService` — foreground service for background tracking
- `NotificationHelper` — channel management and notification dispatch
- `BootReceiver` — re-initialize notifications on device restart

## Requirements
- Android 8.0+ (API 26+)
- Kotlin 1.9+
- Gradle 8.1+
