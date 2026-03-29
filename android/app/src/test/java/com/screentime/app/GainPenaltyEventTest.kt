package com.screentime.app

import com.screentime.app.data.model.*
import org.junit.Assert.*
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.*

class GainPenaltyEventTest {

    @Test
    fun `GainPenaltyEvent initializes correctly for activity reward`() {
        val now = System.currentTimeMillis()
        val event = GainPenaltyEvent(
            id = "test-id",
            type = GainPenaltyType.ACTIVITY_REWARD,
            activityName = "Walking",
            secondsDelta = 600L,
            timestamp = now,
            icon = "directions_walk"
        )
        assertEquals(GainPenaltyType.ACTIVITY_REWARD, event.type)
        assertEquals("Walking", event.activityName)
        assertEquals(600L, event.secondsDelta)
        assertEquals(now, event.timestamp)
        assertTrue(event.secondsDelta > 0)
    }

    @Test
    fun `GainPenaltyEvent initializes correctly for penalty app`() {
        val now = System.currentTimeMillis()
        val event = GainPenaltyEvent(
            id = "test-id-2",
            type = GainPenaltyType.PENALTY_APP,
            appName = "TikTok",
            secondsDelta = -300L,
            timestamp = now,
            icon = "remove_circle"
        )
        assertEquals(GainPenaltyType.PENALTY_APP, event.type)
        assertEquals("TikTok", event.appName)
        assertEquals(-300L, event.secondsDelta)
        assertTrue(event.secondsDelta < 0)
    }

    @Test
    fun `GainPenaltyEvent initializes correctly for achievement bonus`() {
        val now = System.currentTimeMillis()
        val event = GainPenaltyEvent(
            id = "test-id-3",
            type = GainPenaltyType.ACHIEVEMENT_BONUS,
            achievementTitle = "First Steps",
            secondsDelta = 60L,
            timestamp = now,
            icon = "emoji_events"
        )
        assertEquals(GainPenaltyType.ACHIEVEMENT_BONUS, event.type)
        assertEquals("First Steps", event.achievementTitle)
        assertEquals(60L, event.secondsDelta)
    }

    @Test
    fun `events sorted by timestamp descending`() {
        val now = System.currentTimeMillis()
        val events = listOf(
            GainPenaltyEvent(type = GainPenaltyType.ACTIVITY_REWARD, activityName = "Walking",
                secondsDelta = 600L, timestamp = now - 5000L, icon = "directions_walk"),
            GainPenaltyEvent(type = GainPenaltyType.REWARD_APP, appName = "Duolingo",
                secondsDelta = 300L, timestamp = now - 1000L, icon = "add_circle"),
            GainPenaltyEvent(type = GainPenaltyType.PENALTY_APP, appName = "TikTok",
                secondsDelta = -120L, timestamp = now - 3000L, icon = "remove_circle"),
        )
        val sorted = events.sortedByDescending { it.timestamp }
        assertEquals(now - 1000L, sorted[0].timestamp)
        assertEquals(now - 3000L, sorted[1].timestamp)
        assertEquals(now - 5000L, sorted[2].timestamp)
    }

    @Test
    fun `filtering keeps only events with non-zero secondsDelta`() {
        val now = System.currentTimeMillis()
        val events = listOf(
            GainPenaltyEvent(type = GainPenaltyType.REWARD_APP, appName = "App1",
                secondsDelta = 0L, timestamp = now, icon = "add_circle"),
            GainPenaltyEvent(type = GainPenaltyType.REWARD_APP, appName = "App2",
                secondsDelta = 300L, timestamp = now, icon = "add_circle"),
            GainPenaltyEvent(type = GainPenaltyType.PENALTY_APP, appName = "App3",
                secondsDelta = -150L, timestamp = now, icon = "remove_circle"),
        )
        val nonZero = events.filter { it.secondsDelta != 0L }
        assertEquals(2, nonZero.size)
    }

    @Test
    fun `timestamp formatting produces valid locale-aware time string`() {
        val formatter = SimpleDateFormat("h:mm a", Locale.getDefault())
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 9)
        cal.set(Calendar.MINUTE, 42)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val formatted = formatter.format(cal.time)
        assertNotNull(formatted)
        assertTrue(formatted.isNotEmpty())
        // Should contain colon separator
        assertTrue(formatted.contains(":"))
    }

    @Test
    fun `take limits events to specified count`() {
        val now = System.currentTimeMillis()
        val events = (1..15).map { i ->
            GainPenaltyEvent(
                type = GainPenaltyType.REWARD_APP,
                appName = "App$i",
                secondsDelta = i.toLong() * 60,
                timestamp = now - i.toLong() * 1000,
                icon = "add_circle"
            )
        }
        val limited = events.take(10)
        assertEquals(10, limited.size)
    }
}
