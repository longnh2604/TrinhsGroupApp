package com.trinhsgroup.shared.network

/**
 * HTTP method enum mirroring Swift's HTTPMethod.
 */
enum class HttpMethod { GET, POST, PUT, DELETE }

/**
 * Which credential a route accepts.
 *
 * Three modes, because the server really does have three. WordPress only understands a
 * WooCommerce `ck_/cs_` pair on `/wc/v3`; send it to any other namespace and WP tries the
 * key as a *username* and answers 401 `invalid_username`. So the public `trinh-app` routes
 * — signup and the add-on groups — must be called with no Authorization header at all.
 */
enum class EndpointAuth {
    /** No Authorization header. Public `trinh-app` routes, login, password reset. */
    NONE,

    /** Read-only WooCommerce consumer key. Only `/wc/v3` catalog reads accept it. */
    CONSUMER_KEY,

    /** The signed-in user's JWT. Everything scoped to a customer. */
    JWT
}

/**
 * API endpoint definitions.
 * Mirrors Swift's WooCommerceEndpoint enum in Utility/WooCommerceOAuth.swift.
 *
 * Two namespaces: `/wc/v3` for the public catalog, read with the read-only consumer key,
 * and `/trinh-app/v1` for anything belonging to a customer, authorised by that customer's
 * JWT. Nothing customer-scoped takes an id in the URL — the server derives the account
 * from the token, so one signed-in user cannot ask for another's data.
 */
sealed class WooCommerceEndpoint {

    // Unauthenticated
    data object Authenticate : WooCommerceEndpoint()
    data object ForgotPassword : WooCommerceEndpoint()

    /** Server-side signup, so the app never needs a write-capable consumer key. */
    data object Register : WooCommerceEndpoint()

    // Public catalog — read-only consumer key
    data object FetchCategories : WooCommerceEndpoint()
    data object FetchPopularProducts : WooCommerceEndpoint()
    data class FetchProductsCategory(val categoryId: Int) : WooCommerceEndpoint()

    /** Add-on groups YITH offers for one product. Public, like the product page. */
    data class ProductAddOns(val productId: Int) : WooCommerceEndpoint()

    // Signed-in user — JWT, scoped server-side to the token's own account

    /** Own customer record: GET to read, PUT to update, DELETE to close the account. */
    data object Me : WooCommerceEndpoint()

    /** GET lists own orders, POST creates one. */
    data object MyOrders : WooCommerceEndpoint()

    /** What the basket costs, priced by the server. Creates nothing. */
    data object OrderQuote : WooCommerceEndpoint()
    data class CancelMyOrder(val orderId: Int) : WooCommerceEndpoint()

    /** Timestamped status timeline for one order. */
    data class MyOrderHistory(val orderId: Int) : WooCommerceEndpoint()
    data class MyPaymentIntent(val orderId: Int) : WooCommerceEndpoint()
    data object MyVouchers : WooCommerceEndpoint()
    data object PaymentMethods : WooCommerceEndpoint()

    /** Own myCred balance; the guard plugin fills user_id in from the JWT. */
    data object MyPoints : WooCommerceEndpoint()
    data object RedeemPoints : WooCommerceEndpoint()
    data object FcmRegister : WooCommerceEndpoint()
    data object FcmUnregister : WooCommerceEndpoint()
    data class CustomerAvatar(val customerId: Int) : WooCommerceEndpoint()

    fun urlPath(): String = when (this) {
        is Authenticate -> "/wp-json/jwt-auth/v1/token"
        is ForgotPassword -> "/wp-login.php?action=lostpassword"
        is Register -> "$APP_API_URL/register"

        is FetchCategories -> "$COMMON_URL/products/categories"
        is FetchPopularProducts -> "$COMMON_URL/products?orderby=popularity&order=desc&per_page=10"
        is FetchProductsCategory -> "$COMMON_URL/products?category=$categoryId"
        is ProductAddOns -> "$APP_API_URL/products/$productId/addons"

        is Me -> "$APP_API_URL/me"
        is MyOrders -> "$APP_API_URL/me/orders"
        is OrderQuote -> "$APP_API_URL/me/orders/preview"
        is CancelMyOrder -> "$APP_API_URL/me/orders/$orderId/cancel"
        is MyOrderHistory -> "$APP_API_URL/me/orders/$orderId/history"
        is MyPaymentIntent -> "$APP_API_URL/me/orders/$orderId/payment-intent"
        is MyVouchers -> "$APP_API_URL/me/vouchers"
        is PaymentMethods -> "$APP_API_URL/payment-methods"
        is MyPoints -> "/wp-json/bu/v1/me/points"
        is RedeemPoints -> "/wp-json/bu/v1/redeem"
        is FcmRegister -> "$APP_API_URL/fcm/register"
        is FcmUnregister -> "$APP_API_URL/fcm/unregister"
        is CustomerAvatar -> "$COMMON_URL/customers/$customerId/avatar"
    }

    /**
     * The credential this route accepts. Verified against the live store: the catalog needs
     * the consumer key, the public `trinh-app` routes reject it, and everything
     * customer-scoped needs the JWT.
     */
    val auth: EndpointAuth
        get() = when (this) {
            // Signup and the add-on groups live under trinh-app, which does not understand
            // a consumer key. Login and password reset post a form and carry no header.
            is Authenticate, is ForgotPassword, is Register, is ProductAddOns -> EndpointAuth.NONE

            is FetchCategories, is FetchPopularProducts,
            is FetchProductsCategory -> EndpointAuth.CONSUMER_KEY

            is Me, is MyOrders, is OrderQuote, is CancelMyOrder, is MyOrderHistory,
            is MyPaymentIntent, is MyVouchers, is PaymentMethods, is MyPoints,
            is RedeemPoints, is FcmRegister, is FcmUnregister,
            is CustomerAvatar -> EndpointAuth.JWT
        }

    /** Everything touching a customer is server-scoped to the token. */
    val requiresJwt: Boolean
        get() = auth == EndpointAuth.JWT

    companion object {
        const val COMMON_URL = "/wp-json/wc/v3"
        const val APP_API_URL = "/wp-json/trinh-app/v1"
    }
}
