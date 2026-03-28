package com.screentime.app.service

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import com.screentime.app.data.db.AppDatabase
import com.screentime.app.data.model.*
import kotlinx.coroutines.*
import kotlin.math.abs

class AppUsageTrackingWorker(private val context: Context) {
    private val db = AppDatabase.getDatabase(context)
    private val screenTimeDao = db.screenTimeDao()
    private val appConfigDao = db.appConfigDao()
    private val userProfileDao = db.userProfileDao()

    private var trackingJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    companion object {
        private const val SELF_PACKAGE = "com.screentime.app"
        private const val POLL_INTERVAL_MS = 1000L // 1 second
    }

    fun hasUsageStatsPermission(): Boolean {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return false
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 60_000, now)
        return stats != null && stats.isNotEmpty()
    }

    fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    fun startTracking() {
        if (trackingJob?.isActive == true) return
        trackingJob = scope.launch {
            while (isActive) {
                tick()
                delay(POLL_INTERVAL_MS)
            }
        }
    }

    fun stopTracking() {
        trackingJob?.cancel()
        trackingJob = null
    }

    private suspend fun tick() {
        val foregroundPackage = getForegroundPackage() ?: return

        val today = todayStartMillis()
        val summary = screenTimeDao.getSummaryForDateDirect(today)
            ?: DailyScreenTimeSummary(date = today)

        // Always count 1 second of usage
        var updatedSummary = summary.copy(totalUsedSeconds = summary.totalUsedSeconds + 1)

        // Self-app exemption: skip reward/penalty for ScreenTime itself
        if (foregroundPackage == SELF_PACKAGE) {
            screenTimeDao.upsertSummary(updatedSummary)
            return
        }

        // Look up app config
        val configs = appConfigDao.getAllConfigsDirect()
        val config = configs.firstOrNull { it.packageName == foregroundPackage && it.isEnabled }

        if (config != null) {
            when (config.configType) {
                AppConfigType.REWARD -> {
                    val rewardPerSecond = (config.minutesPerMinute / 60.0).toLong().coerceAtLeast(0)
                    updatedSummary = updatedSummary.copy(
                        totalEarnedSeconds = updatedSummary.totalEarnedSeconds + rewardPerSecond
                    )
                }
                AppConfigType.PENALTY -> {
                    val penaltyPerSecond = (abs(config.minutesPerMinute) / 60.0).toLong().coerceAtLeast(0)
                    updatedSummary = updatedSummary.copy(
                        totalPenaltySeconds = updatedSummary.totalPenaltySeconds + penaltyPerSecond
                    )
                }
                AppConfigType.NEUTRAL -> { /* no effect */ }
            }
        } else {
            // Default penalty for unconfigured apps
            val profile = userProfileDao.getProfileDirect()
            val defaultPenaltyRate = kotlin.math.abs(profile?.defaultPenaltyRate ?: -1.0)
            val penaltyPerSecond = (defaultPenaltyRate / 60.0).toLong().coerceAtLeast(0)
            updatedSummary = updatedSummary.copy(
                totalPenaltySeconds = updatedSummary.totalPenaltySeconds + penaltyPerSecond
            )
        }

        screenTimeDao.upsertSummary(updatedSummary)
    }

    private fun getForegroundPackage(): String? {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 10_000, now)
        return stats?.maxByOrNull { it.lastTimeUsed }?.packageName
    }
}
