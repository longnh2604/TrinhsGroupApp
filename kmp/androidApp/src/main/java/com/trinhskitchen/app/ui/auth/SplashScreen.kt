package com.trinhskitchen.app.ui.auth

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.R
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.viewmodel.AuthState
import com.trinhsgroup.shared.viewmodel.AuthViewModel
import kotlinx.coroutines.delay

/**
 * Splash screen with animated logo.
 * Mirrors iOS SplashView.
 * 
 * Flow:
 * 1. Show splash animation
 * 2. Call restoreSession() to check stored auth state
 * 3. Wait for authState to resolve (not Loading)
 * 4. Navigate to Main (authenticated) or Login (unauthenticated)
 */
@Composable
fun SplashScreen(
    authViewModel: AuthViewModel,
    onNavigateToMain: () -> Unit,
    onNavigateToLogin: () -> Unit
) {
    var startAnimation by remember { mutableStateOf(false) }
    var animationComplete by remember { mutableStateOf(false) }
    val authState by authViewModel.authState.collectAsState()
    
    val alphaAnim by animateFloatAsState(
        targetValue = if (startAnimation) 1f else 0f,
        animationSpec = tween(durationMillis = 1000),
        label = "alpha"
    )
    
    val scaleAnim by animateFloatAsState(
        targetValue = if (startAnimation) 1f else 0.5f,
        animationSpec = tween(durationMillis = 1000),
        label = "scale"
    )
    
    // Start animation and restore session
    LaunchedEffect(key1 = true) {
        startAnimation = true
        // Initiate session restoration
        authViewModel.restoreSession()
        // Wait for minimum splash duration
        delay(2000)
        animationComplete = true
    }
    
    // Navigate when animation is complete AND auth state is resolved
    LaunchedEffect(animationComplete, authState) {
        if (animationComplete && authState != AuthState.Loading) {
            when (authState) {
                AuthState.Authenticated -> {
                    println("🔐 SplashScreen: Authenticated, navigating to Main")
                    onNavigateToMain()
                }
                AuthState.Unauthenticated -> {
                    println("🔐 SplashScreen: Unauthenticated, navigating to Login")
                    onNavigateToLogin()
                }
                else -> { /* Still loading, wait */ }
            }
        }
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Primary),
        contentAlignment = Alignment.Center
    ) {
        // Logo placeholder - replace with actual app logo
        Box(
            modifier = Modifier
                .size(150.dp)
                .alpha(alphaAnim)
                .scale(scaleAnim)
                .background(
                    color = MaterialTheme.colorScheme.surface,
                    shape = MaterialTheme.shapes.medium
                ),
            contentAlignment = Alignment.Center
        ) {
            // TODO: Replace with actual logo image
            // Image(
            //     painter = painterResource(id = R.drawable.logo),
            //     contentDescription = "TrinhsGroup Logo",
            //     modifier = Modifier.size(100.dp)
            // )
        }
    }
}
