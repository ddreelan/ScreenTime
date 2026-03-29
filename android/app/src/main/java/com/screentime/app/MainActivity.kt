package com.screentime.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import com.screentime.app.data.db.AppDatabase
import com.screentime.app.data.model.todayStartMillis
import com.screentime.app.notification.NotificationHelper
import com.screentime.app.ui.ScreenTimeApp
import com.screentime.app.ui.theme.ScreenTimeTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ScreenTimeTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    ScreenTimeApp()
                }
            }
        }
    }

    override fun onStop() {
        super.onStop()
        lifecycleScope.launch(Dispatchers.IO) {
            val db = AppDatabase.getDatabase(applicationContext)
            val summary = db.screenTimeDao().getSummaryForDateDirect(todayStartMillis())
            if (summary != null) {
                NotificationHelper.sendAppExitSummaryNotification(
                    context = applicationContext,
                    totalUsedSeconds = summary.totalUsedSeconds,
                    totalPenaltySeconds = summary.totalPenaltySeconds,
                    remainingSeconds = summary.remainingSeconds
                )
            }
        }
    }
}
