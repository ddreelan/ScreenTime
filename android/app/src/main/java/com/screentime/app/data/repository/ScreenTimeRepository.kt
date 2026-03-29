package com.screentime.app.data.repository

import com.screentime.app.data.db.*
import com.screentime.app.data.model.*
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class ScreenTimeRepository(
    private val userProfileDao: UserProfileDao,
    private val appConfigDao: AppConfigDao,
    private val screenTimeDao: ScreenTimeDao,
    private val activityDao: ActivityDao,
    private val achievementDao: AchievementDao,
    private val timelineDao: TimelineDao
) {
    // ── User Profile ─────────────────────────────────────────────────────────
    val userProfile: Flow<UserProfile?> = userProfileDao.getProfile()
    suspend fun saveUserProfile(profile: UserProfile) = userProfileDao.upsert(profile)

    // ── App Configs ──────────────────────────────────────────────────────────
    val allAppConfigs: Flow<List<AppConfig>> = appConfigDao.getAllConfigs()
    fun getConfigsByType(type: AppConfigType): Flow<List<AppConfig>> = appConfigDao.getConfigsByType(type)
    suspend fun saveAppConfig(config: AppConfig) = appConfigDao.upsert(config)
    suspend fun deleteAppConfig(id: String) = appConfigDao.deleteById(id)
    suspend fun getAppConfigCount(): Int = appConfigDao.count()

    suspend fun initializeDefaultConfigs() {
        if (appConfigDao.count() == 0) {
            DefaultData.rewardApps.forEach { appConfigDao.upsert(it) }
            DefaultData.penaltyApps.forEach { appConfigDao.upsert(it) }
        }
    }

    // ── Screen Time ──────────────────────────────────────────────────────────
    fun getTodaySummary(): Flow<DailyScreenTimeSummary?> = screenTimeDao.getSummaryForDate(todayStartMillis())
    val recentSummaries: Flow<List<DailyScreenTimeSummary>> = screenTimeDao.getRecentSummaries()
    suspend fun updateSummary(summary: DailyScreenTimeSummary) = screenTimeDao.upsertSummary(summary)

    fun getTodayNonZeroEntries(): Flow<List<ScreenTimeEntry>> = screenTimeDao.getNonZeroEntriesForDate(todayStartMillis())

    suspend fun recordScreenTimeUsage(durationSeconds: Long, appConfig: AppConfig?) {
        val today = todayStartMillis()
        // Get existing or create new summary - use a simple approach since we can't collect in suspend
        val penaltySeconds = if (appConfig?.configType == AppConfigType.PENALTY) {
            (durationSeconds * kotlin.math.abs(appConfig.minutesPerMinute)).toLong()
        } else 0L

        // We'll handle this through the ViewModel which has access to the current summary
    }

    // ── Activities ───────────────────────────────────────────────────────────
    val allActivities: Flow<List<ActivityRecord>> = activityDao.getAllActivities()
    fun getTodayActivities(): Flow<List<ActivityRecord>> = activityDao.getTodayActivities(todayStartMillis())
    suspend fun saveActivity(activity: ActivityRecord) = activityDao.upsert(activity)
    suspend fun getVerifiedActivityCount(): Int = activityDao.countVerified()

    // ── Achievements ─────────────────────────────────────────────────────────
    val allAchievements: Flow<List<Achievement>> = achievementDao.getAllAchievements()
    suspend fun saveAchievement(achievement: Achievement) = achievementDao.upsert(achievement)
    suspend fun initializeAchievements() {
        if (achievementDao.count() == 0) {
            achievementDao.insertAll(DefaultData.achievements)
        }
    }

    // ── Timeline ─────────────────────────────────────────────────────────────
    fun getTodayTimeline(): Flow<List<TimelineDataPoint>> = timelineDao.getTodayTimeline(todayStartMillis())
    suspend fun insertTimelinePoint(point: TimelineDataPoint) = timelineDao.insert(point)
    suspend fun cleanupOldTimelineData(cutoff: Long) = timelineDao.deleteOlderThan(cutoff)
}
