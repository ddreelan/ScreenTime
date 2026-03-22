package com.screentime.app.ui

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.screentime.app.ui.screens.*

@Composable
fun ScreenTimeApp() {
    val navController = rememberNavController()

    MainScaffold(navController = navController) { paddingValues ->
        NavHost(navController = navController, startDestination = "dashboard") {
            composable("dashboard") { DashboardScreen(paddingValues) }
            composable("analytics") { AnalyticsScreen(paddingValues) }
            composable("activities") { ActivitiesScreen(paddingValues) }
            composable("profile") { ProfileScreen(paddingValues) }
            composable("settings") { SettingsScreen(paddingValues) }
        }
    }
}
