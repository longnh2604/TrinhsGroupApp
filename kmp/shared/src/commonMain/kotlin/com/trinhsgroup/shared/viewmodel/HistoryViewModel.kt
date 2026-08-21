package com.trinhsgroup.shared.viewmodel

import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.model.OrderTimelineEvent
import com.trinhsgroup.shared.service.HistoryService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

/**
 * Shared ViewModel for order history.
 * Mirrors Swift's HistoryViewModel class.
 *
 * Note: On Android, wrap this in an AndroidX ViewModel.
 * On iOS, use this directly with lifecycle management.
 */
class HistoryViewModel(
    private val service: HistoryService
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val _orders = MutableStateFlow<List<Order>>(emptyList())
    val orders: StateFlow<List<Order>> = _orders.asStateFlow()

    private val _showHistory = MutableStateFlow(false)
    val showHistory: StateFlow<Boolean> = _showHistory.asStateFlow()

    private val _showHistoryOrderDetail = MutableStateFlow(false)
    val showHistoryOrderDetail: StateFlow<Boolean> = _showHistoryOrderDetail.asStateFlow()

    private val _showLoading = MutableStateFlow(false)
    val showLoading: StateFlow<Boolean> = _showLoading.asStateFlow()

    private val _message = MutableStateFlow("")
    val message: StateFlow<String> = _message.asStateFlow()

    /** The order whose detail is open. */
    private val _selectedOrder = MutableStateFlow(Order.Default)
    val selectedOrder: StateFlow<Order> = _selectedOrder.asStateFlow()

    private val _isCancelling = MutableStateFlow(false)
    val isCancelling: StateFlow<Boolean> = _isCancelling.asStateFlow()

    /**
     * Timeline for the order on screen. Empty until the fetch lands, and stays empty if the
     * server has no history to give — the rail then falls back to the order's own dates.
     */
    private val _statusHistory = MutableStateFlow<List<OrderTimelineEvent>>(emptyList())
    val statusHistory: StateFlow<List<OrderTimelineEvent>> = _statusHistory.asStateFlow()

    /** Which order [statusHistory] belongs to, so a late response can be discarded. */
    private var statusHistoryOrderId: Int? = null

    /** Order asked for by id before it was in [orders] — resolved when the fetch lands. */
    private var pendingOrderId: Int? = null

    init {
        bindingData()
    }

    private fun bindingData() {
        service.isLoading.onEach { isLoading ->
            _showLoading.value = isLoading
        }.launchIn(scope)

        service.error.onEach { error ->
            _message.value = error
        }.launchIn(scope)

        service.isCancelling.onEach { _isCancelling.value = it }.launchIn(scope)

        service.statusHistory.onEach { result ->
            val (orderId, events) = result ?: return@onEach
            if (orderId != statusHistoryOrderId) return@onEach
            _statusHistory.value = events
        }.launchIn(scope)

        service.orders.onEach { orders ->
            // Keep the open detail in step so an already-visible screen re-renders the new
            // status rather than showing a stale one.
            val open = _selectedOrder.value
            if (open.id > 0) {
                orders.firstOrNull { it.id == open.id }?.let { _selectedOrder.value = it }
            }
            _orders.value = orders

            pendingOrderId?.let { wanted ->
                orders.firstOrNull { it.id == wanted }?.let {
                    pendingOrderId = null
                    openOrder(it)
                }
            }
        }.launchIn(scope)
    }

    /**
     * Fetches orders for a specific customer.
     * Mirrors Swift's fetchOrders(customerId:) method.
     */
    fun fetchOrders() {
        scope.launch {
            service.onFetchHistoryOrders()
        }
    }

    /**
     * Opens an order known only by id — a tapped push notification.
     *
     * Shows the cached order first when there is one, and re-fetches either way: a push means
     * the status changed on the server, so the cache could contradict the message just tapped.
     */
    fun openOrder(orderId: Int) {
        if (orderId <= 0) return
        val cached = _orders.value.firstOrNull { it.id == orderId }
        if (cached != null) openOrder(cached) else pendingOrderId = orderId
        fetchOrders()
    }

    /** Opens one order's detail and asks for its timeline. */
    fun openOrder(order: Order) {
        _selectedOrder.value = order
        _showHistoryOrderDetail.value = true
        loadStatusHistory(order.id)
    }

    /**
     * Loads the timeline for one order.
     *
     * Clears the previous one first: showing the last order's stamps against this order's
     * stages would be worse than showing none.
     */
    fun loadStatusHistory(orderId: Int) {
        if (orderId <= 0) return
        statusHistoryOrderId = orderId
        _statusHistory.value = emptyList()
        scope.launch {
            service.onFetchOrderStatusHistory(orderId)
        }
    }

    /** Cancels the order on screen, if the server still allows it. */
    fun cancelOrder(orderId: Int, completion: (Boolean) -> Unit = {}) {
        if (orderId <= 0) return
        _message.value = ""
        scope.launch {
            val updated = service.onCancelOrder(orderId)
            if (updated != null) {
                _selectedOrder.value = updated
                _message.value = "Order #${updated.number} has been cancelled."
                loadStatusHistory(updated.id)
            }
            completion(updated != null)
        }
    }

    // ============ Setters ============

    fun setShowHistory(show: Boolean) {
        _showHistory.value = show
    }

    fun setShowHistoryOrderDetail(show: Boolean) {
        _showHistoryOrderDetail.value = show
    }

    fun clearMessage() {
        _message.value = ""
    }
}
