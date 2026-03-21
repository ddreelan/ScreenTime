package com.screentime.app.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.getSystemService

object NotificationHelper {
    private const val CHANNEL_SCREEN_TIME = "screen_time_alerts"
    private const val CHANNEL_ACTIVITIES = "activity_notifications"
    private const val CHANNEL_MOTIVATION = "motivation_reminders"

    fun createNotificationChannels(context: Context) {
        val manager = context.getSystemService<NotificationManager>() ?: return

        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_SCREEN_TIME, "Screen Time Alerts", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Alerts when screen time limit is reached"
            }
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ACTIVITIES, "Activity Notifications", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Notifications for completed activities and earned rewards"
            }
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_MOTIVATION, "Motivation & Reminders", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Daily motivational messages and break reminders"
            }
        )
    }

    fun sendLimitReachedNotification(context: Context) {
        val notification = NotificationCompat.Builder(context, CHANNEL_SCREEN_TIME)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Screen Time Limit Reached")
            .setContentText("Complete activities to earn more screen time!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(1001, notification)
    }

    fun sendActivityCompletedNotification(context: Context, activityName: String, earnedMinutes: Long) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ACTIVITIES)
            .setSmallIcon(android.R.drawable.star_big_on)
            .setContentTitle("Activity Verified! 🎉")
            .setContentText("$activityName complete! +$earnedMinutes minutes earned.")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(System.currentTimeMillis().toInt(), notification)
    }

    fun sendBreakReminder(context: Context) {
        val notification = NotificationCompat.Builder(context, CHANNEL_MOTIVATION)
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentTitle("Time for a Break! 🌱")
            .setContentText("Step outside or exercise to earn bonus screen time.")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(2001, notification)
    }
}
