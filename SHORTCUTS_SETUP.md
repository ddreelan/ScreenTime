# Shortcuts Setup Instructions

Here is exactly how to set up the automation for each app (e.g. YouTube). Repeat for every reward/penalty app.

---

## Open automation (fires when the app opens)

1. Open **Shortcuts** → tap the **Automation** tab → tap **+**
2. Tap **App** → search for and select **YouTube** → tick **Is Opened** only → tap **Next**
3. Tap **New Blank Automation**
4. Tap **+** → search for **Get Contents of URL** → add it
5. Set the URL to your **Status URL** (copy from the *Set Up Shortcut* sheet in Settings)
6. Leave method as **GET**, no body
7. Tap **+** → search for **If** → add it
8. Set condition: **Input** → **Contains** → type `ready`
9. Inside the **If** block, tap **+** → add another **Get Contents of URL**
10. Set the URL to your **Start URL** (copy from the *Set Up Shortcut* sheet in Settings)
11. Leave method as **GET**, no body
12. Tap the **X** to close the action editor
13. Tap the **ⓘ** info icon at the bottom → change **Run After Confirmation** to **Run Immediately** → tap **Done**

---

## Close automation (fires when the app closes)

1. Tap **+** → **App** → select **YouTube** → tick **Is Closed** only → tap **Next**
2. Tap **New Blank Automation**
3. Tap **+** → search for **Get Contents of URL** → add it
4. Set the URL to your **Stop URL** (copy from the *Set Up Shortcut* sheet in Settings)
5. Leave method as **GET**, no body
6. Tap the **ⓘ** info icon → change **Run After Confirmation** to **Run Immediately** → tap **Done**

---

## How it works end to end

```
User opens YouTube
  → "Is Opened" automation fires
  → GET /status?bundleID=com.google.ios.youtube  →  "ready"
  → If "ready": GET /startApp?bundleID=com.google.ios.youtube
      → LocalServer sets status = "triggered"
      → ScreenTimeService starts tracking
      → ScreenTimeApp opens youtube:// to return user
          → "Is Opened" automation fires again
          → GET /status?bundleID=...  →  "triggered"
          → If condition false → automation stops ✓ (loop broken)
      → After 3 seconds: status resets to "ready"

User closes YouTube
  → "Is Closed" automation fires
  → GET /stopApp?bundleID=com.google.ios.youtube
      → LocalServer sets status = "ready"
      → ScreenTimeService stops tracking ✓
```
