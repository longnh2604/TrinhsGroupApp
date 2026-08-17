package com.trinhsgroup.shared.viewmodel

import com.trinhsgroup.shared.model.Order
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

        service.orders.onEach { orders ->
            _orders.value = orders
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
