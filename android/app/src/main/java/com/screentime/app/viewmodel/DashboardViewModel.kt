package com.screentime.app.viewmodel

import android.app.Application
import androidx.lifecycle.*
import com.screentime.app.data.model.*
import com.screentime.app.data.repository.RepositoryProvider
import com.screentime.app.data.repository.ScreenTimeRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class DashboardViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = RepositoryProvider.getRepository(application)

    val todaySummary: StateFlow<DailyScreenTimeSummary> = repository.getTodaySummary()
        .map { it ?: DailyScreenTimeSummary() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), DailyScreenTimeSummary())

    val todayActivities: StateFlow<List<ActivityRecord>> = repository.getTodayActivities()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allConfigs: StateFlow<List<AppConfig>> = repository.allAppConfigs
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val motivationalMessage: StateFlow<String> = todaySummary.map { summary ->
        when {
            summary.remainingSeconds <= 0 -> "Screen time limit reached! Complete activities to earn more. 💪"
            summary.remainingSeconds < 1800 -> "Less than 30 minutes left. Consider a break! 🌿"
            summary.totalEarnedSeconds > 0 -> "Great job earning extra time through activities! 🌟"
            else -> "Complete activities to earn bonus screen time! 🎯"
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), "")

    init {
        viewModelScope.launch {
            repository.initializeDefaultConfigs()
            repository.initializeAchievements()
        }
    }

    fun addEarnedTime(seconds: Long) {
        viewModelScope.launch {
            val current = todaySummary.value
            repository.updateSummary(current.copy(
                totalEarnedSeconds = current.totalEarnedSeconds + seconds
            ))
        }
    }

    fun recordUsage(durationSeconds: Long, appConfig: AppConfig?) {
        viewModelScope.launch {
            val current = todaySummary.value
            val penalty = if (appConfig?.configType == AppConfigType.PENALTY) {
                (durationSeconds * kotlin.math.abs(appConfig.minutesPerMinute)).toLong()
            } else 0L
            repository.updateSummary(current.copy(
                totalUsedSeconds = current.totalUsedSeconds + durationSeconds,
                totalPenaltySeconds = current.totalPenaltySeconds + penalty
            ))
        }
    }
}
