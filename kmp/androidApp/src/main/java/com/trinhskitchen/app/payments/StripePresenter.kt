package com.trinhskitchen.app.payments

import android.app.Activity
import android.content.Context
import com.stripe.android.PaymentConfiguration
import com.stripe.android.paymentsheet.PaymentSheet
import com.stripe.android.paymentsheet.PaymentSheetResult
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Android Stripe PaymentSheet presenter.
 * Handles presenting and configuring the Stripe PaymentSheet.
 * Mirrors iOS StripeManager behavior.
 */
class StripePresenter {
    
    private var paymentSheet: PaymentSheet? = null
    private var appContext: Context? = null
    
    private val _isPreparing = MutableStateFlow(false)
    val isPreparing: StateFlow<Boolean> = _isPreparing.asStateFlow()
    
    private val _paymentResult = MutableStateFlow<PaymentResult?>(null)
    val paymentResult: StateFlow<PaymentResult?> = _paymentResult.asStateFlow()
    
    private val _lastError = MutableStateFlow<String?>(null)
    val lastError: StateFlow<String?> = _lastError.asStateFlow()
    
    /**
     * Initializes the PaymentSheet with the activity.
     * Must be called in Activity.onCreate().
     */
    fun initialize(activity: Activity) {
        appContext = activity.applicationContext
        paymentSheet = PaymentSheet(activity as androidx.activity.ComponentActivity) { result ->
            handlePaymentResult(result)
        }
    }
    
    /**
     * Prepares and presents the PaymentSheet.
     *
     * @param paymentIntentClientSecret The payment intent client secret from WooCommerce
     * @param publishableKey Stripe publishable key
     * @param customerId Optional customer ID for saved payment methods
     * @param ephemeralKeySecret Optional ephemeral key for customer
     */
    fun presentPaymentSheet(
        paymentIntentClientSecret: String,
        publishableKey: String,
        customerId: String? = null,
        ephemeralKeySecret: String? = null
    ) {
        if (_isPreparing.value) {
            _lastError.value = "Payment sheet preparation already in progress"
            return
        }
        
        _isPreparing.value = true
        _lastError.value = null
        
        val context = appContext ?: run {
            _lastError.value = "StripePresenter not initialized"
            _isPreparing.value = false
            return
        }
        
        // Configure Stripe with publishable key
        PaymentConfiguration.init(context, publishableKey)
        
        // Build configuration
        val configuration = PaymentSheet.Configuration.Builder("TrinhsKitchen")
            .allowsDelayedPaymentMethods(true)
            .apply {
                if (customerId != null && ephemeralKeySecret != null) {
                    customer(
                        PaymentSheet.CustomerConfiguration(
                            id = customerId,
                            ephemeralKeySecret = ephemeralKeySecret
                        )
                    )
                }
            }
            .build()
        
        // Present payment sheet
        paymentSheet?.presentWithPaymentIntent(
            paymentIntentClientSecret = paymentIntentClientSecret,
            configuration = configuration
        )
        
        _isPreparing.value = false
    }
    
    private fun handlePaymentResult(result: PaymentSheetResult) {
        _paymentResult.value = when (result) {
            is PaymentSheetResult.Completed -> PaymentResult.Completed
            is PaymentSheetResult.Canceled -> PaymentResult.Canceled
            is PaymentSheetResult.Failed -> {
                _lastError.value = result.error.localizedMessage
                PaymentResult.Failed(result.error.localizedMessage ?: "Payment failed")
            }
        }
    }
    
    /**
     * Clears the payment result state.
     */
    fun clearResult() {
        _paymentResult.value = null
        _lastError.value = null
    }
}

/**
 * Sealed class for payment results.
 */
sealed class PaymentResult {
    data object Completed : PaymentResult()
    data object Canceled : PaymentResult()
    data class Failed(val message: String) : PaymentResult()
}
