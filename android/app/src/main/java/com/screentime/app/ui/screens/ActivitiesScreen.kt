package com.screentime.app.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.screentime.app.data.model.*
import com.screentime.app.viewmodel.ActivityViewModel

@Composable
fun ActivitiesScreen(
    paddingValues: PaddingValues,
    viewModel: ActivityViewModel = viewModel()
) {
    val isVerifying by viewModel.isVerifying.collectAsState()
    val currentActivity by viewModel.currentActivity.collectAsState()
    val verificationProgress by viewModel.verificationProgress.collectAsState()
    val verificationMessage by viewModel.verificationMessage.collectAsState()
    val todayActivities by viewModel.todayActivities.collectAsState()
    val todayEarned by viewModel.todayEarnedSeconds.collectAsState()
    val showReward by viewModel.showRewardAnimation.collectAsState()
    val recentlyEarned by viewModel.recentlyEarned.collectAsState()

    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Text("Activities", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
            }

            item {
                EarnedTimeBanner(earnedSeconds = todayEarned)
            }

            if (isVerifying && currentActivity != null) {
                item {
                    VerificationCard(
                        activity = currentActivity!!,
                        progress = verificationProgress,
                        message = verificationMessage,
                        onTap = { viewModel.recordTap() },
                        onComplete = { viewModel.completeManualActivity() },
                        onCancel = { viewModel.cancelActivity() }
                    )
                }
            } else {
                item {
                    Text("Start an Activity", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                }
                item {
                    ActivityTypeGrid { type -> viewModel.startActivity(type) }
                }
            }

            if (todayActivities.isNotEmpty()) {
                item {
                    Text("Today's History", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                }
                items(todayActivities) { activity ->
                    ActivityHistoryCard(activity = activity)
                }
            }
        }

        AnimatedVisibility(
            visible = showReward,
            enter = scaleIn() + fadeIn(),
            exit = scaleOut() + fadeOut(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            RewardOverlay(earnedSeconds = recentlyEarned)
        }
    }
}

@Composable
fun EarnedTimeBanner(earnedSeconds: Long) {
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF4CAF50).copy(alpha = 0.1f))) {
        Row(
            modifier = Modifier.padding(16.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(Icons.Default.AddCircle, contentDescription = null, tint = Color(0xFF4CAF50), modifier = Modifier.size(32.dp))
            Column {
                Text("Today's Earned Time", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("+${earnedSeconds / 60} minutes", fontWeight = FontWeight.Bold, color = Color(0xFF4CAF50))
            }
        }
    }
}

@Composable
fun ActivityTypeGrid(onStart: (ActivityType) -> Unit) {
    val activities = ActivityType.entries
    LazyVerticalGrid(
        columns = GridCells.Fixed(3),
        modifier = Modifier.heightIn(max = 400.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(activities.size) { index ->
            val type = activities[index]
            ActivityTypeCard(type = type, onClick = { onStart(type) })
        }
    }
}

@Composable
fun ActivityTypeCard(type: ActivityType, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                imageVector = when (type) {
                    ActivityType.WALKING -> Icons.Default.DirectionsWalk
                    ActivityType.RUNNING -> Icons.Default.DirectionsRun
                    ActivityType.CYCLING -> Icons.Default.DirectionsBike
                    ActivityType.MEDITATION -> Icons.Default.SelfImprovement
                    ActivityType.READING -> Icons.Default.MenuBook
                    ActivityType.EXERCISE -> Icons.Default.FitnessCenter
                    ActivityType.OUTDOOR -> Icons.Default.WbSunny
                    ActivityType.CUSTOM -> Icons.Default.Star
                },
                contentDescription = type.displayName,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(32.dp)
            )
            Text(type.displayName, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Medium)
            Text("+${type.rewardMinutes.toInt()}m", style = MaterialTheme.typography.bodySmall, color = Color(0xFF4CAF50))
        }
    }
}

@Composable
fun VerificationCard(
    activity: ActivityRecord,
    progress: Float,
    message: String,
    onTap: () -> Unit,
    onComplete: () -> Unit,
    onCancel: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text("Verifying: ${activity.displayName}", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxWidth().height(8.dp)
            )
            Text(message, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)

            if (activity.verificationMethod == VerificationMethod.TAP_COUNT) {
                Button(onClick = onTap, modifier = Modifier.fillMaxWidth()) {
                    Text("TAP TO VERIFY")
                }
            }
            if (activity.verificationMethod == VerificationMethod.MANUAL) {
                Button(onClick = onComplete, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))) {
                    Text("COMPLETE ACTIVITY")
                }
            }
            TextButton(onClick = onCancel) {
                Text("Cancel", color = MaterialTheme.colorScheme.error)
            }
        }
    }
}

@Composable
fun ActivityHistoryCard(activity: ActivityRecord) {
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
            Surface(shape = MaterialTheme.shapes.medium, color = statusColor.copy(alpha = 0.1f), modifier = Modifier.size(48.dp)) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Default.DirectionsWalk, contentDescription = null, tint = statusColor)
                }
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(activity.displayName, fontWeight = FontWeight.Medium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (activity.rewardEarnedSeconds > 0) {
                        Text("+${activity.rewardEarnedSeconds / 60}m earned", color = Color(0xFF4CAF50), style = MaterialTheme.typography.bodySmall)
                    }
                    if (activity.durationSeconds > 0) {
                        Text("${activity.durationSeconds / 60}m duration", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            AssistChip(
                onClick = {},
                label = { Text(activity.status.name.lowercase().replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.bodySmall) },
                colors = AssistChipDefaults.assistChipColors(containerColor = statusColor.copy(alpha = 0.1f))
            )
        }
    }
}

@Composable
fun RewardOverlay(earnedSeconds: Long) {
    Card(
        modifier = Modifier.padding(32.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Column(
            modifier = Modifier.padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(Icons.Default.Star, contentDescription = null, tint = Color(0xFFFFD700), modifier = Modifier.size(64.dp))
            Text("🎉 Activity Verified!", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("+${earnedSeconds / 60} minutes earned!", color = Color(0xFF4CAF50), style = MaterialTheme.typography.titleMedium)
        }
    }
}
