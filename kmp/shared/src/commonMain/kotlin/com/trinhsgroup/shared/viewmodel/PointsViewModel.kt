package com.trinhsgroup.shared.viewmodel

import com.trinhsgroup.shared.model.RedeemResponse
import com.trinhsgroup.shared.model.VoucherResponse
import com.trinhsgroup.shared.service.PointsService
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
 * Shared ViewModel for points management.
 * Mirrors Swift's PointsViewModel class.
 *
 * Note: On Android, wrap this in an AndroidX ViewModel.
 * On iOS, use this directly with lifecycle management.
 */
class PointsViewModel(
    private val service: PointsService
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val _balance = MutableStateFlow<Double?>(null)
    val balance: StateFlow<Double?> = _balance.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _message = MutableStateFlow("")
    val message: StateFlow<String> = _message.asStateFlow()

    private val _lastRedeemResponse = MutableStateFlow<RedeemResponse?>(null)
    val lastRedeemResponse: StateFlow<RedeemResponse?> = _lastRedeemResponse.asStateFlow()

    private val _showRedeemSuccess = MutableStateFlow(false)
    val showRedeemSuccess: StateFlow<Boolean> = _showRedeemSuccess.asStateFlow()

    private val _showRedeemError = MutableStateFlow(false)
    val showRedeemError: StateFlow<Boolean> = _showRedeemError.asStateFlow()

    private val _availableVouchers = MutableStateFlow<List<VoucherResponse>>(emptyList())
    val availableVouchers: StateFlow<List<VoucherResponse>> = _availableVouchers.asStateFlow()

    private val _isLoadingVouchers = MutableStateFlow(false)
    val isLoadingVouchers: StateFlow<Boolean> = _isLoadingVouchers.asStateFlow()

    init {
        bindingData()
    }

    private fun bindingData() {
        service.isLoading.onEach { isLoading ->
            _isLoading.value = isLoading
        }.launchIn(scope)

        service.error.onEach { error ->
            _message.value = error
            if (error.isNotEmpty()) {
                _showRedeemError.value = true
            }
        }.launchIn(scope)

        service.points.onEach { points ->
            _balance.value = points?.balance
        }.launchIn(scope)

        service.redeemResponse.onEach { response ->
            if (response != null) {
                _lastRedeemResponse.value = response
                _balance.value = response.balance
                _showRedeemSuccess.value = true
            }
        }.launchIn(scope)

        service.vouchers.onEach { vouchers ->
            println("🎟️ PointsViewModel: service.vouchers emitted ${vouchers.size} vouchers")
            _availableVouchers.value = vouchers
            _isLoadingVouchers.value = false
            println("🎟️ PointsViewModel: Set isLoadingVouchers=false, availableVouchers=${vouchers.size}")
        }.launchIn(scope)
    }

    /**
     * Fetches the signed-in customer's points balance.
     * Mirrors Swift's fetchPoints() method. The account comes from the JWT.
     */
    fun fetchPoints() {
        scope.launch {
            service.fetchMyPoints()
        }
    }

    /**
     * Checks if user has enough points to redeem for a specific amount.
     * 1 point = $1, minimum 10 points to redeem.
     * Mirrors Swift's canRedeem(points:) method.
     */
    fun canRedeem(points: Int): Boolean {
        val currentBalance = _balance.value ?: return false
        return currentBalance.toInt() >= points && points >= 10 && points % 10 == 0
    }

    /**
     * Redeems points for a voucher.
     * Points must be >= 10 and divisible by 10.
     * Mirrors Swift's redeemPoints(points:) method.
     */
    fun redeemPoints(points: Int) {
        if (!canRedeem(points)) {
            val currentBalance = _balance.value
            if (currentBalance != null && currentBalance.toInt() < points) {
                _message.value = "Insufficient points. You need $points points but only have ${currentBalance.toInt()}."
            } else {
                _message.value = "Invalid points amount. Must be at least 10 points."
            }
            _showRedeemError.value = true
            return
        }

        // Clear previous state
        _message.value = ""
        _lastRedeemResponse.value = null

        scope.launch {
            service.redeemPoints(pointsToRedeem = points)
        }
    }

    /**
     * Resets error state.
     * Mirrors Swift's clearError() method.
     */
    fun clearError() {
        _message.value = ""
        _showRedeemError.value = false
    }

    /**
     * Resets success state.
     * Mirrors Swift's clearSuccess() method.
     */
    fun clearSuccess() {
        _showRedeemSuccess.value = false
    }

    /**
     * Fetches user's available vouchers.
     * Mirrors Swift's fetchVouchers() method. The account comes from the JWT.
     */
    fun fetchVouchers() {
        _isLoadingVouchers.value = true
        scope.launch {
            service.fetchVouchers()
        }
    }
}
