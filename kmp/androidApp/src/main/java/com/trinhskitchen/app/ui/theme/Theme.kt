package com.trinhskitchen.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = lightColorScheme(
    primary = AppColors.Primary,
    onPrimary = AppColors.BadgeText,
    primaryContainer = AppColors.Primary.copy(alpha = 0.1f),
    onPrimaryContainer = AppColors.Primary,
    secondary = AppColors.Secondary,
    onSecondary = AppColors.BadgeText,
    background = AppColors.Background,
    onBackground = AppColors.TextPrimary,
    surface = AppColors.Surface,
    onSurface = AppColors.TextPrimary,
    surfaceVariant = AppColors.SurfaceVariant,
    onSurfaceVariant = AppColors.TextSecondary,
    error = AppColors.Error,
    onError = AppColors.BadgeText,
    outline = AppColors.Divider
)

private val DarkColorScheme = darkColorScheme(
    primary = AppColors.Primary,
    onPrimary = AppColors.BadgeText,
    primaryContainer = AppColors.Primary.copy(alpha = 0.2f),
    onPrimaryContainer = AppColors.Primary,
    secondary = AppColors.Secondary,
    onSecondary = AppColors.BadgeText,
    background = AppColors.TextPrimary,
    onBackground = AppColors.Surface,
    surface = AppColors.TextPrimary,
    onSurface = AppColors.Surface,
    surfaceVariant = AppColors.TextSecondary,
    onSurfaceVariant = AppColors.SurfaceVariant,
    error = AppColors.Error,
    onError = AppColors.BadgeText,
    outline = AppColors.TextSecondary
)

@Composable
fun TrinhsGroupTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
