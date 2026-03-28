package com.screentime.app.ui.screens

import android.graphics.drawable.Drawable
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
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

        // App Config Breakdown (Part 7A)
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("App Configuration", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    val rewardApps = allConfigs.filter { it.configType == AppConfigType.REWARD && it.isEnabled }
                    val penaltyApps = allConfigs.filter { it.configType == AppConfigType.PENALTY && it.isEnabled }

                    if (rewardApps.isEmpty() && penaltyApps.isEmpty()) {
                        Text("No apps configured. Go to Settings to add reward and penalty apps.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    } else {
                        if (rewardApps.isNotEmpty()) {
                            Text("Reward Apps", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            rewardApps.forEach { app ->
                                AppBreakdownRow(config = app)
                            }
                            Text(
                                "Total Reward Apps: ${rewardApps.size}",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = Color(0xFF4CAF50)
                            )
                        }
                        if (penaltyApps.isNotEmpty()) {
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("Penalty Apps", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            penaltyApps.forEach { app ->
                                AppBreakdownRow(config = app)
                            }
                            Text(
                                "Total Penalty Apps: ${penaltyApps.size}",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
        }

        // Daily Timeline Chart (Part 7B + 7C)
        item {
            DailyTimelineChart(dataPoints = emptyList())
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
fun DailyTimelineChart(dataPoints: List<TimelineDataPoint>) {
    var hoveredIndex by remember { mutableStateOf<Int?>(null) }

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Daily Timeline", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(8.dp))

            if (dataPoints.isEmpty()) {
                Text(
                    "No timeline data yet. Data is recorded every 30 seconds while tracking.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 40.dp)
                )
            } else {
                // Tooltip for hovered point
                if (hoveredIndex != null && hoveredIndex!! < dataPoints.size) {
                    val point = dataPoints[hoveredIndex!!]
                    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                    Surface(
                        tonalElevation = 4.dp,
                        shape = MaterialTheme.shapes.small,
                        modifier = Modifier.padding(bottom = 4.dp)
                    ) {
                        Column(modifier = Modifier.padding(8.dp)) {
                            Text(timeFormat.format(Date(point.timestamp)), style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.SemiBold)
                            Text("${point.remainingSeconds / 60}m remaining", style = MaterialTheme.typography.labelSmall)
                            point.activeAppName?.let {
                                Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }

                val maxMinutes = (dataPoints.maxOfOrNull { it.remainingSeconds } ?: 3600L) / 60f
                val yMax = maxOf(maxMinutes * 1.1f, 1f)

                Canvas(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(180.dp)
                        .pointerInput(dataPoints) {
                            detectDragGestures(
                                onDragStart = { offset ->
                                    if (dataPoints.isNotEmpty()) {
                                        val fraction = offset.x / size.width
                                        val idx = (fraction * (dataPoints.size - 1)).toInt().coerceIn(0, dataPoints.size - 1)
                                        hoveredIndex = idx
                                    }
                                },
                                onDrag = { change, _ ->
                                    change.consume()
                                    if (dataPoints.isNotEmpty()) {
                                        val fraction = change.position.x / size.width
                                        val idx = (fraction * (dataPoints.size - 1)).toInt().coerceIn(0, dataPoints.size - 1)
                                        hoveredIndex = idx
                                    }
                                },
                                onDragEnd = { hoveredIndex = null },
                                onDragCancel = { hoveredIndex = null }
                            )
                        }
                ) {
                    val w = size.width
                    val h = size.height
                    val count = dataPoints.size

                    fun xFor(index: Int) = if (count > 1) w * index / (count - 1).toFloat() else w / 2f
                    fun yFor(point: TimelineDataPoint) = h - (point.remainingSeconds / 60f / yMax) * h

                    // Draw colored line segments
                    for (i in 0 until count - 1) {
                        val color = when {
                            dataPoints[i + 1].delta > 0 -> Color(0xFF4CAF50)
                            dataPoints[i + 1].delta < 0 -> Color(0xFFF44336)
                            else -> Color.DarkGray
                        }
                        drawLine(
                            color = color,
                            start = Offset(xFor(i), yFor(dataPoints[i])),
                            end = Offset(xFor(i + 1), yFor(dataPoints[i + 1])),
                            strokeWidth = 3f
                        )
                    }

                    // Draw hovered point indicator
                    hoveredIndex?.let { idx ->
                        if (idx < count) {
                            drawCircle(
                                color = Color(0xFF2196F3),
                                radius = 6f,
                                center = Offset(xFor(idx), yFor(dataPoints[idx]))
                            )
                        }
                    }

                    // X-axis time labels
                    val paint = android.graphics.Paint().apply {
                        textSize = 24f
                        this.color = android.graphics.Color.GRAY
                        isAntiAlias = true
                    }
                    val timeFormat = SimpleDateFormat("h:mm", Locale.getDefault())
                    if (dataPoints.isNotEmpty()) {
                        drawContext.canvas.nativeCanvas.drawText(
                            timeFormat.format(Date(dataPoints.first().timestamp)),
                            0f, h + 20f, paint
                        )
                    }
                    if (dataPoints.size > 1) {
                        val lastLabel = timeFormat.format(Date(dataPoints.last().timestamp))
                        val textWidth = paint.measureText(lastLabel)
                        drawContext.canvas.nativeCanvas.drawText(
                            lastLabel,
                            w - textWidth, h + 20f, paint
                        )
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
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
