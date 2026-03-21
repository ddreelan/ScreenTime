# ScreenTime iOS App

A SwiftUI-based iOS application for managing daily screen time with a configurable reward and penalty system.

## Architecture

- **MVVM Pattern** with SwiftUI
- **Combine** for reactive data flow
- **UserDefaults** for local persistence

## Key Components

### Models
- `UserProfile` - User data and settings
- `AppConfig` - Reward/penalty app configurations
- `ScreenTimeEntry` / `DailyScreenTimeSummary` - Time tracking
- `Activity` - Verified real-world activities
- `Achievement` - Gamification achievements

### Services
- `DataStore` - Central data persistence and state management
- `ScreenTimeService` - Real-time screen time tracking
- `ActivityVerificationService` - Verify physical activities via sensors
- `NotificationService` - Break reminders and alerts

### Views
- `DashboardView` - Daily progress ring and quick actions
- `SettingsView` - Configure reward/penalty apps and daily limits
- `ActivityVerificationView` - Start and verify activities
- `AnalyticsView` - Usage history and achievements
- `ProfileView` - User profile and goals

## Requirements
- iOS 16.0+
- Xcode 15+
- Swift 5.9+
