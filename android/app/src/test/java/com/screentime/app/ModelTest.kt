package com.screentime.app

import com.screentime.app.data.model.*
import org.junit.Assert.*
import org.junit.Test

class ModelTest {

    @Test
    fun `daily summary remaining time calculation`() {
        val summary = DailyScreenTimeSummary(
            totalAllocatedSeconds = 7200L,
            totalUsedSeconds = 3600L,
            totalEarnedSeconds = 1800L,
            totalPenaltySeconds = 600L
        )
        val expected = 7200L + 1800L - 3600L - 600L
        assertEquals(expected, summary.remainingSeconds)
    }

    @Test
    fun `daily summary remaining time never negative`() {
        val summary = DailyScreenTimeSummary(
            totalAllocatedSeconds = 7200L,
            totalUsedSeconds = 10000L,
            totalEarnedSeconds = 0L,
            totalPenaltySeconds = 0L
        )
        assertEquals(0L, summary.remainingSeconds)
    }

    @Test
    fun `usage percentage capped at 1`() {
        val summary = DailyScreenTimeSummary(
            totalAllocatedSeconds = 7200L,
            totalUsedSeconds = 10000L
        )
        assertEquals(1f, summary.usagePercentage)
    }

    @Test
    fun `app config effect description reward`() {
        val config = AppConfig(
            packageName = "com.test",
            appName = "Test",
            configType = AppConfigType.REWARD,
            minutesPerMinute = 1.5
        )
        assertTrue(config.effectDescription.contains("+"))
        assertTrue(config.effectDescription.contains("1.5"))
    }

    @Test
    fun `app config effect description penalty`() {
        val config = AppConfig(
            packageName = "com.test",
            appName = "Test",
            configType = AppConfigType.PENALTY,
            minutesPerMinute = -2.0
        )
        assertTrue(config.effectDescription.contains("-"))
    }

    @Test
    fun `activity display name uses custom name`() {
        val activity = ActivityRecord(
            type = ActivityType.CUSTOM,
            customName = "Morning Yoga"
        )
        assertEquals("Morning Yoga", activity.displayName)
    }

    @Test
    fun `activity display name falls back to type name`() {
        val activity = ActivityRecord(type = ActivityType.WALKING)
        assertEquals("Walking", activity.displayName)
    }

    @Test
    fun `achievement progress capped at 1`() {
        val achievement = Achievement(
            title = "Test",
            description = "Test",
            icon = "star",
            category = AchievementCategory.ACTIVITY,
            progressCurrent = 15.0,
            progressTarget = 10.0
        )
        assertEquals(1f, achievement.progress)
    }

    @Test
    fun `today start millis returns midnight`() {
        val millis = todayStartMillis()
        val cal = java.util.Calendar.getInstance()
        cal.timeInMillis = millis
        assertEquals(0, cal.get(java.util.Calendar.HOUR_OF_DAY))
        assertEquals(0, cal.get(java.util.Calendar.MINUTE))
        assertEquals(0, cal.get(java.util.Calendar.SECOND))
    }

    @Test
    fun `formatted time hours`() {
        assertEquals("1h 30m", 5400L.toFormattedTime())
    }

    @Test
    fun `formatted time minutes only`() {
        assertEquals("45m", 2700L.toFormattedTime())
    }
}
