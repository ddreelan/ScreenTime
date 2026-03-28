package com.screentime.app.data.db

import androidx.room.*
import com.screentime.app.data.model.*
import kotlinx.coroutines.flow.Flow

@Dao
interface UserProfileDao {
    @Query("SELECT * FROM user_profiles LIMIT 1")
    fun getProfile(): Flow<UserProfile?>

    @Query("SELECT * FROM user_profiles LIMIT 1")
    suspend fun getProfileDirect(): UserProfile?

    @Upsert
    suspend fun upsert(profile: UserProfile)
}

@Dao
interface AppConfigDao {
    @Query("SELECT * FROM app_configs ORDER BY appName ASC")
    fun getAllConfigs(): Flow<List<AppConfig>>

    @Query("SELECT * FROM app_configs WHERE configType = :type ORDER BY appName ASC")
    fun getConfigsByType(type: AppConfigType): Flow<List<AppConfig>>

    @Upsert
    suspend fun upsert(config: AppConfig)

    @Query("SELECT * FROM app_configs")
    suspend fun getAllConfigsDirect(): List<AppConfig>

    @Delete
    suspend fun delete(config: AppConfig)

    @Query("DELETE FROM app_configs WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("SELECT COUNT(*) FROM app_configs")
    suspend fun count(): Int
}

@Dao
interface ScreenTimeDao {
    @Query("SELECT * FROM daily_summaries WHERE date = :date LIMIT 1")
    fun getSummaryForDate(date: Long): Flow<DailyScreenTimeSummary?>

    @Query("SELECT * FROM daily_summaries ORDER BY date DESC LIMIT 30")
    fun getRecentSummaries(): Flow<List<DailyScreenTimeSummary>>

    @Upsert
    suspend fun upsertSummary(summary: DailyScreenTimeSummary)

    @Query("SELECT * FROM daily_summaries WHERE date = :date LIMIT 1")
    suspend fun getSummaryForDateDirect(date: Long): DailyScreenTimeSummary?

    @Query("SELECT * FROM daily_summaries ORDER BY date DESC LIMIT 30")
    suspend fun getRecentSummariesDirect(): List<DailyScreenTimeSummary>

    @Query("SELECT * FROM screen_time_entries WHERE date = :date ORDER BY startTime DESC")
    fun getEntriesForDate(date: Long): Flow<List<ScreenTimeEntry>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEntry(entry: ScreenTimeEntry)
}

@Dao
interface ActivityDao {
    @Query("SELECT * FROM activities ORDER BY startTime DESC")
    fun getAllActivities(): Flow<List<ActivityRecord>>

    @Query("SELECT * FROM activities")
    suspend fun getAllDirect(): List<ActivityRecord>

    @Query("SELECT * FROM activities WHERE startTime >= :startOfDay ORDER BY startTime DESC")
    fun getTodayActivities(startOfDay: Long): Flow<List<ActivityRecord>>

    @Upsert
    suspend fun upsert(activity: ActivityRecord)

    @Query("SELECT COUNT(*) FROM activities WHERE status = 'VERIFIED'")
    suspend fun countVerified(): Int
}

@Dao
interface AchievementDao {
    @Query("SELECT * FROM achievements ORDER BY isUnlocked DESC, title ASC")
    fun getAllAchievements(): Flow<List<Achievement>>

    @Query("SELECT * FROM achievements")
    suspend fun getAllDirect(): List<Achievement>

    @Upsert
    suspend fun upsert(achievement: Achievement)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(achievements: List<Achievement>)

    @Query("SELECT COUNT(*) FROM achievements")
    suspend fun count(): Int
}

@Dao
interface TimelineDao {
    @Query("SELECT * FROM timeline_data_points WHERE timestamp >= :startOfDay ORDER BY timestamp ASC")
    fun getTodayTimeline(startOfDay: Long): Flow<List<TimelineDataPoint>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(point: TimelineDataPoint)

    @Query("DELETE FROM timeline_data_points WHERE timestamp < :cutoff")
    suspend fun deleteOlderThan(cutoff: Long)
}
