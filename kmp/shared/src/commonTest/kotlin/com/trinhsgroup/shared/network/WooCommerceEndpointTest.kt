package com.trinhsgroup.shared.network

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Parity tests for WooCommerceEndpoint.
 * Verifies URL paths match the Swift WooCommerceEndpoint enum exactly.
 */
class WooCommerceEndpointTest {

    @Test
    fun testAuthenticateEndpoint() {
        assertEquals("/wp-json/jwt-auth/v1/token", WooCommerceEndpoint.Authenticate.urlPath())
    }

    @Test
    fun testForgotPasswordEndpoint() {
        assertEquals("/wp-login.php?action=lostpassword", WooCommerceEndpoint.ForgotPassword.urlPath())
    }

    @Test
    fun testRegisterEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/register", WooCommerceEndpoint.Register.urlPath())
    }

    @Test
    fun testFetchCategoriesEndpoint() {
        assertEquals("/wp-json/wc/v3/products/categories", WooCommerceEndpoint.FetchCategories.urlPath())
    }

    @Test
    fun testFetchPopularProductsEndpoint() {
        assertEquals(
            "/wp-json/wc/v3/products?orderby=popularity&order=desc&per_page=10",
            WooCommerceEndpoint.FetchPopularProducts.urlPath()
        )
    }

    @Test
    fun testFetchProductsCategoryEndpoint() {
        assertEquals("/wp-json/wc/v3/products?category=5", WooCommerceEndpoint.FetchProductsCategory(5).urlPath())
        assertEquals("/wp-json/wc/v3/products?category=42", WooCommerceEndpoint.FetchProductsCategory(42).urlPath())
    }

    @Test
    fun testProductAddOnsEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/products/100/addons", WooCommerceEndpoint.ProductAddOns(100).urlPath())
    }

    @Test
    fun testMeEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/me", WooCommerceEndpoint.Me.urlPath())
    }

    @Test
    fun testMyOrdersEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/me/orders", WooCommerceEndpoint.MyOrders.urlPath())
    }

    @Test
    fun testOrderQuoteEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/me/orders/preview", WooCommerceEndpoint.OrderQuote.urlPath())
    }

    @Test
    fun testCancelMyOrderEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/me/orders/77/cancel", WooCommerceEndpoint.CancelMyOrder(77).urlPath())
    }

    @Test
    fun testMyOrderHistoryEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/me/orders/77/history", WooCommerceEndpoint.MyOrderHistory(77).urlPath())
    }

    @Test
    fun testMyPaymentIntentEndpoint() {
        assertEquals(
            "/wp-json/trinh-app/v1/me/orders/1234/payment-intent",
            WooCommerceEndpoint.MyPaymentIntent(1234).urlPath()
        )
    }

    @Test
    fun testMyVouchersEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/me/vouchers", WooCommerceEndpoint.MyVouchers.urlPath())
    }

    @Test
    fun testPaymentMethodsEndpoint() {
        assertEquals("/wp-json/trinh-app/v1/payment-methods", WooCommerceEndpoint.PaymentMethods.urlPath())
    }

    @Test
    fun testPointsEndpoints() {
        assertEquals("/wp-json/bu/v1/me/points", WooCommerceEndpoint.MyPoints.urlPath())
        assertEquals("/wp-json/bu/v1/redeem", WooCommerceEndpoint.RedeemPoints.urlPath())
    }

    @Test
    fun testFcmEndpoints() {
        assertEquals("/wp-json/trinh-app/v1/fcm/register", WooCommerceEndpoint.FcmRegister.urlPath())
        assertEquals("/wp-json/trinh-app/v1/fcm/unregister", WooCommerceEndpoint.FcmUnregister.urlPath())
    }

    @Test
    fun testCustomerAvatarEndpoint() {
        assertEquals("/wp-json/wc/v3/customers/9/avatar", WooCommerceEndpoint.CustomerAvatar(9).urlPath())
    }

    /**
     * The security property the /trinh-app/v1 migration exists for: no route that touches a
     * customer may be reachable with the shared read-only consumer key.
     */
    @Test
    fun `customer scoped routes require the user's JWT`() {
        listOf(
            WooCommerceEndpoint.Me,
            WooCommerceEndpoint.MyOrders,
            WooCommerceEndpoint.OrderQuote,
            WooCommerceEndpoint.CancelMyOrder(1),
            WooCommerceEndpoint.MyOrderHistory(1),
            WooCommerceEndpoint.MyPaymentIntent(1),
            WooCommerceEndpoint.MyVouchers,
            WooCommerceEndpoint.PaymentMethods,
            WooCommerceEndpoint.MyPoints,
            WooCommerceEndpoint.RedeemPoints,
            WooCommerceEndpoint.FcmRegister,
            WooCommerceEndpoint.FcmUnregister,
            WooCommerceEndpoint.CustomerAvatar(1)
        ).forEach { assertTrue(it.requiresJwt, "${it.urlPath()} must be JWT-scoped") }
    }

    /**
     * Verified against the live store: WordPress only understands a WooCommerce key on
     * /wc/v3. Sending it to a trinh-app route answers 401 invalid_username, which would
     * break signup and the add-on groups.
     */
    @Test
    fun `only wc-v3 catalog reads carry the consumer key`() {
        listOf(
            WooCommerceEndpoint.FetchCategories,
            WooCommerceEndpoint.FetchPopularProducts,
            WooCommerceEndpoint.FetchProductsCategory(1)
        ).forEach {
            assertEquals(EndpointAuth.CONSUMER_KEY, it.auth, "${it.urlPath()} needs the key")
            assertTrue(it.urlPath().startsWith(WooCommerceEndpoint.COMMON_URL))
        }

        listOf(
            WooCommerceEndpoint.Register,
            WooCommerceEndpoint.ProductAddOns(1),
            WooCommerceEndpoint.Authenticate,
            WooCommerceEndpoint.ForgotPassword
        ).forEach {
            assertEquals(EndpointAuth.NONE, it.auth, "${it.urlPath()} must send no credential")
        }
    }

    @Test
    fun `catalog and signup routes do not require a JWT`() {
        listOf(
            WooCommerceEndpoint.Authenticate,
            WooCommerceEndpoint.ForgotPassword,
            WooCommerceEndpoint.Register,
            WooCommerceEndpoint.FetchCategories,
            WooCommerceEndpoint.FetchPopularProducts,
            WooCommerceEndpoint.FetchProductsCategory(1),
            WooCommerceEndpoint.ProductAddOns(1)
        ).forEach { assertFalse(it.requiresJwt, "${it.urlPath()} must not need a session") }
    }

    /** No customer-scoped path may carry an id — the server reads it from the token. */
    @Test
    fun `customer scoped routes carry no customer id`() {
        listOf(
            WooCommerceEndpoint.Me,
            WooCommerceEndpoint.MyOrders,
            WooCommerceEndpoint.MyVouchers,
            WooCommerceEndpoint.MyPoints
        ).forEach {
            assertFalse(it.urlPath().contains("customer="), "${it.urlPath()} leaks a customer id")
            assertFalse(it.urlPath().contains("user_id="), "${it.urlPath()} leaks a user id")
        }
    }
}
