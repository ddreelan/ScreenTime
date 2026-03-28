package com.screentime.app.ui.screens

import android.graphics.drawable.Drawable
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.graphics.drawable.toBitmap
import androidx.lifecycle.viewmodel.compose.viewModel
import com.screentime.app.data.model.*
import com.screentime.app.viewmodel.DashboardViewModel
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun AnalyticsScreen(
    paddingValues: PaddingValues,
    viewModel: DashboardViewModel = viewModel()
) {
    val allConfigs by viewModel.allConfigs.collectAsState()
    var selectedDays by remember { mutableIntStateOf(7) }

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(paddingValues),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text("Analytics", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        }

        item {
            SegmentedButtons(selectedDays = selectedDays, onSelect = { selectedDays = it })
        }

        item {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                AnalyticsSummaryCard(modifier = Modifier.weight(1f), title = "Reward Apps", value = "${allConfigs.count { it.configType == AppConfigType.REWARD }}", icon = Icons.Default.AddCircle, color = Color(0xFF4CAF50))
                AnalyticsSummaryCard(modifier = Modifier.weight(1f), title = "Penalty Apps", value = "${allConfigs.count { it.configType == AppConfigType.PENALTY }}", icon = Icons.Default.RemoveCircle, color = MaterialTheme.colorScheme.error)
            }
        }

        // App Config Breakdown
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("App Configuration", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    val rewardApps = allConfigs.filter { it.configType == AppConfigType.REWARD && it.isEnabled }
                    val penaltyApps = allConfigs.filter { it.configType == AppConfigType.PENALTY && it.isEnabled }

                    if (rewardApps.isEmpty() && penaltyApps.isEmpty()) {
                        Text("No apps configured. Go to Settings to add reward and penalty apps.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    } else {
                        rewardApps.take(3).forEach { app ->
                            AppBreakdownRow(config = app)
                        }
                        penaltyApps.take(3).forEach { app ->
                            AppBreakdownRow(config = app)
                        }
                    }
                }
            }
        }

        // Achievements (placeholder section)
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Getting Started", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("Track your activities and stay within your screen time limits to earn achievements and unlock rewards!", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
fun SegmentedButtons(selectedDays: Int, onSelect: (Int) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        listOf(7 to "7 Days", 14 to "14 Days", 30 to "30 Days").forEach { (days, label) ->
            FilterChip(
                selected = selectedDays == days,
                onClick = { onSelect(days) },
                label = { Text(label) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
fun AnalyticsSummaryCard(modifier: Modifier = Modifier, title: String, value: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
    Card(modifier = modifier) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(28.dp))
            Column {
                Text(value, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                Text(title, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
fun AppBreakdownRow(config: AppConfig) {
    val color = if (config.configType == AppConfigType.REWARD) Color(0xFF4CAF50) else MaterialTheme.colorScheme.error
    val context = LocalContext.current
    val appIcon: Drawable? = remember(config.packageName) {
        try {
            context.packageManager.getApplicationIcon(config.packageName)
        } catch (_: Exception) {
            null
        }
    }

    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        if (appIcon != null) {
            Image(
                bitmap = appIcon.toBitmap(20, 20).asImageBitmap(),
                contentDescription = config.appName,
                modifier = Modifier.size(20.dp)
            )
        } else {
            Icon(Icons.Default.Apps, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
        }
        Spacer(modifier = Modifier.width(8.dp))
        Text(config.appName, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium)
        Text(config.effectDescription, style = MaterialTheme.typography.bodySmall, color = color)
    }
}
