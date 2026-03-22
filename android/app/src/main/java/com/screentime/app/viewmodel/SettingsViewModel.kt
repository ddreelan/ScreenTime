package com.screentime.app.viewmodel

import android.app.Application
import androidx.lifecycle.*
import com.screentime.app.data.model.*
import com.screentime.app.data.repository.RepositoryProvider
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class SettingsViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = RepositoryProvider.getRepository(application)

    val userProfile: StateFlow<UserProfile?> = repository.userProfile
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    val rewardApps: StateFlow<List<AppConfig>> = repository.getConfigsByType(AppConfigType.REWARD)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val penaltyApps: StateFlow<List<AppConfig>> = repository.getConfigsByType(AppConfigType.PENALTY)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun saveAppConfig(config: AppConfig) {
        viewModelScope.launch {
            repository.saveAppConfig(config)
        }
    }

    fun deleteAppConfig(id: String) {
        viewModelScope.launch {
            repository.deleteAppConfig(id)
        }
    }

    fun toggleAppEnabled(config: AppConfig) {
        viewModelScope.launch {
            repository.saveAppConfig(config.copy(isEnabled = !config.isEnabled))
        }
    }

    fun saveDailyLimit(hours: Int, minutes: Int) {
        viewModelScope.launch {
            val totalSeconds = (hours * 3600 + minutes * 60).toLong()
            val current = userProfile.value ?: UserProfile(name = "User", age = 18)
            repository.saveUserProfile(current.copy(
                dailyScreenTimeLimitSeconds = totalSeconds,
                updatedAt = System.currentTimeMillis()
            ))
        }
    }

    fun saveUserProfile(name: String, age: Int, goals: List<String>) {
        viewModelScope.launch {
            val current = userProfile.value ?: UserProfile(name = name, age = age)
            repository.saveUserProfile(current.copy(
                name = name,
                age = age,
                goals = goals.joinToString(","),
                updatedAt = System.currentTimeMillis()
            ))
        }
    }
}
