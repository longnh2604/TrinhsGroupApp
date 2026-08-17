package com.trinhskitchen.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.navigation.compose.rememberNavController
import com.trinhskitchen.app.nav.AppNavGraph
import com.trinhskitchen.app.nav.Screen
import com.trinhskitchen.app.payments.StripePresenter
import com.trinhskitchen.app.ui.theme.TrinhsGroupTheme
import org.koin.android.ext.android.inject

class MainActivity : ComponentActivity() {
    
    private val stripePresenter: StripePresenter by inject()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Stripe PaymentSheet
        stripePresenter.initialize(this)
        
        // Handle deep link from intent
        val deepLinkOrderId = handleDeepLink(intent)
        
        setContent {
            TrinhsGroupTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    val navController = rememberNavController()
                    
                    AppNavGraph(navController = navController)
                    
                    // Handle deep link navigation if present
                    deepLinkOrderId?.let { orderId ->
                        navController.navigate(Screen.OrderReceived.createRoute(orderId)) {
                            popUpTo(Screen.Main.route) { inclusive = false }
                        }
                    }
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
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
