# iOS Testing & Deployment Guide — ScreenTime App

This guide walks developers and testers through every step needed to build, run, and test the ScreenTime app on a physical iPhone. All commands are run from the repository root unless stated otherwise.

---

## ⚡ One-Command Quick Start

```bash
git clone https://github.com/ddreelan/ScreenTime.git
open ScreenTime/ios/ScreenTime/ScreenTime.xcodeproj
# Then: select your iPhone in the toolbar → ⌘R
```

---

## Table of Contents

1. [Local Development Setup](#1-local-development-setup)
2. [Running on a Physical Device](#2-running-on-a-physical-device)
3. [Required Permissions](#3-required-permissions)
4. [Testing Scenarios](#4-testing-scenarios)
5. [Debugging and Troubleshooting](#5-debugging-and-troubleshooting)
6. [TestFlight Distribution](#6-testflight-distribution)
7. [Performance Testing](#7-performance-testing)

---

## 1. Local Development Setup

### 1.1 System Requirements

| Requirement | Value |
|-------------|-------|
| macOS | 15 Sequoia |
| Xcode | 26.3 (Build 17C529) |
| Swift | 6.2.4 |
| iOS SDK | 16.0+ |
| iPhone / iOS | iOS 16.0+ |

### 1.2 Install Xcode

1. Open **App Store** on your Mac and search for **Xcode**.
2. Click **Get / Install** (the download is ~7–10 GB).
3. After installation, launch Xcode once to accept the license agreement and install the command-line tools when prompted.
4. Verify the installation:
   ```bash
   xcode-select -p        # Should print /Applications/Xcode.app/Contents/Developer
   swift --version        # Should print Apple Swift version 6.2.4
   xcodebuild -version    # Should print Xcode 26.3
   ```
5. Install additional iOS simulators if required:
   - **Xcode → Settings → Platforms → iOS** → click **+** to download a simulator runtime.

### 1.3 Clone and Open the Project

```bash
git clone https://github.com/ddreelan/ScreenTime.git
```

The repository includes a pre-built **`ScreenTime.xcodeproj`** — simply open it:

```bash
open ScreenTime/ios/ScreenTime/ScreenTime.xcodeproj
```

> **Tip:** You can also double-click `ScreenTime.xcodeproj` in Finder.

Xcode will open the project with all Swift source files already configured. No additional package resolution is required (there are no external dependencies).

The iOS app also uses **Swift Package Manager (SPM)** for its internal target structure — the `Package.swift` manifest is included alongside the `.xcodeproj` for reference and command-line builds.

### 1.4 Configure the Deployment Target

The minimum deployment target is already set to **iOS 16** in both `Package.swift` and the `.xcodeproj`:

```swift
platforms: [
    .iOS(.v16)
]
```

No changes are required. If you want to test on an older device, update the version in `Package.swift` and in the project's **Build Settings → iOS Deployment Target**.

### 1.5 Dependency Management

The project uses Swift Package Manager exclusively and has no external dependencies. To add a new dependency in the future:

1. In Xcode: **File → Add Package Dependencies…**
2. Enter the package URL and select a version rule.
3. The `Package.swift` manifest is updated automatically.

To resolve/refresh packages from the command line:

```bash
cd ios/ScreenTime
swift package resolve
swift package update   # upgrades to latest compatible versions
```

---

## 2. Running on a Physical Device

### 2.1 Apple Developer Account

A **free** Apple ID lets you sideload the app for up to 7 days before the certificate expires and the app must be re-signed. A **paid** Apple Developer Program membership ($99/year) removes that limit and is required for TestFlight and App Store distribution.

1. Go to [developer.apple.com](https://developer.apple.com) and sign in (or enrol) with your Apple ID.
2. In Xcode: **Settings → Accounts → +** → **Apple ID** → sign in with the same account.

### 2.2 Open the Xcode Project

The repository ships with a ready-to-use **`ScreenTime.xcodeproj`** — you no longer need to create a host project manually.

```bash
open ios/ScreenTime/ScreenTime.xcodeproj
```

Xcode opens the project with all source files configured and the `ScreenTime` scheme pre-set to build an iOS App target.

### 2.3 Code Signing

1. Select the project root in the **Project Navigator**.
2. Select the app target → **Signing & Capabilities** tab.
3. Check **Automatically manage signing**.
4. Choose your **Team** from the drop-down.
5. Xcode provisions a Development certificate and a wildcard provisioning profile automatically.

If you see **"No matching provisioning profiles found"**:
- Ensure your device is registered (see [Register Your iPhone](#24-register-your-iphone)).
- Click **Try Again** or **Download Manual Profiles** in the banner.

For manual signing (CI/CD pipelines), export the provisioning profile from [developer.apple.com/account](https://developer.apple.com/account) and install it by double-clicking the `.mobileprovision` file.

### 2.4 Register Your iPhone

**Automatic (recommended):**

1. Connect your iPhone to your Mac with a USB-C or Lightning cable.
2. On the iPhone, tap **Trust** when the "Trust This Computer?" alert appears.
3. Open Xcode — your device appears in **Window → Devices and Simulators**.
4. Xcode automatically registers the device UDID with your developer account when you first build for it.

**Manual:**

1. Find the UDID in **Window → Devices and Simulators** (copy from the detail panel).
2. Log in to [developer.apple.com](https://developer.apple.com) → **Certificates, IDs & Profiles → Devices → +**.
3. Enter the UDID and a device name → **Register**.
4. In Xcode, refresh provisioning profiles: **Settings → Accounts → [your account] → Download Manual Profiles**.

### 2.5 Trust the Developer Certificate on iPhone

After the app is installed for the first time via a free Apple ID, iOS blocks it by default.

1. On your iPhone go to **Settings → General → VPN & Device Management**.
2. Tap your developer certificate (listed under **Developer App**).
3. Tap **Trust "[your Apple ID]"** → **Trust**.

Apps signed with a paid developer account provisioning profile do not require this step.

### 2.6 Build and Run on iPhone

1. In Xcode, select your iPhone in the device picker at the top of the toolbar (it appears once connected and trusted).
2. Press **⌘ R** (or click the **▶ Run** button).
3. Xcode compiles the app, installs it on the device, and launches it.
4. The app icon appears on the Home Screen and the debugger attaches automatically.

**Run from the command line** (headless / CI):

```bash
cd ios/ScreenTime
xcodebuild \
  -project ScreenTime.xcodeproj \
  -scheme ScreenTime \
  -destination 'platform=iOS,id=<DEVICE_UDID>' \
  -configuration Debug \
  build
```

Replace `<DEVICE_UDID>` with the 40-character UDID from **Window → Devices and Simulators**.

---

## 3. Required Permissions

The ScreenTime app requests the following permissions at runtime. Each permission is explained with the in-app trigger that requests it.

### 3.1 Notifications (`UNUserNotificationCenter`)

**Why:** The app sends screen time warnings (5-minute alert, limit reached), break reminders, activity completion celebrations, and daily streak notifications.

**When requested:** On first launch (inside `ScreenTimeApp.swift` `onAppear`).

**iOS permission key (add to `Info.plist`):**

```xml
<key>NSUserNotificationUsageDescription</key>
<string>ScreenTime sends reminders when your daily screen time is running low and celebrates when you complete activities.</string>
```

**Test it:** Deny once, open **Settings → ScreenTime → Notifications**, and re-enable to verify the flow.

### 3.2 Motion & Fitness (`CoreMotion`)

**Why:** `ActivityVerificationService` uses the accelerometer to detect physical movement (walking, exercise) and the step counter via `CMPedometer`.

**When requested:** When a user starts an activity that uses `.accelerometer` verification.

**iOS permission key:**

```xml
<key>NSMotionUsageDescription</key>
<string>ScreenTime uses motion data to verify physical activities like walking and exercise so you can earn extra screen time.</string>
```

### 3.3 Location — When In Use (`CoreLocation`)

**Why:** `ActivityVerificationService` calls `locationManager.requestWhenInUseAuthorization()` for `.geolocation` activities (outdoor walks, GPS verification).

**When requested:** When a user starts an outdoor activity.

**iOS permission key:**

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ScreenTime uses your location to verify outdoor activities and earn you extra screen time.</string>
```

> Only "when in use" authorization is needed; the app does not track location in the background.

### 3.4 Summary of `Info.plist` Entries

Add the following keys to your app target's `Info.plist` before running on device:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>ScreenTime sends reminders when your daily screen time is running low and celebrates when you complete activities.</string>

<key>NSMotionUsageDescription</key>
<string>ScreenTime uses motion data to verify physical activities like walking and exercise so you can earn extra screen time.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>ScreenTime uses your location to verify outdoor activities and earn you extra screen time.</string>
```

> **Note on Apple's Screen Time API (`FamilyControls`):** The system-level Screen Time API requires the `com.apple.developer.family-controls` entitlement, which must be approved by Apple. The current implementation uses its own in-app timer and does not enforce system-level restrictions. If you integrate `FamilyControls` in the future, add the entitlement through the **Signing & Capabilities** tab and note that testing requires a physical device (not a Simulator).

---

## 4. Testing Scenarios

Run each scenario on a physical device to validate end-to-end behaviour.

### 4.1 Daily Screen Time Allocation

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Open the app → Dashboard | Time ring shows full allocated budget (default 2 hours) |
| 2 | Settings → Daily Allocation → change to 30 minutes | Ring and remaining-time label update immediately |
| 3 | Leave the app running for 1 minute | Remaining time decreases by ~1 minute |
| 4 | Force-quit and reopen the app | Remaining time is persisted (UserDefaults) |

### 4.2 Reward System

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Settings → App Configs → Add app as Reward (+1.0 min/min) | App appears in reward list |
| 2 | Dashboard → Start a Walking activity | Verification screen opens |
| 3 | Complete 20 taps (tap-count verification) | "Activity verified!" message shown |
| 4 | Return to Dashboard | Earned minutes are added to remaining time |
| 5 | Notification received | "Activity Complete 🎉" push notification delivered |

### 4.3 Penalty System

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Settings → App Configs → Add app as Penalty (−2.0 min/min) | App appears in penalty list |
| 2 | Simulate using that app for 5 minutes | Remaining time decreases by 10 extra minutes (5 × 2.0) |
| 3 | Dashboard → Analytics | Penalty appears in daily breakdown |

### 4.4 Activity Verification Methods

Test each verification method from **Activities** screen:

| Activity Type | Verification | How to Test |
|---------------|-------------|-------------|
| Walking / Exercise | Accelerometer | Walk around with the device; progress bar fills as motion is detected |
| Reading / Meditation | Scroll detection | Scroll through any content in the verification view |
| Meditation | Tap count | Tap the screen 20 times |
| Outdoor / GPS | Geolocation | Go outside or enable a location mock in Xcode (Debug → Simulate Location) |
| Custom | Manual | Tap "Complete" after the desired duration |

### 4.5 App-Specific Settings Configuration

1. Open **Settings → App Configurations**.
2. Add a new app:
   - Bundle identifier, display name, type (Reward / Penalty / Neutral), minutes-per-minute ratio.
3. Verify the entry appears in the list.
4. Edit the ratio slider and confirm the updated value persists after closing and reopening the app.
5. Delete the app config and confirm it is removed from the list.

### 4.6 Notification Delivery

1. Grant notification permission on first launch.
2. Reduce the daily allocation to 2 minutes.
3. Wait for the 5-minute warning (fires when `remainingTime == 300` seconds).

   > **Quick test:** In a debug-only build configuration, temporarily lower the threshold to 5 seconds to accelerate the test cycle. Use a `#if DEBUG` guard so the change is never shipped in a release build. Remember to revert before committing.
   >
   > ```swift
   > #if DEBUG
   > } else if remainingTime == 5 { // accelerated threshold for testing only
   > #else
   > } else if remainingTime == 300 { // 5 minutes warning
   > #endif
   > ```

4. Let the timer reach 0 and confirm the "Screen Time Limit Reached" notification fires.
5. Complete an activity and confirm the "Activity Complete 🎉" notification fires.
6. Verify the daily motivation notification fires at 9:00 AM.

### 4.7 Data Persistence

1. Record several activities and app-config changes.
2. Force-quit the app (**App Switcher → swipe up**).
3. Relaunch and confirm all data is present.
4. Reboot the device and relaunch — all UserDefaults-backed data should survive.

### 4.8 Analytics and Achievements

1. Use the app for a few days (or adjust timestamps in `DataStore` during debugging).
2. Open the **Analytics** tab and verify:
   - Bar chart reflects daily usage.
   - Achievement badges unlock at the correct milestones.
3. Complete activities on consecutive days and verify the streak counter increments.

---

## 5. Debugging and Troubleshooting

### 5.1 Using Xcode Debugger

- **Breakpoints:** Click the line-number gutter to set a breakpoint. Use **⌘ Y** to enable/disable all breakpoints.
- **LLDB Console:** `po <expression>` in the debug console prints any variable.
- **View Debugger:** **Debug → View Debugging → Capture View Hierarchy** inspects the live SwiftUI tree.
- **Memory Graph:** **Debug → Debug Memory Graph** identifies retain cycles and leaks.

### 5.2 Console Logging

All services use `print()` for debug output. To follow logs on a connected device:

```bash
# Stream all ScreenTime process logs
xcrun devicectl device syslog stream --device <DEVICE_UDID> \
  --predicate 'process == "ScreenTime"'
```

Or use **Xcode → Window → Devices and Simulators → [device] → Open Console** for a graphical log viewer.

### 5.3 Common Setup Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Untrusted Developer" alert | Free provisioning, first install | **Settings → General → VPN & Device Management → Trust** |
| "No provisioning profiles found" | Device UDID not registered | Register device in Apple Developer portal; refresh profiles in Xcode |
| Build error: "Missing `Info.plist` keys" | Permission descriptions absent | Add the three `NSUsageDescription` keys (§3.4) |
| "Signing certificate expired" | Free cert valid 7 days | Reconnect device; Xcode re-provisions automatically |
| Device not appearing in Xcode | USB or trust issue | Use a different cable; re-trust on device; restart `usbmuxd`: `sudo launchctl stop com.apple.usbmuxd` |
| "Swift Compiler Error: module not found" | SPM cache stale | **Product → Clean Build Folder (⇧ ⌘ K)** then rebuild |
| Notifications not delivered | Permission denied | **Settings → ScreenTime → Notifications → Allow Notifications** |
| Location permission denied | Alert dismissed | **Settings → Privacy & Security → Location Services → ScreenTime → While Using** |
| Motion permission denied | Alert dismissed | **Settings → Privacy & Security → Motion & Fitness → ScreenTime → ON** |
| App crashes on launch | Missing `@main` or environment objects | Confirm `ScreenTimeApp.swift` is the app entry point and all `@EnvironmentObject` providers are injected |

### 5.4 Simulating Locations

To test geolocation verification without leaving your desk:

1. Connect the device and run the app.
2. In Xcode: **Debug → Simulate Location → [choose a preset]** (e.g., "City Bicycle Ride").
3. Or create a custom `.gpx` file and add it via **Debug → Simulate Location → Add GPX File to Project…**.

### 5.5 Resetting App State

To start fresh without reinstalling:

```swift
// Paste into LLDB console or add to a debug-only "Reset" button
if let bundleId = Bundle.main.bundleIdentifier {
    UserDefaults.standard.removePersistentDomain(forName: bundleId)
}
```

Or delete the app from the device (long-press → **Remove App**) and reinstall.

---

## 6. TestFlight Distribution

TestFlight lets you distribute the app to up to 10,000 external testers without App Store review (external testers require a brief beta review).

### 6.1 Prerequisites

- Active **Apple Developer Program** membership.
- App record created in [App Store Connect](https://appstoreconnect.apple.com).

### 6.2 Set Up App Store Connect

1. Log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
2. **My Apps → +** → **New App**.
3. Fill in:
   - **Platform:** iOS
   - **Name:** ScreenTime
   - **Bundle ID:** must match exactly what is in your Xcode project.
   - **SKU:** any unique identifier.
4. Click **Create**.

### 6.3 Archive and Upload the Build

1. In Xcode, select **Any iOS Device (arm64)** as the destination.
2. **Product → Archive** (this creates a release build; may take several minutes).
3. In the **Organizer** window that opens, select the new archive.
4. Click **Distribute App → TestFlight & App Store → Next**.
5. Choose **Upload** and follow the wizard — Xcode uploads the build to App Store Connect.

From the command line (useful in CI):

```bash
xcodebuild archive \
  -scheme ScreenTime \
  -configuration Release \
  -archivePath /tmp/ScreenTime.xcarchive

xcodebuild -exportArchive \
  -archivePath /tmp/ScreenTime.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath /tmp/ScreenTimeExport

xcrun altool --upload-app \
  -f /tmp/ScreenTimeExport/ScreenTime.ipa \
  -u "your@apple.id" \
  -p "@keychain:AC_PASSWORD"
```

### 6.4 Add Internal Testers

1. In App Store Connect, go to **TestFlight → [your build] → Internal Testing**.
2. Click **+** next to **Testers** → select App Store Connect users with Developer or Admin roles.
3. They receive an email to install TestFlight and the build automatically.

### 6.5 Add External Testers

1. **TestFlight → External Groups → + New Group**.
2. Add the build and submit for **Beta App Review** (~24 hours).
3. Once approved, share the **Public Link** or invite testers by email.
4. Testers install the **TestFlight** app from the App Store, then tap your invitation link.

### 6.6 Collecting Feedback

- Testers shake the device while using the app → **Send Feedback** dialog appears (screenshot + comment).
- All feedback is visible in App Store Connect under **TestFlight → Feedback**.
- Crashes are automatically symbolicated and appear in **Xcode → Organizer → Crashes**.

---

## 7. Performance Testing

### 7.1 Memory Usage

1. Run the app on a physical device (Simulator memory is not representative).
2. In Xcode: **Product → Profile (⌘ I)** → choose the **Leaks** or **Allocations** instrument.
3. Exercise the main user flows: start/stop activities, change settings, navigate all screens.
4. Look for:
   - **Allocations growth** — steady increase indicates a memory leak.
   - **Leaked objects** — objects shown in the Leaks timeline.
5. Common sources in this app:
   - `Combine` subscriptions not stored in `cancellables` sets.
   - Closures in `Timer` or `NotificationCenter` observers that capture `self` strongly.

### 7.2 Battery Impact

1. In Instruments, choose the **Energy Log** template.
2. Run the app for 15–30 minutes with activities active (especially location tracking).
3. Monitor the **CPU**, **Location**, and **Networking** usage lanes.
4. Optimisation tips:
   - Stop `CMMotionManager` updates (`stopAccelerometerUpdates()`) as soon as verification completes — `ActivityVerificationService` already does this.
   - Call `locationManager.stopUpdatingLocation()` immediately after a GPS fix — also already implemented.
   - Prefer `CLLocationManager` with `desiredAccuracy = kCLLocationAccuracyHundredMeters` for outdoor activities where exact GPS is not needed.

### 7.3 Background Process Optimization

The app's `ScreenTimeService` timer runs on the main `RunLoop`. When the app is backgrounded:

- iOS suspends the app after ~30 seconds; the timer stops ticking.
- On foreground resume, call `updateRemainingTime()` to reconcile elapsed time using `Date()` comparison.
- To track time while the app is in the background, migrate the timer to a `BackgroundTask` (register with `UIApplication.shared.beginBackgroundTask`) or use `BGProcessingTask` / `BGAppRefreshTask` from `BackgroundTasks.framework`.

### 7.4 Instruments Quick Reference

| Template | Use Case |
|----------|----------|
| **Allocations** | Track heap growth and object lifetimes |
| **Leaks** | Detect reference cycles and leaked memory |
| **Energy Log** | CPU, GPU, location, and network energy usage |
| **Time Profiler** | Find CPU hotspots causing UI stutters |
| **Core Animation** | Frame-rate and rendering bottlenecks |
| **Network** | API call timing and payload sizes |

Launch Instruments: **Xcode → Open Developer Tool → Instruments**, or **⌘ I** from an active Xcode session.

---

## Quick-Start Checklist

Use this checklist before handing the device to a tester:

- [ ] Xcode 26.3+ installed and command-line tools accepted
- [ ] Developer account added in **Xcode → Settings → Accounts**
- [ ] `ios/ScreenTime/ScreenTime.xcodeproj` opened in Xcode
- [ ] iPhone connected via USB and trusted
- [ ] Team selected in **Signing & Capabilities** (your Apple ID team)
- [ ] Bundle ID `com.ddreelan.ScreenTime` (or customised to your org) matches provisioning profile
- [ ] `Info.plist` present at `ios/ScreenTime/ScreenTime/Info.plist` with all three `NSUsageDescription` keys
- [ ] App built and installed successfully (no code-signing errors)
- [ ] Certificate trusted on device (**Settings → General → VPN & Device Management**)
- [ ] Notification permission granted on first launch
- [ ] Motion permission granted when starting an activity
- [ ] Location permission granted when starting an outdoor activity
- [ ] Data persistence verified after force-quit and relaunch
- [ ] All five testing scenarios (§4.1–4.8) completed

---

*For additional questions, open an issue in the [ScreenTime repository](https://github.com/ddreelan/ScreenTime).*
