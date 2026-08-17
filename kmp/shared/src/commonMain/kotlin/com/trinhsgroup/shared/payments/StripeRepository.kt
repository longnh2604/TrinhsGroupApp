package com.trinhsgroup.shared.payments

import com.trinhsgroup.shared.model.StripePaymentIntentResponse
import com.trinhsgroup.shared.network.HttpMethod
import com.trinhsgroup.shared.network.WooCommerceApi
import com.trinhsgroup.shared.network.WooCommerceEndpoint
import com.trinhsgroup.shared.network.request
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Repository for Stripe payment operations.
 * Handles fetching payment intent from WooCommerce.
 *
 * The actual PaymentSheet presentation is platform-specific (Android/iOS).
 * This repository only handles the shared network call.
 */
class StripeRepository(
    private val api: WooCommerceApi = WooCommerceApi()
) {
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _paymentIntent = MutableStateFlow<StripePaymentIntentResponse?>(null)
    val paymentIntent: StateFlow<StripePaymentIntentResponse?> = _paymentIntent.asStateFlow()

    /**
     * Fetches payment intent for an order from WooCommerce.
     * Mirrors iOS StripeManager.preparePaymentSheetFromOrder().
     *
     * @param orderId The WooCommerce order ID
     * @return StripePaymentIntentResponse if successful, null if failed or endpoint doesn't exist
     */
    suspend fun getPaymentIntent(orderId: Int): StripePaymentIntentResponse? {
        if (_isLoading.value) return null
        
        _isLoading.value = true
        _error.value = null

        return try {
            val response: StripePaymentIntentResponse = api.request(
                endpoint = WooCommerceEndpoint.MyPaymentIntent(orderId),
                method = HttpMethod.GET
            )
            
            if (response.isValid) {
                _paymentIntent.value = response
                response
            } else {
                _error.value = "Payment intent not found in response. Please try again or use another payment method."
                null
            }
        } catch (e: Exception) {
            // If endpoint doesn't exist (404), return null to trigger payment URL fallback
            // This matches iOS behavior
            _error.value = e.message
            null
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Clears the current payment intent state.
     */
    fun clearPaymentIntent() {
        _paymentIntent.value = null
        _error.value = null
    }
}
