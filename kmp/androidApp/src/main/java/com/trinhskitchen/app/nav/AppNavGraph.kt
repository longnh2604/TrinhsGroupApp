package com.trinhskitchen.app.nav

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.trinhskitchen.app.firebase.FirestoreClient
import com.trinhskitchen.app.ui.auth.LoginScreen
import com.trinhskitchen.app.ui.auth.SignupScreen
import com.trinhskitchen.app.ui.auth.SplashScreen
import com.trinhskitchen.app.ui.checkout.CheckoutScreen
import com.trinhskitchen.app.ui.checkout.OrderReceivedScreen
import com.trinhskitchen.app.ui.main.MainScreen
import com.trinhskitchen.app.ui.product.ProductDetailScreen
import com.trinhsgroup.shared.viewmodel.AuthViewModel
import com.trinhsgroup.shared.viewmodel.HistoryViewModel
import com.trinhsgroup.shared.viewmodel.MainViewModel
import com.trinhsgroup.shared.viewmodel.PointsViewModel
import org.koin.compose.koinInject

/**
 * Main navigation graph for the app.
 */
@Composable
fun AppNavGraph(
    navController: NavHostController
) {
    val authViewModel: AuthViewModel = koinInject()
    val mainViewModel: MainViewModel = koinInject()
    val historyViewModel: HistoryViewModel = koinInject()
    val pointsViewModel: PointsViewModel = koinInject()
    val firestoreClient: FirestoreClient = koinInject()
    
    NavHost(
        navController = navController,
        startDestination = Screen.Splash.route
    ) {
        // Splash screen - handles session restoration and auth state checking
        composable(Screen.Splash.route) {
            SplashScreen(
                authViewModel = authViewModel,
                onNavigateToMain = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
                    }
                },
                onNavigateToLogin = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
                    }
                }
            )
        }
        
        // Login screen
        composable(Screen.Login.route) {
            LoginScreen(
                viewModel = authViewModel,
                onLoginSuccess = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNavigateToSignup = {
                    navController.navigate(Screen.Signup.route)
                },
                onNavigateToForgotPassword = {
                    navController.navigate(Screen.ForgotPassword.route)
                }
            )
        }
        
        // Signup screen
        composable(Screen.Signup.route) {
            SignupScreen(
                viewModel = authViewModel,
                onSignupSuccess = {
                    navController.popBackStack()
                },
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
        
        // Forgot password (placeholder)
        composable(Screen.ForgotPassword.route) {
            // TODO: Implement ForgotPasswordScreen
        }
        
        // Main app shell with bottom tabs
        composable(Screen.Main.route) {
            MainScreen(
                mainViewModel = mainViewModel,
                authViewModel = authViewModel,
                historyViewModel = historyViewModel,
                pointsViewModel = pointsViewModel,
                onNavigateToProductDetail = { productId ->
                    navController.navigate(Screen.ProductDetail.createRoute(productId))
                },
                onNavigateToCheckout = {
                    navController.navigate(Screen.Checkout.route)
                },
                onNavigateToOrderDetail = { orderId ->
                    navController.navigate(Screen.OrderDetail.createRoute(orderId))
                },
                onLogout = {
                    authViewModel.logout()
                    mainViewModel.reset()
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Main.route) { inclusive = true }
                    }
                }
            )
        }
        
        // Product detail (placeholder)
        composable(Screen.ProductDetail.route) { backStackEntry ->
            val productId = backStackEntry.arguments?.getString("productId")?.toIntOrNull() ?: 0
            ProductDetailScreen(
                productId = productId,
                viewModel = mainViewModel,
                firestoreClient = firestoreClient,
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Checkout screen
        composable(Screen.Checkout.route) {
            CheckoutScreen(
                mainViewModel = mainViewModel,
                authViewModel = authViewModel,
                pointsViewModel = pointsViewModel,
                onNavigateBack = { navController.popBackStack() },
                onOrderSuccess = { orderId ->
                    navController.navigate(Screen.OrderReceived.createRoute(orderId)) {
                        popUpTo(Screen.Main.route) { inclusive = false }
                    }
                }
            )
        }
        
        // Order detail (placeholder)
        composable(Screen.OrderDetail.route) { backStackEntry ->
            val orderId = backStackEntry.arguments?.getString("orderId")?.toIntOrNull()
            // TODO: Implement OrderDetailScreen
        }
        
        // Order received / success screen
        composable(Screen.OrderReceived.route) { backStackEntry ->
            val orderId = backStackEntry.arguments?.getString("orderId")?.toIntOrNull()
            OrderReceivedScreen(
                orderId = orderId,
                mainViewModel = mainViewModel,
                onDismiss = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Main.route) { inclusive = true }
                    }
                }
            )
        }
    }
}
