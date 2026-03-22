package com.screentime.app.ui.screens

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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.screentime.app.viewmodel.ActivityViewModel
import com.screentime.app.viewmodel.SettingsViewModel

@Composable
fun ProfileScreen(
    paddingValues: PaddingValues,
    settingsViewModel: SettingsViewModel = viewModel(),
    activityViewModel: ActivityViewModel = viewModel()
) {
    val userProfile by settingsViewModel.userProfile.collectAsState()
    val allActivities by activityViewModel.allActivities.collectAsState()
    var isEditing by remember { mutableStateOf(false) }
    var name by remember { mutableStateOf("") }
    var age by remember { mutableStateOf("") }

    LaunchedEffect(userProfile) {
        name = userProfile?.name ?: ""
        age = userProfile?.age?.toString() ?: ""
    }

    val availableGoals = listOf(
        "Reduce social media usage", "Spend more time outdoors",
        "Read more books", "Exercise regularly",
        "Better work-life balance", "Improve sleep habits"
    )
    val currentGoals = userProfile?.goals?.split(",")?.filter { it.isNotBlank() } ?: emptyList()
    val selectedGoals = remember(currentGoals) { mutableStateListOf<String>().apply { addAll(currentGoals) } }

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(paddingValues),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text("Profile", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        }

        item {
            // Profile header card
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Surface(shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.primaryContainer, modifier = Modifier.size(80.dp)) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = (userProfile?.name ?: "U").take(2).uppercase(),
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }

                    if (isEditing) {
                        OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth())
                        OutlinedTextField(value = age, onValueChange = { age = it }, label = { Text("Age") }, modifier = Modifier.fillMaxWidth())
                    } else {
                        Text(userProfile?.name ?: "Set up your profile", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        if (userProfile?.age != null && userProfile!!.age > 0) {
                            Text("Age ${userProfile?.age}", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }

                    Button(onClick = {
                        if (isEditing) {
                            settingsViewModel.saveUserProfile(name, age.toIntOrNull() ?: 0, selectedGoals)
                        }
                        isEditing = !isEditing
                    }) {
                        Text(if (isEditing) "Save Profile" else "Edit Profile")
                    }
                }
            }
        }

        item {
            // Stats
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Lifetime Statistics", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                        val verifiedActivities = allActivities.filter { it.status == com.screentime.app.data.model.ActivityStatus.VERIFIED }
                        ProfileStatItem("Activities", "${verifiedActivities.size}", Icons.Default.DirectionsWalk, Color(0xFF4CAF50))
                        ProfileStatItem("Total Earned", "+${verifiedActivities.sumOf { it.rewardEarnedSeconds } / 60}m", Icons.Default.AddCircle, MaterialTheme.colorScheme.primary)
                    }
                }
            }
        }

        item {
            Text("Goals", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        }

        if (isEditing) {
            items(availableGoals) { goal ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(
                        checked = goal in selectedGoals,
                        onCheckedChange = { checked ->
                            if (checked) selectedGoals.add(goal)
                            else selectedGoals.remove(goal)
                        }
                    )
                    Text(goal, style = MaterialTheme.typography.bodyMedium)
                }
            }
        } else {
            if (currentGoals.isEmpty()) {
                item {
                    Text("No goals set. Tap 'Edit Profile' to add goals.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            } else {
                items(currentGoals) { goal ->
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF4CAF50), modifier = Modifier.size(20.dp))
                        Text(goal, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileStatItem(title: String, value: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(28.dp))
        Text(value, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
        Text(title, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
