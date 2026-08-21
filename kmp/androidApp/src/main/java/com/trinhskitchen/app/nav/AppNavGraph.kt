package com.trinhskitchen.app.nav

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import com.trinhskitchen.app.ui.auth.ForgotPasswordScreen
import com.trinhskitchen.app.ui.auth.LoginScreen
import com.trinhskitchen.app.ui.auth.SignupScreen
import com.trinhskitchen.app.ui.auth.SplashScreen
import com.trinhskitchen.app.ui.checkout.CheckoutScreen
import com.trinhskitchen.app.ui.checkout.OrderReceivedScreen
import com.trinhskitchen.app.firebase.PushTokens
import com.trinhskitchen.app.ui.main.MainScreen
import com.trinhskitchen.app.ui.notifications.NotificationsScreen
import com.trinhskitchen.app.ui.orders.MyOrdersScreen
import com.trinhskitchen.app.ui.orders.OrderDetailScreen
import com.trinhskitchen.app.ui.orders.OrdersFilter
import com.trinhskitchen.app.ui.product.ProductDetailScreen
import com.trinhskitchen.app.ui.profile.EditAddressScreen
import com.trinhskitchen.app.ui.profile.EditProfileScreen
import com.trinhskitchen.app.ui.profile.MyVouchersScreen
import com.trinhsgroup.shared.storage.NotificationStore
import com.trinhsgroup.shared.viewmodel.AuthViewModel
import com.trinhsgroup.shared.viewmodel.HistoryViewModel
import com.trinhsgroup.shared.viewmodel.MainViewModel
import com.trinhsgroup.shared.viewmodel.PointsViewModel
import kotlinx.coroutines.launch
import org.koin.compose.koinInject

/**
 * Main navigation graph for the app.
 */
@Composable
fun AppNavGraph(
    navController: NavHostController,
    pushOrderId: Int? = null,
    onPushOrderConsumed: () -> Unit = {}
) {
    val authViewModel: AuthViewModel = koinInject()
    val mainViewModel: MainViewModel = koinInject()
    val historyViewModel: HistoryViewModel = koinInject()
    val pointsViewModel: PointsViewModel = koinInject()
    val notificationStore: NotificationStore = koinInject()
    val pushTokens: PushTokens = koinInject()
    val scope = rememberCoroutineScope()

    // Tell the server where to send this account's order updates.
    val isLogin by authViewModel.isLogin.collectAsState()
    LaunchedEffect(isLogin) { if (isLogin) pushTokens.register() }

    // A push tapped in the tray. Held until the shell is up: on a cold launch the splash is
    // still on screen and would navigate over the order detail as soon as the session restores.
    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route
    LaunchedEffect(pushOrderId, currentRoute) {
        val orderId = pushOrderId ?: return@LaunchedEffect
        if (currentRoute != Screen.Main.route) return@LaunchedEffect
        historyViewModel.openOrder(orderId)
        navController.navigate(Screen.OrderDetail.createRoute(orderId))
        onPushOrderConsumed()
    }
    
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
                onNavigateToNotifications = {
                    navController.navigate(Screen.Notifications.route)
                },
                onNavigateToEditProfile = { navController.navigate(Screen.EditProfile.route) },
                onNavigateToEditAddress = { navController.navigate(Screen.EditAddress.route) },
                onNavigateToPastOrders = { navController.navigate(Screen.MyOrders.route) },
                onNavigateToVouchers = { navController.navigate(Screen.MyVouchers.route) },
                onLogout = {
                    scope.launch {
                        // Unbind this device before the JWT goes: afterwards the server has no
                        // way to tell which account's pushes to stop.
                        pushTokens.unregister()
                        authViewModel.logout()
                        mainViewModel.reset()
                        navController.navigate(Screen.Login.route)
                    }
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

        composable(Screen.Notifications.route) {
            NotificationsScreen(
                store = notificationStore,
                onOpenOrder = { orderId ->
                    historyViewModel.openOrder(orderId)
                    navController.navigate(Screen.OrderDetail.createRoute(orderId))
                },
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
