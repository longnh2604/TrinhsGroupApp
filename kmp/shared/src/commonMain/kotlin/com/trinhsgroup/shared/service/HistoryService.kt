package com.trinhsgroup.shared.service

import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.network.HttpMethod
import com.trinhsgroup.shared.network.WooCommerceApi
import com.trinhsgroup.shared.network.WooCommerceEndpoint
import com.trinhsgroup.shared.network.request
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Service for fetching order history.
 * Mirrors Swift's HistoryServices class.
 */
class HistoryService(
    private val api: WooCommerceApi = WooCommerceApi()
) {
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow("")
    val error: StateFlow<String> = _error.asStateFlow()

    private val _orders = MutableStateFlow<List<Order>>(emptyList())
    val orders: StateFlow<List<Order>> = _orders.asStateFlow()

    /**
     * Orders for the signed-in customer.
     * Mirrors Swift's onFetchHistoryOrders().
     *
     * The server derives the customer from the JWT — the previous `?customer=<id>` query
     * could list any customer's order history.
     */
    suspend fun onFetchHistoryOrders() {
        _isLoading.value = true
        _error.value = ""

        try {
            val orderList: List<Order> = api.request(
                endpoint = WooCommerceEndpoint.MyOrders,
                method = HttpMethod.GET
            )
            _orders.value = orderList
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch orders"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Clears the error state.
     */
    fun clearError() {
        _error.value = ""
    }
}
