package com.screentime.app.data.db

import androidx.room.*
import com.screentime.app.data.model.*
import kotlinx.coroutines.flow.Flow

@Dao
interface UserProfileDao {
    @Query("SELECT * FROM user_profiles LIMIT 1")
    fun getProfile(): Flow<UserProfile?>

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

    @Query("SELECT * FROM screen_time_entries WHERE date = :date ORDER BY startTime DESC")
    fun getEntriesForDate(date: Long): Flow<List<ScreenTimeEntry>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEntry(entry: ScreenTimeEntry)
}

@Dao
interface ActivityDao {
    @Query("SELECT * FROM activities ORDER BY startTime DESC")
    fun getAllActivities(): Flow<List<ActivityRecord>>

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

    @Upsert
    suspend fun upsert(achievement: Achievement)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(achievements: List<Achievement>)

    @Query("SELECT COUNT(*) FROM achievements")
    suspend fun count(): Int
}
