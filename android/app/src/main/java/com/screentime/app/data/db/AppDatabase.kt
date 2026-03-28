package com.screentime.app.data.db

import android.content.Context
import androidx.room.*
import com.screentime.app.data.model.*

@TypeConverters(Converters::class)
@Database(
    entities = [
        UserProfile::class,
        AppConfig::class,
        ScreenTimeEntry::class,
        DailyScreenTimeSummary::class,
        ActivityRecord::class,
        Achievement::class,
        TimelineDataPoint::class
    ],
    version = 2,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userProfileDao(): UserProfileDao
    abstract fun appConfigDao(): AppConfigDao
    abstract fun screenTimeDao(): ScreenTimeDao
    abstract fun activityDao(): ActivityDao
    abstract fun achievementDao(): AchievementDao
    abstract fun timelineDao(): TimelineDao

    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "screentime_database"
                ).fallbackToDestructiveMigration().build()
                INSTANCE = instance
                instance
            }
        }
    }
}

class Converters {
    @TypeConverter fun fromActivityType(value: ActivityType): String = value.name
    @TypeConverter fun toActivityType(value: String): ActivityType = ActivityType.valueOf(value)

    @TypeConverter fun fromVerificationMethod(value: VerificationMethod): String = value.name
    @TypeConverter fun toVerificationMethod(value: String): VerificationMethod = VerificationMethod.valueOf(value)

    @TypeConverter fun fromActivityStatus(value: ActivityStatus): String = value.name
    @TypeConverter fun toActivityStatus(value: String): ActivityStatus = ActivityStatus.valueOf(value)

    @TypeConverter fun fromConfigType(value: AppConfigType): String = value.name
    @TypeConverter fun toConfigType(value: String): AppConfigType = AppConfigType.valueOf(value)

    @TypeConverter fun fromAchievementCategory(value: AchievementCategory): String = value.name
    @TypeConverter fun toAchievementCategory(value: String): AchievementCategory = AchievementCategory.valueOf(value)
}
