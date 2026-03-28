package com.screentime.app.ui

import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.screentime.app.service.AuthService
import com.screentime.app.ui.screens.*

@Composable
fun ScreenTimeApp() {
    val context = LocalContext.current
    val authService = remember { AuthService(context) }
    val isAuthenticated by authService.authState.collectAsState()
    var showSplash by remember { mutableStateOf(true) }

    when {
        showSplash -> {
            SplashScreen(onFinished = { showSplash = false })
        }
        !isAuthenticated -> {
            SignInScreen(
                authService = authService,
                onAuthenticated = { /* StateFlow will update UI automatically */ }
            )
        }
        else -> {
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
    }
}
