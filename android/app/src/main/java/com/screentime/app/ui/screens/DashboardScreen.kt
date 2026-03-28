package com.screentime.app.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.screentime.app.data.model.*
import com.screentime.app.viewmodel.DashboardViewModel
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    paddingValues: PaddingValues,
    viewModel: DashboardViewModel = viewModel()
) {
    val summary by viewModel.todaySummary.collectAsState()
    val activities by viewModel.todayActivities.collectAsState()
    val motivationalMessage by viewModel.motivationalMessage.collectAsState()

    var activeQuickStart by remember { mutableStateOf<ActivityType?>(null) }
    var quickStartElapsed by remember { mutableLongStateOf(0L) }
    var quickStartRunning by remember { mutableStateOf(false) }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(paddingValues),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text(
                "Screen Time",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold
            )
        }

        item {
            TimeRingCard(summary = summary)
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    modifier = Modifier.weight(1f),
                    title = "Used",
                    value = summary.totalUsedSeconds.toFormattedTime(),
                    icon = Icons.Default.AccessTime,
                    color = MaterialTheme.colorScheme.tertiary
                )
                StatCard(
                    modifier = Modifier.weight(1f),
                    title = "Earned",
                    value = "+${summary.totalEarnedSeconds.toFormattedTime()}",
                    icon = Icons.Default.AddCircle,
                    color = Color(0xFF4CAF50)
                )
                StatCard(
                    modifier = Modifier.weight(1f),
                    title = "Limit",
                    value = summary.totalAllocatedSeconds.toFormattedTime(),
                    icon = Icons.Default.Timer,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }

        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = motivationalMessage,
                    modifier = Modifier.padding(16.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        if (activities.isNotEmpty()) {
            item {
                Text("Today's Activities", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }
            items(activities.take(3)) { activity ->
                ActivityRowCard(activity = activity)
            }
        }

        item {
            QuickStartSection(onQuickStart = { activityType ->
                activeQuickStart = activityType
                quickStartElapsed = 0L
                quickStartRunning = false
            })
        }
    }

    activeQuickStart?.let { activityType ->
        QuickStartBottomSheet(
            activityType = activityType,
            elapsed = quickStartElapsed,
            isRunning = quickStartRunning,
            onElapsedUpdate = { quickStartElapsed = it },
            onRunningChange = { quickStartRunning = it },
            onStopAndSave = {
                val durationSeconds = quickStartElapsed
                val baseReward = activityType.rewardMinutes * 60.0
                val durationMultiplier = minOf(durationSeconds / (15.0 * 60.0), 2.0)
                val rewardSeconds = (baseReward * durationMultiplier).toLong()

                val activity = ActivityRecord(
                    type = activityType,
                    startTime = System.currentTimeMillis() - (durationSeconds * 1000),
                    endTime = System.currentTimeMillis(),
                    durationSeconds = durationSeconds,
                    verificationMethod = VerificationMethod.MANUAL,
                    status = ActivityStatus.VERIFIED,
                    rewardEarnedSeconds = rewardSeconds
                )
                viewModel.saveActivityAndEarnTime(activity, rewardSeconds)
                quickStartRunning = false
                activeQuickStart = null
            },
            onDismiss = {
                quickStartRunning = false
                activeQuickStart = null
            }
        )
    }
}

@Composable
fun TimeRingCard(summary: DailyScreenTimeSummary) {
    val progressColor = when {
        summary.usagePercentage < 0.6f -> Color(0xFF4CAF50)
        summary.usagePercentage < 0.85f -> Color(0xFFFF9800)
        else -> MaterialTheme.colorScheme.error
    }
    val animatedProgress by animateFloatAsState(
        targetValue = summary.usagePercentage,
        animationSpec = tween(durationMillis = 800),
        label = "progress"
    )

    Card(modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(240.dp),
            contentAlignment = Alignment.Center
        ) {
            val trackColor = MaterialTheme.colorScheme.surfaceVariant
            Box(
                modifier = Modifier
                    .size(180.dp)
                    .drawBehind {
                        val strokeWidth = 24.dp.toPx()
                        val inset = strokeWidth / 2
                        drawArc(
                            color = trackColor,
                            startAngle = -210f,
                            sweepAngle = 240f,
                            useCenter = false,
                            topLeft = Offset(inset, inset),
                            size = Size(size.width - strokeWidth, size.height - strokeWidth),
                            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                        )
                        drawArc(
                            color = progressColor,
                            startAngle = -210f,
                            sweepAngle = 240f * animatedProgress,
                            useCenter = false,
                            topLeft = Offset(inset, inset),
                            size = Size(size.width - strokeWidth, size.height - strokeWidth),
                            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                        )
                    },
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = summary.remainingSeconds.toFormattedTime(),
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = progressColor
                    )
                    Text("remaining", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
fun StatCard(modifier: Modifier = Modifier, title: String, value: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
    Card(modifier = modifier) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
            Text(value, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyMedium)
            Text(title, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun ActivityRowCard(activity: ActivityRecord) {
    val statusColor = when (activity.status) {
        ActivityStatus.VERIFIED -> Color(0xFF4CAF50)
        ActivityStatus.FAILED -> MaterialTheme.colorScheme.error
        ActivityStatus.IN_PROGRESS -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(Icons.Default.DirectionsWalk, contentDescription = null, tint = statusColor, modifier = Modifier.size(32.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(activity.displayName, fontWeight = FontWeight.Medium)
                if (activity.rewardEarnedSeconds > 0) {
                    Text("+${activity.rewardEarnedSeconds / 60} min earned", color = Color(0xFF4CAF50), style = MaterialTheme.typography.bodySmall)
                }
            }
            AssistChip(
                onClick = {},
                label = { Text(activity.status.name.lowercase().replaceFirstChar { it.uppercase() }) },
                colors = AssistChipDefaults.assistChipColors(containerColor = statusColor.copy(alpha = 0.1f))
            )
        }
    }
}

@Composable
fun QuickStartSection(onQuickStart: (ActivityType) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Quick Start", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            listOf(
                Triple("Walk", Icons.Default.DirectionsWalk, Color(0xFF4CAF50)),
                Triple("Read", Icons.Default.MenuBook, MaterialTheme.colorScheme.primary),
                Triple("Meditate", Icons.Default.SelfImprovement, Color(0xFF9C27B0)),
                Triple("Run", Icons.Default.DirectionsRun, Color(0xFFFF9800))
            ).forEach { (label, icon, color) ->
                val activityType = when (label) {
                    "Walk" -> ActivityType.WALKING
                    "Read" -> ActivityType.READING
                    "Meditate" -> ActivityType.MEDITATION
                    "Run" -> ActivityType.RUNNING
                    else -> ActivityType.CUSTOM
                }
                QuickActionButton(
                    modifier = Modifier.weight(1f),
                    label = label,
                    icon = icon,
                    color = color,
                    onClick = { onQuickStart(activityType) }
                )
            }
        }
    }
}

@Composable
fun QuickActionButton(modifier: Modifier = Modifier, label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color, onClick: () -> Unit) {
    Card(modifier = modifier, colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.1f)), onClick = onClick) {
        Column(
            modifier = Modifier.padding(8.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(icon, contentDescription = label, tint = color, modifier = Modifier.size(28.dp))
            Text(label, style = MaterialTheme.typography.bodySmall, color = color)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickStartBottomSheet(
    activityType: ActivityType,
    elapsed: Long,
    isRunning: Boolean,
    onElapsedUpdate: (Long) -> Unit,
    onRunningChange: (Boolean) -> Unit,
    onStopAndSave: () -> Unit,
    onDismiss: () -> Unit
) {
    LaunchedEffect(isRunning, elapsed) {
        if (isRunning) {
            delay(1000L)
            onElapsedUpdate(elapsed + 1)
        }
    }

    val mins = elapsed / 60
    val secs = elapsed % 60
    val elapsedFormatted = String.format("%02d:%02d", mins, secs)

    val baseReward = activityType.rewardMinutes * 60.0
    val durationMultiplier = minOf(elapsed / (15.0 * 60.0), 2.0)
    val estimatedRewardMinutes = (baseReward * durationMultiplier) / 60.0

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = when (activityType) {
                    ActivityType.WALKING -> Icons.Default.DirectionsWalk
                    ActivityType.RUNNING -> Icons.Default.DirectionsRun
                    ActivityType.READING -> Icons.Default.MenuBook
                    ActivityType.MEDITATION -> Icons.Default.SelfImprovement
                    ActivityType.CYCLING -> Icons.Default.DirectionsBike
                    ActivityType.EXERCISE -> Icons.Default.FitnessCenter
                    else -> Icons.Default.Star
                },
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )

            Text(activityType.displayName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            Text(elapsedFormatted, style = MaterialTheme.typography.displayMedium, fontWeight = FontWeight.Bold)

            Text(
                "Earning: +${String.format("%.1f", estimatedRewardMinutes)}m",
                style = MaterialTheme.typography.titleMedium,
                color = Color(0xFF4CAF50)
            )

            Spacer(modifier = Modifier.height(8.dp))

            if (!isRunning) {
                Button(
                    onClick = { onRunningChange(true) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                ) {
                    Text("Start", style = MaterialTheme.typography.titleMedium)
                }
            } else {
                Button(
                    onClick = onStopAndSave,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("Stop & Save", style = MaterialTheme.typography.titleMedium)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
