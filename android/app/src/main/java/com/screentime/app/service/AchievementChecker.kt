package com.screentime.app.service

import com.screentime.app.data.db.AppDatabase
import com.screentime.app.data.model.*
import java.util.Calendar

class AchievementChecker(private val db: AppDatabase) {
    private val achievementDao = db.achievementDao()
    private val activityDao = db.activityDao()
    private val screenTimeDao = db.screenTimeDao()
    private val appConfigDao = db.appConfigDao()

    suspend fun checkAll() {
        val achievements = achievementDao.getAllDirect()
        val verifiedCount = activityDao.countVerified()
        val activities = activityDao.getAllDirect()
        val verifiedActivities = activities.filter { it.status == ActivityStatus.VERIFIED }
        val today = todayStartMillis()
        val todaySummary = screenTimeDao.getSummaryForDateDirect(today)
        val recentSummaries = screenTimeDao.getRecentSummariesDirect()
        val configCount = appConfigDao.count()

        var totalTimeReward = 0L

        for (achievement in achievements) {
            if (achievement.isUnlocked) continue

            val updated = evaluateAchievement(
                achievement, verifiedCount, verifiedActivities, todaySummary, recentSummaries, configCount
            )
            if (updated != achievement) {
                achievementDao.upsert(updated)

                // Accumulate time reward when newly unlocked
                if (updated.isUnlocked && !achievement.isUnlocked && updated.timeRewardSeconds > 0) {
                    totalTimeReward += updated.timeRewardSeconds
                }
            }
        }

        // Apply accumulated time rewards in a single summary update
        if (totalTimeReward > 0 && todaySummary != null) {
            val updatedSummary = todaySummary.copy(
                totalEarnedSeconds = todaySummary.totalEarnedSeconds + totalTimeReward
            )
            screenTimeDao.upsertSummary(updatedSummary)
        }
    }

    private fun evaluateAchievement(
        achievement: Achievement,
        verifiedCount: Int,
        verifiedActivities: List<ActivityRecord>,
        todaySummary: DailyScreenTimeSummary?,
        recentSummaries: List<DailyScreenTimeSummary>,
        configCount: Int
    ): Achievement {
        var a = achievement
        when (a.title) {
            "First Steps" -> {
                a = a.copy(progressCurrent = verifiedCount.toDouble().coerceAtMost(1.0))
                if (verifiedCount >= 1) a = unlock(a)
            }
            "Week Warrior" -> {
                val streak = calculateStreak(recentSummaries)
                a = a.copy(progressCurrent = streak.toDouble())
                if (streak >= 7) a = unlock(a)
            }
            "Activity Champion" -> {
                a = a.copy(progressCurrent = verifiedCount.toDouble())
                if (verifiedCount >= 10) a = unlock(a)
            }
            "Digital Detox" -> {
                if (todaySummary != null && todaySummary.totalUsedSeconds < 3600 && todaySummary.totalUsedSeconds > 0) {
                    a = a.copy(progressCurrent = 1.0)
                    a = unlock(a)
                }
            }
            "Early Bird" -> {
                val hasEarlyActivity = verifiedActivities.any { activityBefore8AM(it) }
                if (hasEarlyActivity) {
                    a = a.copy(progressCurrent = 1.0)
                    a = unlock(a)
                }
            }
            "Night Owl Redeemed" -> {
                val hasNightMeditation = verifiedActivities.any {
                    it.type == ActivityType.MEDITATION && activityAfter9PM(it)
                }
                if (hasNightMeditation) {
                    a = a.copy(progressCurrent = 1.0)
                    a = unlock(a)
                }
            }
            "Marathon Runner" -> {
                val runCount = verifiedActivities.count { it.type == ActivityType.RUNNING }
                a = a.copy(progressCurrent = runCount.toDouble())
                if (runCount >= 5) a = unlock(a)
            }
            "Bookworm" -> {
                val readCount = verifiedActivities.count { it.type == ActivityType.READING }
                a = a.copy(progressCurrent = readCount.toDouble())
                if (readCount >= 10) a = unlock(a)
            }
            "Zen Master" -> {
                val meditateCount = verifiedActivities.count { it.type == ActivityType.MEDITATION }
                a = a.copy(progressCurrent = meditateCount.toDouble())
                if (meditateCount >= 10) a = unlock(a)
            }
            "Fitness Fanatic" -> {
                val exerciseCount = verifiedActivities.count { it.type == ActivityType.EXERCISE }
                a = a.copy(progressCurrent = exerciseCount.toDouble())
                if (exerciseCount >= 15) a = unlock(a)
            }
            "Social Butterfly" -> {
                val zeroPenaltyDays = recentSummaries.count { it.totalPenaltySeconds == 0L }
                a = a.copy(progressCurrent = zeroPenaltyDays.toDouble())
                if (zeroPenaltyDays >= 3) a = unlock(a)
            }
            "Time Banker" -> {
                val totalEarned = recentSummaries.sumOf { it.totalEarnedSeconds }
                a = a.copy(progressCurrent = (totalEarned.toDouble() / 3600.0).coerceAtMost(1.0))
                if (totalEarned >= 3600) a = unlock(a)
            }
            "Consistent" -> {
                val streak = calculateStreak(recentSummaries)
                a = a.copy(progressCurrent = streak.toDouble())
                if (streak >= 5) a = unlock(a)
            }
            "Power User" -> {
                a = a.copy(progressCurrent = verifiedCount.toDouble())
                if (verifiedCount >= 25) a = unlock(a)
            }
            "Half Marathon" -> {
                // Reward app usage >= 30 min total (1800 seconds earned)
                val totalEarned = recentSummaries.sumOf { it.totalEarnedSeconds }
                a = a.copy(progressCurrent = (totalEarned.toDouble() / 1800.0).coerceAtMost(1.0))
                if (totalEarned >= 1800) a = unlock(a)
            }
            "Screen Free Saturday" -> {
                val saturdaySummary = recentSummaries.firstOrNull { isSaturday(it.date) }
                if (saturdaySummary != null && saturdaySummary.totalUsedSeconds < 1800) {
                    a = a.copy(progressCurrent = 1.0)
                    a = unlock(a)
                }
            }
            "Mindful Morning" -> {
                val morningCount = verifiedActivities.count { activityBefore8AM(it) }
                a = a.copy(progressCurrent = morningCount.toDouble())
                if (morningCount >= 3) a = unlock(a)
            }
            "Explorer" -> {
                val typesUsed = verifiedActivities.map { it.type }.toSet()
                val totalTypes = ActivityType.entries.size
                a = a.copy(progressCurrent = typesUsed.size.toDouble(), progressTarget = totalTypes.toDouble())
                if (typesUsed.size >= totalTypes) a = unlock(a)
            }
            "Overachiever" -> {
                val totalEarned = recentSummaries.sumOf { it.totalEarnedSeconds }
                a = a.copy(progressCurrent = (totalEarned.toDouble() / 7200.0).coerceAtMost(1.0))
                if (totalEarned >= 7200) a = unlock(a)
            }
            "Iron Will" -> {
                val streak = calculateStreak(recentSummaries)
                a = a.copy(progressCurrent = streak.toDouble())
                if (streak >= 10) a = unlock(a)
            }
            "Centurion" -> {
                a = a.copy(progressCurrent = verifiedCount.toDouble())
                if (verifiedCount >= 100) a = unlock(a)
            }
            "App Master" -> {
                a = a.copy(progressCurrent = configCount.toDouble())
                if (configCount >= 5) a = unlock(a)
            }
            "Balance Pro" -> {
                if (todaySummary != null && todaySummary.totalEarnedSeconds > 0 && todaySummary.totalPenaltySeconds > 0) {
                    val ratio = todaySummary.totalEarnedSeconds.toDouble() / todaySummary.totalPenaltySeconds.toDouble()
                    if (ratio in 0.8..1.2) {
                        a = a.copy(progressCurrent = 1.0)
                        a = unlock(a)
                    }
                }
            }
            "Legendary" -> {
                val streak = calculateStreak(recentSummaries)
                a = a.copy(progressCurrent = streak.toDouble())
                if (streak >= 30) a = unlock(a)
            }
        }
        return a
    }

    private fun unlock(a: Achievement): Achievement {
        if (a.isUnlocked) return a
        return a.copy(isUnlocked = true, unlockedAt = System.currentTimeMillis())
    }

    private fun calculateStreak(summaries: List<DailyScreenTimeSummary>): Int {
        if (summaries.isEmpty()) return 0
        val sorted = summaries.sortedByDescending { it.date }
        var streak = 0
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)

        for (summary in sorted) {
            val expected = cal.timeInMillis
            if (summary.date == expected && summary.remainingSeconds > 0) {
                streak++
                cal.add(Calendar.DAY_OF_YEAR, -1)
            } else {
                break
            }
        }
        return streak
    }

    private fun activityBefore8AM(activity: ActivityRecord): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = activity.startTime }
        return cal.get(Calendar.HOUR_OF_DAY) < 8
    }

    private fun activityAfter9PM(activity: ActivityRecord): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = activity.startTime }
        return cal.get(Calendar.HOUR_OF_DAY) >= 21
    }

    private fun isSaturday(dateMillis: Long): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = dateMillis }
        return cal.get(Calendar.DAY_OF_WEEK) == Calendar.SATURDAY
    }
}
