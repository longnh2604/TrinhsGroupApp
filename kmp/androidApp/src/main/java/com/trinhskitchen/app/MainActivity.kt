package com.trinhskitchen.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.navigation.compose.rememberNavController
import com.trinhskitchen.app.nav.AppNavGraph
import com.trinhskitchen.app.nav.Screen
import com.trinhskitchen.app.firebase.PushMessagingService
import com.trinhskitchen.app.firebase.syncTrayNotifications
import com.trinhskitchen.app.payments.StripePresenter
import com.trinhskitchen.app.ui.theme.TrinhsGroupTheme
import com.trinhsgroup.shared.storage.NotificationStore
import org.koin.android.ext.android.inject

class MainActivity : ComponentActivity() {
    
    private val stripePresenter: StripePresenter by inject()
    private val notificationStore: NotificationStore by inject()

    /** Order a tapped push wants opened; the nav graph consumes it once the shell is up. */
    private val pushOrderId = mutableStateOf<Int?>(null)

    /** Order a `trinhsgroup://checkout` return wants shown. */
    private val deepLinkOrderId = mutableStateOf<Int?>(null)

    private val notificationPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Stripe PaymentSheet
        stripePresenter.initialize(this)
        
        askForNotificationPermission()
        readIntent(intent)
        
        setContent {
            TrinhsGroupTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    val navController = rememberNavController()
                    
                    AppNavGraph(
                        navController = navController,
                        pushOrderId = pushOrderId.value,
                        onPushOrderConsumed = { pushOrderId.value = null }
                    )
                    
                    // A checkout return, whether the activity was started by it or handed it
                    // while already running.
                    LaunchedEffect(deepLinkOrderId.value) {
                        val orderId = deepLinkOrderId.value ?: return@LaunchedEffect
                        navController.navigate(Screen.OrderReceived.createRoute(orderId)) {
                            popUpTo(Screen.Main.route) { inclusive = false }
                        }
                        deepLinkOrderId.value = null
                    }
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        readIntent(intent)
    }

    /**
     * Picks up whatever an incoming intent asks for. The activity is `singleTop`, so a
     * notification tap or a checkout return arrives here rather than rebuilding the screen.
     */
    private fun readIntent(intent: Intent) {
        pushOrderIdFrom(intent)?.let { pushOrderId.value = it }
        handleDeepLink(intent)?.let { deepLinkOrderId.value = it }
    }

    override fun onStart() {
        super.onStart()
        // Pushes the system showed while the app was away are only in the tray, not in the store.
        syncTrayNotifications(this, notificationStore)
    }

    /**
     * The order id a tapped push carried. Sent as a string by `trinh-push-notify`, and absent
     * for pushes that are not about an order.
     */
    private fun pushOrderIdFrom(intent: Intent): Int? =
        intent.getStringExtra(PushMessagingService.KEY_ORDER_ID)?.toIntOrNull()

    private fun askForNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
        if (granted != PackageManager.PERMISSION_GRANTED) {
            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }
    
    /**
     * Parses deep link from intent.
     * Handles trinhsgroup://checkout?order_id=123&status=completed
     *
     * @return Order ID if link indicates successful order, null otherwise
     */
    private fun handleDeepLink(intent: Intent): Int? {
        val data = intent.data ?: return null
        
        if (data.scheme == "trinhsgroup" && data.host == "checkout") {
            val orderId = data.getQueryParameter("order_id")?.toIntOrNull()
            val status = data.getQueryParameter("status")
            
            // Only handle successful order statuses
            if (orderId != null && status in listOf("completed", "processing", "success")) {
                return orderId
            }
        }
        
        return null
    }
}
