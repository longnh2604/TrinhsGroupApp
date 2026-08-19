package com.trinhsgroup.shared.service

import com.trinhsgroup.shared.model.PointsResponse
import com.trinhsgroup.shared.model.RedeemResponse
import com.trinhsgroup.shared.model.VoucherResponse
import com.trinhsgroup.shared.model.WCCouponResponse
import com.trinhsgroup.shared.model.WooErrorResponse
import com.trinhsgroup.shared.network.HttpMethod
import com.trinhsgroup.shared.network.WooCommerceApi
import com.trinhsgroup.shared.network.WooCommerceEndpoint
import com.trinhsgroup.shared.network.request
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Service for managing customer points and vouchers.
 * Mirrors Swift's PointsServices class.
 */
class PointsService(
    private val api: WooCommerceApi = WooCommerceApi()
) {
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow("")
    val error: StateFlow<String> = _error.asStateFlow()

    private val _points = MutableStateFlow<PointsResponse?>(null)
    val points: StateFlow<PointsResponse?> = _points.asStateFlow()

    private val _redeemResponse = MutableStateFlow<RedeemResponse?>(null)
    val redeemResponse: StateFlow<RedeemResponse?> = _redeemResponse.asStateFlow()

    private val _vouchers = MutableStateFlow<List<VoucherResponse>>(emptyList())
    val vouchers: StateFlow<List<VoucherResponse>> = _vouchers.asStateFlow()

    /** Every voucher this account has redeemed, used and expired ones included. */
    private val _allVouchers = MutableStateFlow<List<VoucherResponse>>(emptyList())
    val allVouchers: StateFlow<List<VoucherResponse>> = _allVouchers.asStateFlow()

    /**
     * Fetches the signed-in customer's points balance.
     * Mirrors Swift's fetchMyPoints().
     *
     * Read from `bu/v1/me/points` rather than the customer record: WooCommerce's customers
     * controller only emits `meta_data` to administrators, so the balance is absent for the
     * customer themselves. The guard plugin fills user_id in from the JWT.
     */
    suspend fun fetchMyPoints() {
        _isLoading.value = true
        _error.value = ""
        println("🔵 Points API Request: fetching own balance")

        try {
            val response: PointsResponse = api.request(
                endpoint = WooCommerceEndpoint.MyPoints,
                method = HttpMethod.GET
            )
            _points.value = response
            println("✅ Points fetched successfully: ${response.balance}")
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch points"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Redeems points for a voucher using the custom myCred plugin API.
     * POST /wp-json/bu/v1/redeem
     * 1 point = $1, minimum 10 points to redeem.
     * Mirrors Swift's redeemPoints().
     *
     * @param pointsToRedeem Number of points to redeem (must be >= 10 and divisible by 10)
     */
    suspend fun redeemPoints(pointsToRedeem: Int) {
        if (pointsToRedeem < 10 || pointsToRedeem % 10 != 0) {
            _error.value = "Points must be at least 10 and in increments of 10"
            return
        }

        _isLoading.value = true
        _error.value = ""

        try {
            // user_id is deliberately omitted — trinh-api-guard (mu-plugin) forces it to the
            // JWT's own user, so points can only ever be redeemed from the caller's balance.
            val body = buildJsonObject {
                put("points", pointsToRedeem)
            }

            val redeemResult: RedeemResponse = api.request(
                endpoint = WooCommerceEndpoint.RedeemPoints,
                method = HttpMethod.POST,
                body = body
            )

            _redeemResponse.value = redeemResult
            
            // Update the local points balance
            _points.value = PointsResponse(
                userId = _points.value?.userId ?: 0,
                type = "mycred_default",
                balance = redeemResult.balance
            )
        } catch (e: WooErrorResponse) {
            _error.value = e.message
        } catch (e: Exception) {
            _error.value = parseRedeemError(e.message ?: "Unknown error")
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Fetches the signed-in customer's currently usable vouchers.
     * Mirrors Swift's fetchVouchers().
     *
     * GET /me/vouchers returns only this account's redeemed vouchers. The old path pulled
     * every coupon in the store and filtered by an "RW{userId}-" code prefix on the device,
     * which handed all store-wide promo codes to every customer.
     */
    suspend fun fetchVouchers() {
        _isLoading.value = true
        _error.value = ""

        try {
            val coupons: List<WCCouponResponse> = api.request(
                endpoint = WooCommerceEndpoint.MyVouchers,
                method = HttpMethod.GET
            )
            val all = coupons.map { it.toVoucherResponse() }
            // iOS asks twice for the same list; once is enough — the wallet screen wants
            // the history, checkout wants only what is still usable.
            _allVouchers.value = all.sortedByDescending { it.expirationDate }
            _vouchers.value = coupons.filter { it.isValid }.map { it.toVoucherResponse() }
            println("🎟️ PointsService.fetchVouchers: ${_vouchers.value.size} available, ${all.size} total")
        } catch (e: Exception) {
            println("🎟️ PointsService.fetchVouchers: ERROR - ${e::class.simpleName}: ${e.message}")
            _error.value = e.message ?: "Failed to fetch vouchers"
            _vouchers.value = emptyList()
            _allVouchers.value = emptyList()
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Parses redeem error messages into user-friendly text.
     * Mirrors Swift's parseRedeemError() exactly for UI parity.
     */
    private fun parseRedeemError(errorString: String): String {
        return when {
            errorString.contains("invalid_user_id") -> "Invalid user account"
            errorString.contains("invalid_points") -> "Invalid points amount"
            errorString.contains("points_not_allowed") -> "Points must be at least 10 and in increments of 10"
            errorString.contains("insufficient_points") -> "Insufficient points for this redemption"
            errorString.contains("coupon_create_failed") -> "Failed to create voucher. Please try again."
            errorString.contains("mycred_not_available") -> "Points system unavailable"
            errorString.contains("woocommerce_not_available") -> "Store system unavailable"
            else -> errorString
        }
    }

    /**
     * Clears the error state.
     */
    fun clearError() {
        _error.value = ""
    }

    /**
     * Clears the redeem response.
     */
    fun clearRedeemResponse() {
        _redeemResponse.value = null
    }
}
