package com.trinhskitchen.app.nav

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.trinhskitchen.app.ui.auth.ForgotPasswordScreen
import com.trinhskitchen.app.ui.auth.LoginScreen
import com.trinhskitchen.app.ui.auth.SignupScreen
import com.trinhskitchen.app.ui.auth.SplashScreen
import com.trinhskitchen.app.ui.checkout.CheckoutScreen
import com.trinhskitchen.app.ui.checkout.OrderReceivedScreen
import com.trinhskitchen.app.ui.main.MainScreen
import com.trinhskitchen.app.ui.orders.MyOrdersScreen
import com.trinhskitchen.app.ui.orders.OrderDetailScreen
import com.trinhskitchen.app.ui.orders.OrdersFilter
import com.trinhskitchen.app.ui.product.ProductDetailScreen
import com.trinhskitchen.app.ui.profile.EditAddressScreen
import com.trinhskitchen.app.ui.profile.EditProfileScreen
import com.trinhskitchen.app.ui.profile.MyVouchersScreen
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
                }
            )
        }
        
        // Login screen
        composable(Screen.Login.route) {
            LoginScreen(
                viewModel = authViewModel,
                onLoginSuccess = { navController.popBackStack() },
                onNavigateToSignup = {
                    navController.navigate(Screen.Signup.route)
                },
                onNavigateToForgotPassword = {
                    navController.navigate(Screen.ForgotPassword.route)
                },
                onClose = { navController.popBackStack() }
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
        
        composable(Screen.ForgotPassword.route) {
            ForgotPasswordScreen(
                authViewModel = authViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
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
                onNavigateToEditProfile = { navController.navigate(Screen.EditProfile.route) },
                onNavigateToEditAddress = { navController.navigate(Screen.EditAddress.route) },
                onNavigateToPastOrders = { navController.navigate(Screen.MyOrders.route) },
                onNavigateToVouchers = { navController.navigate(Screen.MyVouchers.route) },
                onLogout = {
                    authViewModel.logout()
                    mainViewModel.reset()
                    navController.navigate(Screen.Login.route)
                },
                // onDeleteAccount has already cleared the session by the time this runs.
                onAccountDeleted = {
                    mainViewModel.reset()
                    navController.navigate(Screen.Login.route)
                },
                onRequireLogin = {
                    navController.navigate(Screen.Login.route)
                }
            )
        }
        
        composable(Screen.EditProfile.route) {
            EditProfileScreen(
                authViewModel = authViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.EditAddress.route) {
            EditAddressScreen(
                authViewModel = authViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.MyVouchers.route) {
            MyVouchersScreen(
                pointsViewModel = pointsViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Product detail (placeholder)
        composable(Screen.ProductDetail.route) { backStackEntry ->
            val productId = backStackEntry.arguments?.getString("productId")?.toIntOrNull() ?: 0
            ProductDetailScreen(
                productId = productId,
                viewModel = mainViewModel,
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
                },
                onSessionExpired = { navController.navigate(Screen.Login.route) }
            )
        }
        
        // Order detail — the order to show is the one HistoryViewModel has open, so a push
        // notification and a tap from the list land on the same screen.
        composable(Screen.OrderDetail.route) {
            OrderDetailScreen(
                historyViewModel = historyViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Past orders, reached from the profile. Today's live in the Orders tab.
        composable(Screen.MyOrders.route) {
            MyOrdersScreen(
                historyViewModel = historyViewModel,
                filter = OrdersFilter.PAST_ONLY,
                onNavigateBack = { navController.popBackStack() },
                onOpenOrder = { order ->
                    historyViewModel.openOrder(order)
                    navController.navigate(Screen.OrderDetail.createRoute(order.id))
                }
            )
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
