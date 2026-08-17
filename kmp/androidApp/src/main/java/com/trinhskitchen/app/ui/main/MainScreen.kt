package com.trinhskitchen.app.ui.main

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.RestaurantMenu
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.RestaurantMenu
import androidx.compose.material.icons.outlined.ShoppingCart
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.trinhskitchen.app.nav.Screen
import com.trinhskitchen.app.ui.cart.CartScreen
import com.trinhskitchen.app.ui.home.HomeScreen
import com.trinhskitchen.app.ui.menu.MenuScreen
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
    val unselectedIcon: ImageVector,
    val hasBadge: Boolean = false,
    val badgeCount: Int = 0
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
    onLogout: () -> Unit
) {
    val navController = rememberNavController()
    val numberOfItems by mainViewModel.items.collectAsState()
    val cartCount = numberOfItems.sumOf { it.quantity }
    
    var selectedTabIndex by remember { mutableIntStateOf(0) }
    
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
            title = "Cart",
            route = Screen.Cart.route,
            selectedIcon = Icons.Filled.ShoppingCart,
            unselectedIcon = Icons.Outlined.ShoppingCart,
            hasBadge = cartCount > 0,
            badgeCount = cartCount
        ),
        BottomNavItem(
            title = "Profile",
            route = Screen.Profile.route,
            selectedIcon = Icons.Filled.Person,
            unselectedIcon = Icons.Outlined.Person
        )
    )
    
    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                navItems.forEachIndexed { index, item ->
                    NavigationBarItem(
                        selected = selectedTabIndex == index,
                        onClick = {
                            selectedTabIndex = index
                            navController.navigate(item.route) {
                                popUpTo(navController.graph.startDestinationId) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = {
                            BadgedBox(
                                badge = {
                                    if (item.hasBadge && item.badgeCount > 0) {
                                        Badge(
                                            containerColor = AppColors.Badge
                                        ) {
                                            Text(
                                                text = if (item.badgeCount > 99) "99+" else item.badgeCount.toString(),
                                                color = AppColors.BadgeText
                                            )
                                        }
                                    }
                                }
                            ) {
                                Icon(
                                    imageVector = if (selectedTabIndex == index) item.selectedIcon else item.unselectedIcon,
                                    contentDescription = item.title
                                )
                            }
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
                        onNavigateToCategory = { categoryId ->
                            // Navigate to menu tab and select category
                            selectedTabIndex = 1
                            navController.navigate(Screen.Menu.route)
                        }
                    )
                }
                
                composable(Screen.Menu.route) {
                    MenuScreen(
                        viewModel = mainViewModel,
                        onNavigateToProductDetail = onNavigateToProductDetail
                    )
                }
                
                composable(Screen.Cart.route) {
                    CartScreen(
                        viewModel = mainViewModel,
                        onNavigateToCheckout = onNavigateToCheckout,
                        onNavigateToProductDetail = onNavigateToProductDetail
                    )
                }
                
                composable(Screen.Profile.route) {
                    ProfileScreen(
                        authViewModel = authViewModel,
                        historyViewModel = historyViewModel,
                        pointsViewModel = pointsViewModel,
                        mainViewModel = mainViewModel,
                        onNavigateToOrderDetail = onNavigateToOrderDetail,
                        onLogout = onLogout
                    )
                }
            }
        }
    }
}
