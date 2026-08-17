package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Response model for Stripe payment intent from WooCommerce.
 * Mirrors the iOS StripePaymentIntentResponse struct.
 *
 * Endpoint: /wp-json/wc/v3/orders/{orderId}/stripe/payment-intent
 */
@Serializable
data class StripePaymentIntentResponse(
    @SerialName("payment_intent") val paymentIntent: String? = null,
    val customer: String? = null,
    @SerialName("ephemeral_key") val ephemeralKey: String? = null,
    @SerialName("publishable_key") val publishableKey: String? = null
) {
    /**
     * Returns true if all required fields for payment sheet are present.
     */
    val isValid: Boolean
        get() = !paymentIntent.isNullOrEmpty() && !publishableKey.isNullOrEmpty()
}
