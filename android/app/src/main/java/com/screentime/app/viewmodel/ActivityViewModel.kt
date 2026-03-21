package com.screentime.app.viewmodel

import android.app.Application
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.core.content.getSystemService
import androidx.lifecycle.*
import com.screentime.app.data.model.*
import com.screentime.app.data.repository.RepositoryProvider
import com.screentime.app.notification.NotificationHelper
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlin.math.sqrt

class ActivityViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = RepositoryProvider.getRepository(application)
    private val sensorManager = application.getSystemService<SensorManager>()

    val allActivities: StateFlow<List<ActivityRecord>> = repository.allActivities
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val todayActivities: StateFlow<List<ActivityRecord>> = repository.getTodayActivities()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _currentActivity = MutableStateFlow<ActivityRecord?>(null)
    val currentActivity: StateFlow<ActivityRecord?> = _currentActivity

    private val _isVerifying = MutableStateFlow(false)
    val isVerifying: StateFlow<Boolean> = _isVerifying

    private val _verificationProgress = MutableStateFlow(0f)
    val verificationProgress: StateFlow<Float> = _verificationProgress

    private val _verificationMessage = MutableStateFlow("")
    val verificationMessage: StateFlow<String> = _verificationMessage

    private val _tapCount = MutableStateFlow(0)
    val tapCount: StateFlow<Int> = _tapCount

    private val _showRewardAnimation = MutableStateFlow(false)
    val showRewardAnimation: StateFlow<Boolean> = _showRewardAnimation

    private val _recentlyEarned = MutableStateFlow(0L)
    val recentlyEarned: StateFlow<Long> = _recentlyEarned

    private val requiredTaps = 20
    private var activityStartTime = 0L

    private val accelerometerListener = object : SensorEventListener {
        private var motionCount = 0
        override fun onSensorChanged(event: SensorEvent) {
            if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                val magnitude = sqrt(
                    event.values[0] * event.values[0] +
                    event.values[1] * event.values[1] +
                    event.values[2] * event.values[2]
                )
                if (magnitude > 12f) {
                    motionCount++
                    val progress = motionCount.toFloat() / (requiredTaps * 5)
                    _verificationProgress.value = minOf(1f, progress)
                    _verificationMessage.value = "Movement detected: ${(progress * 100).toInt()}%"
                    if (progress >= 1f) {
                        completeVerification(true)
                    }
                }
            }
        }
        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
    }

    fun startActivity(type: ActivityType) {
        val method = when (type) {
            ActivityType.WALKING, ActivityType.RUNNING, ActivityType.CYCLING,
            ActivityType.EXERCISE, ActivityType.OUTDOOR -> VerificationMethod.ACCELEROMETER
            ActivityType.READING -> VerificationMethod.SCROLL_DETECTION
            ActivityType.MEDITATION -> VerificationMethod.TAP_COUNT
            ActivityType.CUSTOM -> VerificationMethod.MANUAL
        }

        val activity = ActivityRecord(type = type, verificationMethod = method, status = ActivityStatus.IN_PROGRESS)
        _currentActivity.value = activity
        _isVerifying.value = true
        _tapCount.value = 0
        _verificationProgress.value = 0f
        activityStartTime = System.currentTimeMillis()

        viewModelScope.launch { repository.saveActivity(activity) }

        when (method) {
            VerificationMethod.TAP_COUNT -> _verificationMessage.value = "Tap the button $requiredTaps times to verify"
            VerificationMethod.SCROLL_DETECTION -> _verificationMessage.value = "Scroll through content to verify reading"
            VerificationMethod.ACCELEROMETER -> {
                startAccelerometerVerification()
                _verificationMessage.value = "Move your device to verify physical activity..."
            }
            VerificationMethod.MANUAL -> _verificationMessage.value = "Tap 'Complete' when done with your activity"
        }
    }

    fun recordTap() {
        if (!_isVerifying.value) return
        val newCount = _tapCount.value + 1
        _tapCount.value = newCount
        val progress = newCount.toFloat() / requiredTaps
        _verificationProgress.value = minOf(1f, progress)
        _verificationMessage.value = "$newCount/$requiredTaps interactions recorded"
        if (newCount >= requiredTaps) completeVerification(true)
    }

    fun recordScroll(distance: Float) {
        if (!_isVerifying.value) return
        val newProgress = minOf(1f, _verificationProgress.value + distance / 1000f)
        _verificationProgress.value = newProgress
        _verificationMessage.value = "Scroll progress: ${(newProgress * 100).toInt()}%"
        if (newProgress >= 1f) completeVerification(true)
    }

    fun completeManualActivity() = completeVerification(true)

    fun cancelActivity() {
        stopAccelerometer()
        _currentActivity.value?.let { activity ->
            viewModelScope.launch {
                repository.saveActivity(activity.copy(status = ActivityStatus.CANCELLED, endTime = System.currentTimeMillis()))
            }
        }
        resetVerification()
    }

    private fun completeVerification(success: Boolean) {
        stopAccelerometer()
        val activity = _currentActivity.value ?: return
        val duration = (System.currentTimeMillis() - activityStartTime) / 1000L

        val rewardSeconds = if (success) calculateReward(activity.type, duration) else 0L
        val updatedActivity = activity.copy(
            endTime = System.currentTimeMillis(),
            durationSeconds = duration,
            status = if (success) ActivityStatus.VERIFIED else ActivityStatus.FAILED,
            rewardEarnedSeconds = rewardSeconds
        )

        viewModelScope.launch {
            repository.saveActivity(updatedActivity)
            if (success) {
                _recentlyEarned.value = rewardSeconds
                _showRewardAnimation.value = true
                NotificationHelper.sendActivityCompletedNotification(
                    getApplication(),
                    activity.displayName,
                    rewardSeconds / 60
                )
                kotlinx.coroutines.delay(3000)
                _showRewardAnimation.value = false
            }
        }
        resetVerification()
    }

    private fun calculateReward(type: ActivityType, durationSeconds: Long): Long {
        val baseReward = type.rewardMinutes * 60
        val multiplier = minOf(durationSeconds.toDouble() / (15 * 60), 2.0)
        return (baseReward * multiplier).toLong()
    }

    private fun startAccelerometerVerification() {
        val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        accelerometer?.let {
            sensorManager.registerListener(accelerometerListener, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    private fun stopAccelerometer() {
        sensorManager?.unregisterListener(accelerometerListener)
    }

    private fun resetVerification() {
        _isVerifying.value = false
        _currentActivity.value = null
        _tapCount.value = 0
        _verificationProgress.value = 0f
    }

    val todayEarnedSeconds: StateFlow<Long> = todayActivities.map { activities ->
        activities.filter { it.status == ActivityStatus.VERIFIED }.sumOf { it.rewardEarnedSeconds }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0L)

    override fun onCleared() {
        super.onCleared()
        stopAccelerometer()
    }
}
