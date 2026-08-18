package com.trinhsgroup.shared.service

import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.model.OrderStatusHistory
import com.trinhsgroup.shared.model.OrderTimelineEvent
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

    private val _isCancelling = MutableStateFlow(false)
    val isCancelling: StateFlow<Boolean> = _isCancelling.asStateFlow()

    /**
     * Status timeline for the order last asked about, keyed by id so a late response for an
     * order the customer has already navigated away from can be discarded instead of
     * overwriting the rail.
     */
    private val _statusHistory = MutableStateFlow<Pair<Int, List<OrderTimelineEvent>>?>(null)
    val statusHistory: StateFlow<Pair<Int, List<OrderTimelineEvent>>?> = _statusHistory.asStateFlow()

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
     * Status timeline for one order.
     *
     * Deliberately routed through neither the loading nor the error flow: [isLoading] drives a
     * full-screen spinner, and this is a secondary fetch that decorates a screen already on
     * display. When it fails the rail falls back to the order's own dates.
     */
    suspend fun onFetchOrderStatusHistory(orderId: Int) {
        try {
            val history: OrderStatusHistory = api.request(
                endpoint = WooCommerceEndpoint.MyOrderHistory(orderId),
                method = HttpMethod.GET
            )
            _statusHistory.value = orderId to history.timelineEvents
        } catch (e: Exception) {
            println("📜 HistoryService.onFetchOrderStatusHistory($orderId): ${e.message}")
            _statusHistory.value = orderId to emptyList()
        }
    }

    /**
     * Cancels one of the signed-in customer's orders.
     * Mirrors Swift's onCancelOrder().
     *
     * The server decides whether a given status may still be cancelled, so a refusal here is
     * information for the customer, not a bug.
     *
     * @return the updated order, or null when the server refused
     */
    suspend fun onCancelOrder(orderId: Int): Order? {
        _isCancelling.value = true
        _error.value = ""

        return try {
            val updated: Order = api.request(
                endpoint = WooCommerceEndpoint.CancelMyOrder(orderId),
                method = HttpMethod.POST
            )
            // Keep the cached list in step so the row and the detail agree immediately.
            _orders.value = _orders.value.map { if (it.id == updated.id) updated else it }
            updated
        } catch (e: Exception) {
            _error.value = e.message ?: "Could not cancel this order"
            null
        } finally {
            _isCancelling.value = false
        }
    }

    /**
     * Clears the error state.
     */
    fun clearError() {
        _error.value = ""
    }
}
