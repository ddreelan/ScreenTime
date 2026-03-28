package com.screentime.app.ui.screens

import android.graphics.drawable.Drawable
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.graphics.drawable.toBitmap
import androidx.lifecycle.viewmodel.compose.viewModel
import com.screentime.app.data.model.*
import com.screentime.app.viewmodel.SettingsViewModel

@Composable
fun SettingsScreen(
    paddingValues: PaddingValues,
    viewModel: SettingsViewModel = viewModel()
) {
    val rewardApps by viewModel.rewardApps.collectAsState()
    val penaltyApps by viewModel.penaltyApps.collectAsState()
    val userProfile by viewModel.userProfile.collectAsState()

    var showAddReward by remember { mutableStateOf(false) }
    var showAddPenalty by remember { mutableStateOf(false) }
    var editingConfig by remember { mutableStateOf<AppConfig?>(null) }
    var dailyHours by remember { mutableIntStateOf(userProfile?.let { (it.dailyScreenTimeLimitSeconds / 3600).toInt() } ?: 2) }
    var dailyMinutes by remember { mutableIntStateOf(userProfile?.let { ((it.dailyScreenTimeLimitSeconds % 3600) / 60).toInt() } ?: 0) }

    LaunchedEffect(userProfile) {
        userProfile?.let {
            dailyHours = (it.dailyScreenTimeLimitSeconds / 3600).toInt()
            dailyMinutes = ((it.dailyScreenTimeLimitSeconds % 3600) / 60).toInt()
        }
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(paddingValues),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text("Settings", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        }

        // Daily Limit
        item {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Daily Screen Time Limit", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("Hours", style = MaterialTheme.typography.bodySmall)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                IconButton(onClick = { if (dailyHours > 0) dailyHours-- }) { Icon(Icons.Default.Remove, null) }
                                Text("$dailyHours", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                                IconButton(onClick = { if (dailyHours < 12) dailyHours++ }) { Icon(Icons.Default.Add, null) }
                            }
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("Minutes", style = MaterialTheme.typography.bodySmall)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                IconButton(onClick = { if (dailyMinutes >= 5) dailyMinutes -= 5 }) { Icon(Icons.Default.Remove, null) }
                                Text("$dailyMinutes", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                                IconButton(onClick = { if (dailyMinutes <= 55) dailyMinutes += 5 }) { Icon(Icons.Default.Add, null) }
                            }
                        }
                        Spacer(modifier = Modifier.weight(1f))
                        Button(onClick = { viewModel.saveDailyLimit(dailyHours, dailyMinutes) }) {
                            Text("Save")
                        }
                    }
                }
            }
        }

        // Reward Apps
        item {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Reward Apps", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                TextButton(onClick = { showAddReward = true }) {
                    Icon(Icons.Default.Add, null, tint = Color(0xFF4CAF50))
                    Text("Add", color = Color(0xFF4CAF50))
                }
            }
        }

        items(rewardApps, key = { it.id }) { config ->
            AppConfigCard(
                config = config,
                onEdit = { editingConfig = config },
                onToggle = { viewModel.toggleAppEnabled(config) },
                onDelete = { viewModel.deleteAppConfig(config.id) }
            )
        }

        // Penalty Apps
        item {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Penalty Apps", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                TextButton(onClick = { showAddPenalty = true }) {
                    Icon(Icons.Default.Add, null, tint = MaterialTheme.colorScheme.error)
                    Text("Add", color = MaterialTheme.colorScheme.error)
                }
            }
        }

        items(penaltyApps, key = { it.id }) { config ->
            AppConfigCard(
                config = config,
                onEdit = { editingConfig = config },
                onToggle = { viewModel.toggleAppEnabled(config) },
                onDelete = { viewModel.deleteAppConfig(config.id) }
            )
        }

        // Default Usage Penalty
        item {
            var defaultPenaltyRate by remember { mutableFloatStateOf(1.0f) }
            var defaultPenaltyText by remember { mutableStateOf("1.0") }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Default Usage Penalty", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text("Rate applied when using unconfigured apps", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text("Effect: -${String.format("%.1f", defaultPenaltyRate)} min/min", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.error)
                    Slider(
                        value = defaultPenaltyRate,
                        onValueChange = { defaultPenaltyRate = it; viewModel.saveDefaultPenaltyRate(-it.toDouble()) },
                        valueRange = 0.0f..5.0f,
                        steps = 49
                    )
                    OutlinedTextField(
                        value = defaultPenaltyText,
                        onValueChange = { newValue ->
                            defaultPenaltyText = newValue
                            val parsed = newValue.toFloatOrNull()
                            if (parsed != null && parsed in 0.0f..5.0f) {
                                defaultPenaltyRate = parsed
                                viewModel.saveDefaultPenaltyRate(-parsed.toDouble())
                            }
                        },
                        label = { Text("Precise value") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
    }

    if (showAddReward) {
        AddEditAppDialog(configType = AppConfigType.REWARD, onDismiss = { showAddReward = false }, onSave = { viewModel.saveAppConfig(it); showAddReward = false })
    }
    if (showAddPenalty) {
        AddEditAppDialog(configType = AppConfigType.PENALTY, onDismiss = { showAddPenalty = false }, onSave = { viewModel.saveAppConfig(it); showAddPenalty = false })
    }
    editingConfig?.let { config ->
        AddEditAppDialog(existingConfig = config, onDismiss = { editingConfig = null }, onSave = { viewModel.saveAppConfig(it); editingConfig = null })
    }
}

@Composable
fun AppConfigCard(config: AppConfig, onEdit: () -> Unit, onToggle: () -> Unit, onDelete: () -> Unit) {
    val accentColor = if (config.configType == AppConfigType.REWARD) Color(0xFF4CAF50) else MaterialTheme.colorScheme.error
    val context = LocalContext.current
    val appIcon: Drawable? = remember(config.packageName) {
        try {
            context.packageManager.getApplicationIcon(config.packageName)
        } catch (_: Exception) {
            null
        }
    }

    Card(modifier = Modifier.fillMaxWidth(), onClick = onEdit) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Surface(shape = MaterialTheme.shapes.small, color = accentColor.copy(alpha = 0.1f), modifier = Modifier.size(40.dp)) {
                Box(contentAlignment = Alignment.Center) {
                    if (appIcon != null) {
                        Image(
                            bitmap = appIcon.toBitmap(40, 40).asImageBitmap(),
                            contentDescription = config.appName,
                            modifier = Modifier.size(28.dp)
                        )
                    } else {
                        Icon(Icons.Default.Apps, contentDescription = null, tint = accentColor, modifier = Modifier.size(20.dp))
                    }
                }
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(config.appName, fontWeight = FontWeight.Medium)
                Text(config.effectDescription, style = MaterialTheme.typography.bodySmall, color = accentColor)
            }
            Switch(checked = config.isEnabled, onCheckedChange = { onToggle() })
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
fun AddEditAppDialog(
    existingConfig: AppConfig? = null,
    configType: AppConfigType = AppConfigType.REWARD,
    onDismiss: () -> Unit,
    onSave: (AppConfig) -> Unit
) {
    val effectiveType = existingConfig?.configType ?: configType
    var appName by remember { mutableStateOf(existingConfig?.appName ?: "") }
    var packageName by remember { mutableStateOf(existingConfig?.packageName ?: "") }
    var minutesPerMinute by remember { mutableFloatStateOf(existingConfig?.let { kotlin.math.abs(it.minutesPerMinute).toFloat() } ?: 1.0f) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (existingConfig != null) "Edit App" else "Add ${if (effectiveType == AppConfigType.REWARD) "Reward" else "Penalty"} App") },
        text = {
            var minutesPerMinuteText by remember { mutableStateOf(String.format("%.1f", minutesPerMinute)) }
            var textIsValid by remember { mutableStateOf(true) }

            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(value = appName, onValueChange = { appName = it }, label = { Text("App Name") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = packageName, onValueChange = { packageName = it }, label = { Text("Package Name") }, modifier = Modifier.fillMaxWidth())
                Text("Time effect: ${String.format("%.1f", minutesPerMinute)} min/min", style = MaterialTheme.typography.bodyMedium)
                Slider(
                    value = minutesPerMinute,
                    onValueChange = {
                        minutesPerMinute = it
                        minutesPerMinuteText = String.format("%.1f", it)
                        textIsValid = true
                    },
                    valueRange = 0.1f..5.0f,
                    steps = 48
                )
                OutlinedTextField(
                    value = minutesPerMinuteText,
                    onValueChange = { newValue ->
                        minutesPerMinuteText = newValue
                        val parsed = newValue.toFloatOrNull()
                        if (parsed != null && parsed in 0.1f..5.0f) {
                            minutesPerMinute = parsed
                            textIsValid = true
                        } else {
                            textIsValid = newValue.isEmpty()
                        }
                    },
                    label = { Text("Precise value") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    isError = !textIsValid,
                    modifier = Modifier.fillMaxWidth()
                )
                Text(
                    "Each minute using this app ${if (effectiveType == AppConfigType.REWARD) "earns" else "costs"} ${String.format("%.1f", minutesPerMinute)} extra minute(s)",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val effectValue = if (effectiveType == AppConfigType.REWARD) minutesPerMinute.toDouble() else -minutesPerMinute.toDouble()
                    onSave(AppConfig(
                        id = existingConfig?.id ?: java.util.UUID.randomUUID().toString(),
                        packageName = packageName.ifEmpty { "com.app.${appName.lowercase().replace(" ", ".")}" },
                        appName = appName,
                        configType = effectiveType,
                        minutesPerMinute = effectValue
                    ))
                },
                enabled = appName.isNotEmpty()
            ) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
