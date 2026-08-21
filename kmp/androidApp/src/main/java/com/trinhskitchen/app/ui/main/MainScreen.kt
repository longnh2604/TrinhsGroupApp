package com.trinhskitchen.app.ui.main

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.RestaurantMenu
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.ReceiptLong
import androidx.compose.material.icons.outlined.RestaurantMenu
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.trinhskitchen.app.nav.Screen
import com.trinhskitchen.app.ui.cart.CartScreen
import com.trinhskitchen.app.ui.favorites.FavoritesScreen
import com.trinhskitchen.app.ui.home.HomeScreen
import com.trinhskitchen.app.ui.menu.MenuScreen
import com.trinhskitchen.app.ui.orders.MyOrdersScreen
import com.trinhskitchen.app.ui.orders.OrdersFilter
import com.trinhskitchen.app.ui.profile.ProfileScreen
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.viewmodel.AuthViewModel
import com.trinhsgroup.shared.viewmodel.HistoryViewModel
import com.trinhsgroup.shared.viewmodel.MainViewModel
import com.trinhsgroup.shared.viewmodel.PointsViewModel

/**
 * Data class for bottom navigation items.
 */
data class BottomNavItem(
    val title: String,
    val route: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)

/**
 * Main app shell with bottom navigation.
 * Mirrors iOS MainView + CustomTabBar.
 */
@Composable
fun MainScreen(
    mainViewModel: MainViewModel,
    authViewModel: AuthViewModel,
    historyViewModel: HistoryViewModel,
    pointsViewModel: PointsViewModel,
    onNavigateToProductDetail: (Int) -> Unit,
    onNavigateToCheckout: () -> Unit,
    onNavigateToOrderDetail: (Int) -> Unit,
    onNavigateToNotifications: () -> Unit,
    onNavigateToEditProfile: () -> Unit,
    onNavigateToEditAddress: () -> Unit,
    onNavigateToPastOrders: () -> Unit,
    onNavigateToVouchers: () -> Unit,
    onLogout: () -> Unit,
    onAccountDeleted: () -> Unit,
    onRequireLogin: () -> Unit
) {
    val navController = rememberNavController()
    /** The cart is an overlay over the whole shell, not a tab — as on iOS. */
    var showCart by rememberSaveable { mutableStateOf(false) }

    var selectedTabIndex by rememberSaveable { mutableIntStateOf(0) }
    /** Tab a guest asked for before signing in, so the tap isn't lost behind the sign-in screen. */
    var pendingTabIndex by rememberSaveable { mutableStateOf<Int?>(null) }
    val isLogin by authViewModel.isLogin.collectAsState()
    
    // Initial bootstrapping - mirrors iOS MainView's .task block
    // Note: Session restoration (user data) happens in SplashScreen via restoreSession()
    // Here we only fetch app data (categories, products)
    LaunchedEffect(Unit) {
        mainViewModel.onFetchCategories()
        mainViewModel.onFetchPopularProducts()
    }
    
    val navItems = listOf(
        BottomNavItem(
            title = "Home",
            route = Screen.Home.route,
            selectedIcon = Icons.Filled.Home,
            unselectedIcon = Icons.Outlined.Home
        ),
        BottomNavItem(
            title = "Menu",
            route = Screen.Menu.route,
            selectedIcon = Icons.Filled.RestaurantMenu,
            unselectedIcon = Icons.Outlined.RestaurantMenu
        ),
        BottomNavItem(
            title = "Orders",
            route = Screen.MyOrders.route,
            selectedIcon = Icons.Filled.ReceiptLong,
            unselectedIcon = Icons.Outlined.ReceiptLong
        ),
        BottomNavItem(
            title = "Favorites",
            route = Screen.Favorites.route,
            selectedIcon = Icons.Filled.Favorite,
            unselectedIcon = Icons.Outlined.FavoriteBorder
        ),
        BottomNavItem(
            title = "Profile",
            route = Screen.Profile.route,
            selectedIcon = Icons.Filled.Person,
            unselectedIcon = Icons.Outlined.Person
        )
    )
    
    fun selectTab(index: Int) {
        selectedTabIndex = index
        navController.navigate(navItems[index].route) {
            popUpTo(navController.graph.startDestinationId) { saveState = true }
            launchSingleTop = true
            restoreState = true
        }
    }

    LaunchedEffect(isLogin) {
        if (isLogin) {
            pendingTabIndex?.let { requested ->
                selectTab(requested)
                pendingTabIndex = null
            }
        } else if (selectedTabIndex in ACCOUNT_TABS) {
            // Logged out, deleted, or the token expired while an account-only tab was up.
            selectTab(0)
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Scaffold(
            bottomBar = {
                NavigationBar(
                    containerColor = MaterialTheme.colorScheme.surface
                ) {
                    navItems.forEachIndexed { index, item ->
                        NavigationBarItem(
                            selected = selectedTabIndex == index,
                            onClick = {
                                if (index in ACCOUNT_TABS && !isLogin) {
                                    pendingTabIndex = index
                                    onRequireLogin()
                                } else {
                                    selectTab(index)
                                }
                            },
                            icon = {
                                Icon(
                                    imageVector = if (selectedTabIndex == index) item.selectedIcon else item.unselectedIcon,
                                    contentDescription = item.title
                                )
                            },
                            label = { Text(item.title) },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = AppColors.TabSelected,
                                selectedTextColor = AppColors.TabSelected,
                                unselectedIconColor = AppColors.TabUnselected,
                                unselectedTextColor = AppColors.TabUnselected,
                                indicatorColor = AppColors.Primary.copy(alpha = 0.1f)
                            )
                        )
                    }
                }
            }
        ) { paddingValues ->
            Box(modifier = Modifier.padding(paddingValues)) {
                NavHost(
                    navController = navController,
                    startDestination = Screen.Home.route
                ) {
                    composable(Screen.Home.route) {
                        HomeScreen(
                            viewModel = mainViewModel,
                            onNavigateToProductDetail = onNavigateToProductDetail,
                            onOpenCart = { showCart = true },
                            onNavigateToCategory = { categoryId ->
                                // Navigate to menu tab and select category
                                selectedTabIndex = 1
                                navController.navigate(Screen.Menu.route)
                            },
                            onNavigateToNotifications = onNavigateToNotifications
                        )
                    }
                
                    composable(Screen.Menu.route) {
                        MenuScreen(
                            viewModel = mainViewModel,
                            onNavigateToProductDetail = onNavigateToProductDetail,
                            onOpenCart = { showCart = true }
                        )
                    }

                    composable(Screen.Favorites.route) {
                        FavoritesScreen(
                            viewModel = mainViewModel,
                            onNavigateToProductDetail = onNavigateToProductDetail,
                            onOpenCart = { showCart = true }
                        )
                    }

                    composable(Screen.MyOrders.route) {
                        MyOrdersScreen(
                            historyViewModel = historyViewModel,
                            filter = OrdersFilter.TODAY_ONLY,
                            onOpenOrder = { order ->
                                historyViewModel.openOrder(order)
                                onNavigateToOrderDetail(order.id)
                            }
                        )
                    }

                    composable(Screen.Profile.route) {
                        ProfileScreen(
                            authViewModel = authViewModel,
                            historyViewModel = historyViewModel,
                            pointsViewModel = pointsViewModel,
                            mainViewModel = mainViewModel,
                            onNavigateToOrderDetail = onNavigateToOrderDetail,
                            onNavigateToEditProfile = onNavigateToEditProfile,
                            onNavigateToEditAddress = onNavigateToEditAddress,
                            onNavigateToPastOrders = onNavigateToPastOrders,
                            onNavigateToVouchers = onNavigateToVouchers,
                            onNavigateToFavorites = { selectTab(3) },
                            onLogout = onLogout,
                            onAccountDeleted = onAccountDeleted
                        )
                    }
                }
            }
        }

        // Cart overlays the whole shell, tab bar included — iOS presents it the same way.
        if (showCart) {
            BackHandler { showCart = false }
            Surface(modifier = Modifier.fillMaxSize()) {
                CartScreen(
                    viewModel = mainViewModel,
                    onClose = { showCart = false },
                    onNavigateToCheckout = {
                        // Placing an order is the account-based part; browsing and
                        // filling the basket are not.
                        showCart = false
                        if (isLogin) onNavigateToCheckout() else onRequireLogin()
                    },
                    onNavigateToProductDetail = { productId ->
                        showCart = false
                        onNavigateToProductDetail(productId)
                    }
                )
            }
        }
    }
}

/** Orders and Profile are about the customer rather than the menu. */
private val ACCOUNT_TABS = setOf(2, 4)
