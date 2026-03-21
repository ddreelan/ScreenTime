package com.screentime.app.data.repository

import android.content.Context
import com.screentime.app.data.db.AppDatabase

object RepositoryProvider {
    private var repository: ScreenTimeRepository? = null

    fun getRepository(context: Context): ScreenTimeRepository {
        return repository ?: synchronized(this) {
            val db = AppDatabase.getDatabase(context)
            ScreenTimeRepository(
                userProfileDao = db.userProfileDao(),
                appConfigDao = db.appConfigDao(),
                screenTimeDao = db.screenTimeDao(),
                activityDao = db.activityDao(),
                achievementDao = db.achievementDao()
            ).also { repository = it }
        }
    }
}
