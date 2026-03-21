package com.screentime.app.ui

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavController
import androidx.navigation.compose.currentBackStackEntryAsState

data class NavItem(val route: String, val label: String, val icon: ImageVector)

@Composable
fun MainScaffold(
    navController: NavController,
    content: @Composable (PaddingValues) -> Unit
) {
    val navItems = listOf(
        NavItem("dashboard", "Home", Icons.Default.Home),
        NavItem("analytics", "Analytics", Icons.Default.BarChart),
        NavItem("activities", "Activities", Icons.Default.DirectionsWalk),
        NavItem("profile", "Profile", Icons.Default.Person),
        NavItem("settings", "Settings", Icons.Default.Settings)
    )

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar {
                navItems.forEach { item ->
                    NavigationBarItem(
                        icon = { Icon(item.icon, contentDescription = item.label) },
                        label = { Text(item.label) },
                        selected = currentRoute == item.route,
                        onClick = {
                            if (currentRoute != item.route) {
                                navController.navigate(item.route) {
                                    popUpTo("dashboard") { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        }
                    )
                }
            }
        }
    ) { paddingValues ->
        content(paddingValues)
    }
}
