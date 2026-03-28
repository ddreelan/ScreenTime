package com.screentime.app.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

// ─── User Profile ────────────────────────────────────────────────────────────

@Entity(tableName = "user_profiles")
data class UserProfile(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val age: Int,
    val dailyScreenTimeLimitSeconds: Long = 7200L, // 2 hours default
    val defaultPenaltyRate: Double = -1.0,
    val goals: String = "", // JSON-encoded list
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

// ─── App Configuration ────────────────────────────────────────────────────────

enum class AppConfigType { REWARD, PENALTY, NEUTRAL }

@Entity(tableName = "app_configs")
data class AppConfig(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val packageName: String,
    val appName: String,
    val appIcon: String? = null,
    val configType: AppConfigType = AppConfigType.NEUTRAL,
    val minutesPerMinute: Double = 0.0, // positive = earn, negative = cost
    val isEnabled: Boolean = true,
    val category: String = "Other"
) {
    val effectDescription: String get() = when (configType) {
        AppConfigType.REWARD -> "+%.1f min/min".format(minutesPerMinute)
        AppConfigType.PENALTY -> "%.1f min/min".format(minutesPerMinute)
        AppConfigType.NEUTRAL -> "No effect"
    }
}

// ─── Screen Time Entry ────────────────────────────────────────────────────────

@Entity(tableName = "screen_time_entries")
data class ScreenTimeEntry(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val appPackageName: String,
    val appName: String,
    val startTime: Long = System.currentTimeMillis(),
    val endTime: Long? = null,
    val durationSeconds: Long = 0L,
    val timeEarnedOrSpentSeconds: Long = 0L,
    val date: Long = todayStartMillis()
)

@Entity(tableName = "daily_summaries")
data class DailyScreenTimeSummary(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val date: Long = todayStartMillis(),
    val totalAllocatedSeconds: Long = 7200L,
    val totalUsedSeconds: Long = 0L,
    val totalEarnedSeconds: Long = 0L,
    val totalPenaltySeconds: Long = 0L
) {
    val remainingSeconds: Long get() = maxOf(0L, totalAllocatedSeconds + totalEarnedSeconds - totalUsedSeconds - totalPenaltySeconds)
    val usagePercentage: Float get() {
        val total = totalAllocatedSeconds + totalEarnedSeconds
        return if (total > 0) minOf(1f, totalUsedSeconds.toFloat() / total.toFloat()) else 0f
    }
}

// ─── Activity ─────────────────────────────────────────────────────────────────

enum class ActivityType(
    val displayName: String,
    val icon: String,
    val rewardMinutes: Double
) {
    WALKING("Walking", "directions_walk", 10.0),
    RUNNING("Running", "directions_run", 20.0),
    CYCLING("Cycling", "directions_bike", 15.0),
    MEDITATION("Meditation", "self_improvement", 10.0),
    READING("Reading", "menu_book", 15.0),
    EXERCISE("Exercise", "fitness_center", 20.0),
    OUTDOOR("Outdoor Activity", "wb_sunny", 10.0),
    CUSTOM("Custom Activity", "star", 5.0)
}

enum class VerificationMethod { TAP_COUNT, SCROLL_DETECTION, ACCELEROMETER, MANUAL }

enum class ActivityStatus { PENDING, IN_PROGRESS, VERIFIED, FAILED, CANCELLED }

@Entity(tableName = "activities")
data class ActivityRecord(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val type: ActivityType,
    val customName: String? = null,
    val startTime: Long = System.currentTimeMillis(),
    val endTime: Long? = null,
    val durationSeconds: Long = 0L,
    val verificationMethod: VerificationMethod = VerificationMethod.TAP_COUNT,
    val status: ActivityStatus = ActivityStatus.PENDING,
    val rewardEarnedSeconds: Long = 0L,
    val tapCount: Int = 0,
    val notes: String? = null
) {
    val displayName: String get() = customName ?: type.displayName
}

// ─── Achievement ──────────────────────────────────────────────────────────────

enum class AchievementCategory { STREAK, ACTIVITY, SCREEN_TIME, COMMUNITY }

@Entity(tableName = "achievements")
data class Achievement(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val title: String,
    val description: String,
    val icon: String,
    val category: AchievementCategory,
    val isUnlocked: Boolean = false,
    val unlockedAt: Long? = null,
    val progressCurrent: Double = 0.0,
    val progressTarget: Double = 1.0,
    val timeRewardSeconds: Long = 0L
) {
    val progress: Float get() = minOf(1f, (progressCurrent / progressTarget).toFloat())
}

// ─── Timeline Data Point ──────────────────────────────────────────────────────

@Entity(tableName = "timeline_data_points")
data class TimelineDataPoint(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val timestamp: Long = System.currentTimeMillis(),
    val remainingSeconds: Long = 0L,
    val activeAppName: String? = null,
    val activeAppPackageName: String? = null,
    val delta: Double = 0.0
)

// ─── Helpers ──────────────────────────────────────────────────────────────────

fun todayStartMillis(): Long {
    val cal = java.util.Calendar.getInstance()
    cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
    cal.set(java.util.Calendar.MINUTE, 0)
    cal.set(java.util.Calendar.SECOND, 0)
    cal.set(java.util.Calendar.MILLISECOND, 0)
    return cal.timeInMillis
}

fun Long.toFormattedTime(): String {
    val totalSeconds = this
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    return if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
}

object DefaultData {
    val rewardApps = listOf(
        AppConfig(packageName = "com.google.android.apps.fitness", appName = "Google Fit", appIcon = "favorite", configType = AppConfigType.REWARD, minutesPerMinute = 2.0, category = "Health"),
        AppConfig(packageName = "com.duolingo", appName = "Duolingo", appIcon = "school", configType = AppConfigType.REWARD, minutesPerMinute = 1.0, category = "Education"),
        AppConfig(packageName = "com.headspace.android", appName = "Headspace", appIcon = "self_improvement", configType = AppConfigType.REWARD, minutesPerMinute = 1.2, category = "Wellness"),
        AppConfig(packageName = "com.audible.application", appName = "Audible", appIcon = "headphones", configType = AppConfigType.REWARD, minutesPerMinute = 0.8, category = "Education")
    )

    val penaltyApps = listOf(
        AppConfig(packageName = "com.zhiliaoapp.musically", appName = "TikTok", appIcon = "music_note", configType = AppConfigType.PENALTY, minutesPerMinute = -2.0, category = "Entertainment"),
        AppConfig(packageName = "com.instagram.android", appName = "Instagram", appIcon = "photo_camera", configType = AppConfigType.PENALTY, minutesPerMinute = -1.5, category = "Social"),
        AppConfig(packageName = "com.twitter.android", appName = "Twitter/X", appIcon = "chat_bubble", configType = AppConfigType.PENALTY, minutesPerMinute = -1.0, category = "Social"),
        AppConfig(packageName = "com.google.android.youtube", appName = "YouTube", appIcon = "play_circle", configType = AppConfigType.PENALTY, minutesPerMinute = -1.5, category = "Entertainment"),
        AppConfig(packageName = "com.facebook.katana", appName = "Facebook", appIcon = "group", configType = AppConfigType.PENALTY, minutesPerMinute = -1.0, category = "Social")
    )

    val achievements = listOf(
        Achievement(title = "First Steps", description = "Complete your first activity", icon = "star", category = AchievementCategory.ACTIVITY, progressTarget = 1.0, timeRewardSeconds = 60),
        Achievement(title = "Week Warrior", description = "Stay within screen time limit for 7 days", icon = "calendar_today", category = AchievementCategory.STREAK, progressTarget = 7.0, timeRewardSeconds = 300),
        Achievement(title = "Activity Champion", description = "Complete 10 activities", icon = "emoji_events", category = AchievementCategory.ACTIVITY, progressTarget = 10.0, timeRewardSeconds = 600),
        Achievement(title = "Digital Detox", description = "Use less than 1 hour of screen time in a day", icon = "eco", category = AchievementCategory.SCREEN_TIME, progressTarget = 1.0, timeRewardSeconds = 300),
        Achievement(title = "Early Bird", description = "Start an activity before 8 AM", icon = "wb_sunny", category = AchievementCategory.ACTIVITY, progressTarget = 1.0, timeRewardSeconds = 120),
        Achievement(title = "Night Owl Redeemed", description = "Complete a meditation after 9 PM", icon = "nightlight", category = AchievementCategory.ACTIVITY, progressTarget = 1.0, timeRewardSeconds = 120),
        Achievement(title = "Marathon Runner", description = "Complete 5 runs", icon = "directions_run", category = AchievementCategory.ACTIVITY, progressTarget = 5.0, timeRewardSeconds = 300),
        Achievement(title = "Bookworm", description = "Complete 10 reading sessions", icon = "menu_book", category = AchievementCategory.ACTIVITY, progressTarget = 10.0, timeRewardSeconds = 300),
        Achievement(title = "Zen Master", description = "Complete 10 meditation sessions", icon = "self_improvement", category = AchievementCategory.ACTIVITY, progressTarget = 10.0, timeRewardSeconds = 300),
        Achievement(title = "Fitness Fanatic", description = "Complete 15 exercises", icon = "fitness_center", category = AchievementCategory.ACTIVITY, progressTarget = 15.0, timeRewardSeconds = 600),
        Achievement(title = "Social Butterfly", description = "Zero penalty app usage for 3 days", icon = "people", category = AchievementCategory.SCREEN_TIME, progressTarget = 3.0, timeRewardSeconds = 300),
        Achievement(title = "Time Banker", description = "Earn 1 hour of screen time total", icon = "savings", category = AchievementCategory.SCREEN_TIME, progressTarget = 1.0, timeRewardSeconds = 300),
        Achievement(title = "Consistent", description = "Maintain a 5 day streak", icon = "event_repeat", category = AchievementCategory.STREAK, progressTarget = 5.0, timeRewardSeconds = 180),
        Achievement(title = "Power User", description = "Complete 25 activities", icon = "bolt", category = AchievementCategory.ACTIVITY, progressTarget = 25.0, timeRewardSeconds = 900),
        Achievement(title = "Half Marathon", description = "Use reward apps for 30 minutes total", icon = "timer", category = AchievementCategory.SCREEN_TIME, progressTarget = 1.0, timeRewardSeconds = 180),
        Achievement(title = "Screen Free Saturday", description = "Use less than 30 minutes on a Saturday", icon = "weekend", category = AchievementCategory.SCREEN_TIME, progressTarget = 1.0, timeRewardSeconds = 600),
        Achievement(title = "Mindful Morning", description = "Complete 3 morning activities", icon = "wb_twilight", category = AchievementCategory.ACTIVITY, progressTarget = 3.0, timeRewardSeconds = 180),
        Achievement(title = "Explorer", description = "Try all activity types", icon = "explore", category = AchievementCategory.ACTIVITY, progressTarget = 8.0, timeRewardSeconds = 300),
        Achievement(title = "Overachiever", description = "Earn 2 hours of screen time total", icon = "military_tech", category = AchievementCategory.SCREEN_TIME, progressTarget = 1.0, timeRewardSeconds = 600),
        Achievement(title = "Iron Will", description = "Maintain a 10 day streak", icon = "shield", category = AchievementCategory.STREAK, progressTarget = 10.0, timeRewardSeconds = 900),
        Achievement(title = "Centurion", description = "Complete 100 activities", icon = "workspace_premium", category = AchievementCategory.ACTIVITY, progressTarget = 100.0, timeRewardSeconds = 1800),
        Achievement(title = "App Master", description = "Configure 5 or more apps", icon = "app_settings_alt", category = AchievementCategory.SCREEN_TIME, progressTarget = 5.0, timeRewardSeconds = 120),
        Achievement(title = "Balance Pro", description = "Equal earn and penalty in a day", icon = "balance", category = AchievementCategory.SCREEN_TIME, progressTarget = 1.0, timeRewardSeconds = 180),
        Achievement(title = "Legendary", description = "Maintain a 30 day streak", icon = "diamond", category = AchievementCategory.STREAK, progressTarget = 30.0, timeRewardSeconds = 3600)
    )
}
