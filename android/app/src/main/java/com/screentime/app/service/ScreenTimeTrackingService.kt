package com.screentime.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import com.screentime.app.notification.NotificationHelper

class ScreenTimeTrackingService : Service() {
    private val CHANNEL_ID = "screen_time_tracking"
    private val NOTIFICATION_ID = 100

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.createNotificationChannels(this)
        createTrackingChannel()
        startForeground(NOTIFICATION_ID, buildForegroundNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createTrackingChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Screen Time Tracking",
            NotificationManager.IMPORTANCE_MIN
        ).apply {
            description = "Tracks screen time usage in the background"
            setShowBadge(false)
        }
        getSystemService<NotificationManager>()?.createNotificationChannel(channel)
    }

    private fun buildForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen Time Active")
            .setContentText("Monitoring your screen time...")
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .build()
    }
}
