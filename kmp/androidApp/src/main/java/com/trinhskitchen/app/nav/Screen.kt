package com.trinhskitchen.app.nav

/**
 * Navigation routes for the app.
 * Mirrors iOS navigation structure.
 */
sealed class Screen(val route: String) {
    // Auth flow
    data object Splash : Screen("splash")
    data object Onboard : Screen("onboard")
    data object Login : Screen("login")
    data object Signup : Screen("signup")
    data object ForgotPassword : Screen("forgot_password")
    
    // Main app (bottom tabs)
    data object Main : Screen("main")
    
    // Home tab destinations
    data object Home : Screen("home")
    data object Notifications : Screen("notifications")
    
    // Menu tab destinations
    data object Menu : Screen("menu")
    data object Category : Screen("category/{categoryId}") {
        fun createRoute(categoryId: Int) = "category/$categoryId"
    }
    
    // Cart tab
    data object Cart : Screen("cart")
    data object Checkout : Screen("checkout")
    data object OrderReceived : Screen("order_received/{orderId}") {
        fun createRoute(orderId: Int) = "order_received/$orderId"
    }
    
    // Profile tab destinations
    data object Profile : Screen("profile")
    data object EditProfile : Screen("edit_profile")
    data object EditAddress : Screen("edit_address")
    data object MyOrders : Screen("my_orders")
    data object OrderDetail : Screen("order_detail/{orderId}") {
        fun createRoute(orderId: Int) = "order_detail/$orderId"
    }
    data object RewardsCenter : Screen("rewards_center")
    data object Favorites : Screen("favorites")
    data object Settings : Screen("settings")
    
    // Product detail
    data object ProductDetail : Screen("product/{productId}") {
        fun createRoute(productId: Int) = "product/$productId"
    }
    
    // Voucher selection
    data object VoucherSelection : Screen("voucher_selection")
}

/**
 * Bottom navigation tab items.
 */
enum class BottomTab(val route: String, val title: String, val icon: String) {
    HOME("home", "Home", "home"),
    MENU("menu", "Menu", "restaurant_menu"),
    CART("cart", "Cart", "shopping_cart"),
    PROFILE("profile", "Profile", "person")
}
