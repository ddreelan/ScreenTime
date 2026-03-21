package com.screentime.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF4FC3F7),
    onPrimary = Color(0xFF003547),
    primaryContainer = Color(0xFF004D64),
    secondary = Color(0xFF80CBC4),
    onSecondary = Color(0xFF00201E),
    tertiary = Color(0xFFFFCC80),
    background = Color(0xFF0D1117),
    surface = Color(0xFF161B22),
    surfaceVariant = Color(0xFF1E242D),
    onBackground = Color(0xFFE6EDF3),
    onSurface = Color(0xFFE6EDF3)
)

private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF0288D1),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFBBDEFB),
    secondary = Color(0xFF00897B),
    onSecondary = Color.White,
    tertiary = Color(0xFFEF6C00),
    background = Color(0xFFF5F5F5),
    surface = Color.White,
    surfaceVariant = Color(0xFFF0F4F8),
    onBackground = Color(0xFF1A1A1A),
    onSurface = Color(0xFF1A1A1A)
)

@Composable
fun ScreenTimeTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography(),
        content = content
    )
}
