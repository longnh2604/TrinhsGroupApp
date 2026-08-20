package com.trinhskitchen.app.ui.checkout

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.Payment
import com.trinhsgroup.shared.model.toProductOrders
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.platform.LocalContext
import com.trinhskitchen.app.payments.PaymentResult
import com.trinhskitchen.app.payments.StripePresenter
import com.trinhsgroup.shared.model.FeeLine
import com.trinhsgroup.shared.payments.StripeRepository
import kotlinx.coroutines.launch
import org.koin.compose.koinInject
import com.trinhsgroup.shared.model.OrderQuote
import com.trinhsgroup.shared.model.VoucherResponse
import com.trinhsgroup.shared.util.PriceFormatting
import com.trinhsgroup.shared.viewmodel.AuthViewModel
import com.trinhsgroup.shared.viewmodel.MainViewModel
import com.trinhsgroup.shared.viewmodel.PointsViewModel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Checkout screen.
 * Mirrors iOS CheckOutView.swift.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckoutScreen(
    mainViewModel: MainViewModel,
    authViewModel: AuthViewModel,
    pointsViewModel: PointsViewModel,
    onNavigateBack: () -> Unit,
    onOrderSuccess: (Int) -> Unit,
    onSessionExpired: () -> Unit
) {
    val payments by mainViewModel.payments.collectAsState()
    val selectedPayment by mainViewModel.selectedPayment.collectAsState()
    val showLoading by mainViewModel.showLoading.collectAsState()
    val apiMessage by mainViewModel.message.collectAsState()
    val total = mainViewModel.total
    val user by authViewModel.user.collectAsState()
    val cartItems by mainViewModel.items.collectAsState()
    
    val vouchers by pointsViewModel.availableVouchers.collectAsState()
    val isLoadingVouchers by pointsViewModel.isLoadingVouchers.collectAsState()
    
    // Selected voucher state
    var selectedVoucher by remember { mutableStateOf<VoucherResponse?>(null) }
    
    // Pickup time state
    var selectedPickupTime by remember { mutableStateOf<TimeSlot?>(null) }
    var showTimePicker by remember { mutableStateOf(false) }
    
    // Error state
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // The server's price for this basket. Null until it answers, or if it could not be asked.
    var quote by remember { mutableStateOf<OrderQuote?>(null) }

    val context = LocalContext.current
    val stripePresenter: StripePresenter = koinInject()
    val stripeRepository: StripeRepository = koinInject()
    val scope = rememberCoroutineScope()
    val paymentResult by stripePresenter.paymentResult.collectAsState()
    val stripeError by stripePresenter.lastError.collectAsState()
    var isPaying by remember { mutableStateOf(false) }

    // The order the sheet is collecting payment for. Kept so the result handler knows which
    // order to finish, and so a cancelled payment leaves it alone rather than losing it.
    var pendingStripeOrderId by remember { mutableStateOf<Int?>(null) }

    /**
     * Finishes a card order once Stripe reports the payment complete. The cart is cleared here
     * rather than at order creation: an abandoned payment must leave the basket intact.
     */
    fun finishOrder(orderId: Int) {
        selectedVoucher = null
        pointsViewModel.fetchVouchers()
        pointsViewModel.fetchPoints()
        mainViewModel.reset()
        onOrderSuccess(orderId)
    }

    LaunchedEffect(paymentResult) {
        val result = paymentResult ?: return@LaunchedEffect
        val orderId = pendingStripeOrderId
        isPaying = false

        when (result) {
            is PaymentResult.Completed -> {
                pendingStripeOrderId = null
                stripePresenter.clearResult()
                if (orderId != null) finishOrder(orderId)
            }
            is PaymentResult.Canceled -> {
                // The order stays pending, so the customer can try again without re-ordering.
                errorMessage = "Payment was cancelled. Your order is saved — try paying again."
                stripePresenter.clearResult()
            }
            is PaymentResult.Failed -> {
                errorMessage = "${result.message}. Your order is saved — try paying again."
                stripePresenter.clearResult()
            }
        }
    }
    
    // Debug log when checkout screen loads
    LaunchedEffect(Unit) {
        println("🛒 CheckoutScreen: Loaded with user.id=${user.id}, user.email=${user.email}")
        mainViewModel.onFetchPaymentMethods()
    }
    
    // The account comes from the JWT, so the vouchers can be asked for as soon as the
    // screen opens rather than waiting on the customer record to land.
    LaunchedEffect(Unit) {
        pointsViewModel.fetchVouchers()
    }
    
    // What the basket costs. Re-asked whenever the answer could change: add-ons are priced
    // by YITH and the cash-on-pickup discount is a gateway fee, so the basket alone is not
    // the whole question — the chosen payment method is part of it.
    LaunchedEffect(cartItems, selectedPayment?.id, selectedVoucher?.code) {
        if (cartItems.isEmpty() || selectedPayment == null) {
            quote = null
        } else {
            mainViewModel.onFetchOrderQuote(
                productOrders = cartItems.toProductOrders(),
                couponCode = selectedVoucher?.code
            ) { quote = it }
        }
    }

    // Filter enabled payments
    val enabledPayments = payments.filter { it.enabled }
    
    // Check if submit is enabled
    val isSubmitEnabled = enabledPayments.isNotEmpty() && 
                          selectedPayment != null && 
                          selectedPickupTime != null
    
    // Pricing, once the server's quote has answered. The local sum is only a fallback, and
    // only ever misses a discount — it never invents a charge.
    val subtotal = quote?.subtotalValue ?: total
    val voucherDiscount = quote?.discountValue ?: (selectedVoucher?.amount ?: 0.0)
    val finalTotal = quote?.totalValue ?: maxOf(0.0, total - (selectedVoucher?.amount ?: 0.0))
    
    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF9F9F9))
        ) {
            // Top bar
            TopAppBar(
                title = { Text("Checkout", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    titleContentColor = AppColors.TextPrimary
                )
            )
            
            // Scrollable content
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp)
            ) {
                // Payment Methods Section
                Text(
                    text = "Select Payment",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                enabledPayments.forEach { payment ->
                    PaymentMethodItem(
                        payment = payment,
                        isSelected = selectedPayment?.id == payment.id,
                        onSelect = { mainViewModel.setSelectedPayment(payment) }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Pickup Time Section
                PickupTimeSelector(
                    selectedTime = selectedPickupTime,
                    onShowPicker = { showTimePicker = true }
                )
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Voucher Selection Section
                VoucherSelector(
                    vouchers = vouchers,
                    selectedVoucher = selectedVoucher,
                    isLoading = isLoadingVouchers,
                    onSelectVoucher = { selectedVoucher = it }
                )
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Price Summary
                PriceSummary(
                    subtotal = subtotal,
                    voucherDiscount = voucherDiscount,
                    fees = quote?.fees.orEmpty(),
                    voucher = selectedVoucher,
                    total = finalTotal
                )
                
                // Whatever the server said about this basket — a rejected voucher, an
                // unsupported gateway — shown where the totals it disagrees with are.
                apiMessage.takeIf { it.isNotEmpty() }?.let { message ->
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = message,
                        color = Color.Red,
                        style = MaterialTheme.typography.bodySmall
                    )
                }

                // Error message
                errorMessage?.let { error ->
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = error,
                        color = Color.Red,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
            
            // Submit Button
            Button(
                onClick = {
                    errorMessage = null
                    
                    // An expired token would have the server reject the order; end the session
                    // here and send them to sign in, as iOS does at its submit button.
                    if (authViewModel.endSessionIfTokenExpired()) {
                        errorMessage = "Your session has expired. Please sign in again."
                        onSessionExpired()
                        return@Button
                    }

                    val currentUser = user
                    println("🛒 CheckoutScreen: Submit clicked, user.id=${currentUser.id}, user.email=${currentUser.email}")
                    
                    if (currentUser.id <= 0) {
                        println("🛒 CheckoutScreen: User ID is ${currentUser.id}, showing login error")
                        errorMessage = "Please login to continue"
                        return@Button
                    }
                    
                    val pickupTime = selectedPickupTime
                    if (pickupTime == null) {
                        errorMessage = "Please select a pickup time"
                        return@Button
                    }

                    // An order the kitchen cannot ring back is worse than one not placed, and
                    // the server rejects it anyway.
                    if (!currentUser.billing.checkFilledData()) {
                        errorMessage = "Please complete your billing details before ordering"
                        return@Button
                    }
                    
                    val productOrders = cartItems.toProductOrders()
                    
                    // Format pickup datetime
                    val pickupDateTime = formatPickupDateTime(pickupTime)
                    
                    // Debug logging
                    println("🛒 CheckoutScreen: Creating order...")
                    println("🛒 CheckoutScreen: User ID = ${currentUser.id}, Email = ${currentUser.email}")
                    println("🛒 CheckoutScreen: Payment = ${selectedPayment?.id}")
                    println("🛒 CheckoutScreen: Pickup = $pickupDateTime")
                    println("🛒 CheckoutScreen: Items = ${productOrders.size}")
                    
                    // Create order
                    mainViewModel.onCreateOrder(
                        user = currentUser,
                        productOrders = productOrders,
                        pickupDateTime = pickupDateTime,
                        couponCode = selectedVoucher?.code
                    ) { orderId, paymentUrl ->
                        if (orderId != null) {
                            println("✅ CheckoutScreen: Order created with ID = $orderId")

                            if (selectedPayment?.id?.lowercase() == "stripe") {
                                // The order exists but is unpaid: ask the server for its payment
                                // intent and hand that to the sheet. The cart survives until the
                                // payment actually completes.
                                pendingStripeOrderId = orderId
                                isPaying = true
                                scope.launch {
                                    val intent = stripeRepository.getPaymentIntent(orderId)
                                    val secret = intent?.paymentIntent
                                    val key = intent?.publishableKey

                                    if (intent != null && secret != null && key != null) {
                                        stripePresenter.presentPaymentSheet(
                                            paymentIntentClientSecret = secret,
                                            publishableKey = key,
                                            customerId = intent.customer,
                                            ephemeralKeySecret = intent.ephemeralKey
                                        )
                                    } else if (!paymentUrl.isNullOrEmpty()) {
                                        // Same fallback as iOS: pay on the web, and the
                                        // trinhsgroup://checkout deep link brings us back.
                                        isPaying = false
                                        context.startActivity(
                                            Intent(Intent.ACTION_VIEW, Uri.parse(paymentUrl))
                                        )
                                    } else {
                                        isPaying = false
                                        errorMessage = "Couldn't start the payment. Your order is saved — please contact us."
                                    }
                                }
                            } else {
                                finishOrder(orderId)
                            }
                        } else {
                            println("❌ CheckoutScreen: Order creation failed, apiMessage=$apiMessage")
                            // Show API error if available, otherwise generic message
                            errorMessage = if (apiMessage.isNotEmpty()) {
                                apiMessage
                            } else {
                                "Failed to create order. Please try again."
                            }
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
                    .height(50.dp),
                enabled = isSubmitEnabled && !showLoading && !isPaying,
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isSubmitEnabled) AppColors.Primary else Color.Gray,
                    disabledContainerColor = Color.Gray
                )
            ) {
                if (showLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = "Submit Order",
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }
        
        // Time picker dialog
        if (showTimePicker) {
            TimeSlotPickerDialog(
                availableSlots = getAvailableTimeSlotsForToday(),
                onSelectTime = { timeSlot ->
                    selectedPickupTime = timeSlot
                    showTimePicker = false
                },
                onDismiss = { showTimePicker = false }
            )
        }
        
        // Loading overlay
        if (showLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.3f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = AppColors.Primary)
            }
        }
    }
}

@Composable
private fun PaymentMethodItem(
    payment: Payment,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onSelect)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Radio-style selection circle
        Box(
            modifier = Modifier
                .size(35.dp)
                .clip(CircleShape)
                .background(if (isSelected) AppColors.Primary else Color.White)
                .border(2.dp, AppColors.Primary, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Text(
            text = payment.title,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
            color = AppColors.TextPrimary
        )
    }
}

@Composable
private fun PickupTimeSelector(
    selectedTime: TimeSlot?,
    onShowPicker: () -> Unit
) {
    Column {
        Text(
            text = "Pickup Time (Today Only)",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        // Today's date display
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(8.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "📅",
                    fontSize = 20.sp
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Today: ${formatTodayDate()}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppColors.TextPrimary
                )
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Time selection button
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onShowPicker),
            shape = RoundedCornerShape(8.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            border = if (selectedTime != null) 
                androidx.compose.foundation.BorderStroke(1.dp, AppColors.Primary) 
            else null
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "🕐",
                        fontSize = 20.sp
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = selectedTime?.displayText ?: "Select Pickup Time",
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (selectedTime != null) AppColors.TextPrimary else Color.Gray
                    )
                }
                Icon(
                    imageVector = Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    tint = Color.Gray
                )
            }
        }
    }
}

@Composable
private fun VoucherSelector(
    vouchers: List<VoucherResponse>,
    selectedVoucher: VoucherResponse?,
    isLoading: Boolean,
    onSelectVoucher: (VoucherResponse?) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    
    Column {
        Text(
            text = "Apply Voucher",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        Box {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = !isLoading && vouchers.isNotEmpty()) { expanded = true },
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = if (selectedVoucher != null)
                    androidx.compose.foundation.BorderStroke(1.dp, AppColors.Primary)
                else null
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    when {
                        isLoading -> {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Loading vouchers...", color = Color.Gray)
                        }
                        selectedVoucher != null -> {
                            Column {
                                Text(
                                    text = selectedVoucher.code,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium,
                                    color = AppColors.Primary
                                )
                                Text(
                                    text = "$${selectedVoucher.amount.toInt()} discount",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color(0xFF4CAF50)
                                )
                            }
                        }
                        vouchers.isEmpty() -> {
                            Text(
                                text = "No vouchers available",
                                color = Color.Gray
                            )
                        }
                        else -> {
                            Text(
                                text = "Select a voucher (optional)",
                                color = AppColors.TextPrimary
                            )
                        }
                    }
                    
                    if (vouchers.isNotEmpty() && !isLoading) {
                        Icon(
                            imageVector = if (expanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                            contentDescription = null,
                            tint = Color.Gray
                        )
                    }
                }
            }
            
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                modifier = Modifier.fillMaxWidth(0.9f)
            ) {
                // No voucher option
                DropdownMenuItem(
                    text = { Text("No voucher", color = Color.Gray) },
                    onClick = {
                        onSelectVoucher(null)
                        expanded = false
                    }
                )
                
                vouchers.forEach { voucher ->
                    DropdownMenuItem(
                        text = {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(voucher.code, fontWeight = FontWeight.Medium)
                                Text(
                                    "-$${voucher.amount.toInt()}",
                                    color = Color(0xFF4CAF50)
                                )
                            }
                        },
                        onClick = {
                            onSelectVoucher(voucher)
                            expanded = false
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun PriceSummary(
    subtotal: Double,
    voucherDiscount: Double,
    fees: List<FeeLine>,
    voucher: VoucherResponse?,
    total: Double
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        PriceRow(
            label = "Subtotal",
            value = PriceFormatting.getPriceAndCurrencySymbol(subtotal),
            labelColor = Color.Gray
        )
        
        if (voucherDiscount > 0) {
            Spacer(modifier = Modifier.height(6.dp))
            PriceRow(
                label = voucher?.let { "Voucher (${it.code})" } ?: "Discount",
                value = "-${PriceFormatting.getPriceAndCurrencySymbol(voucherDiscount)}",
                labelColor = Color(0xFF4CAF50),
                valueColor = Color(0xFF4CAF50)
            )
        }

        // Fee lines as the server labelled them — the cash-on-pickup discount arrives here
        // as a negative fee, so no rate is held in the app.
        fees.forEach { fee ->
            Spacer(modifier = Modifier.height(6.dp))
            val isDiscount = fee.amount < 0
            PriceRow(
                label = fee.name,
                value = (if (isDiscount) "-" else "") +
                    PriceFormatting.getPriceAndCurrencySymbol(kotlin.math.abs(fee.amount)),
                labelColor = if (isDiscount) Color(0xFF4CAF50) else Color.Gray,
                valueColor = if (isDiscount) Color(0xFF4CAF50) else Color.Unspecified
            )
        }
        
        Spacer(modifier = Modifier.height(12.dp))
        
        PriceRow(
            label = "Total:",
            value = PriceFormatting.getPriceAndCurrencySymbol(total),
            labelColor = Color.Gray,
            valueWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun PriceRow(
    label: String,
    value: String,
    labelColor: Color = AppColors.TextSecondary,
    valueColor: Color = AppColors.TextPrimary,
    valueWeight: FontWeight = FontWeight.Normal
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = labelColor
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = valueWeight,
            color = valueColor
        )
    }
}

@Composable
private fun TimeSlotPickerDialog(
    availableSlots: List<TimeSlot>,
    onSelectTime: (TimeSlot) -> Unit,
    onDismiss: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.5f))
            .clickable(onClick = onDismiss),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .clickable(enabled = false) { },
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Select Pickup Time",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                if (availableSlots.isEmpty()) {
                    Text(
                        text = "No available time slots for today",
                        color = Color.Gray
                    )
                } else {
                    Column(
                        modifier = Modifier.verticalScroll(rememberScrollState())
                    ) {
                        availableSlots.forEach { slot ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { onSelectTime(slot) }
                                    .padding(vertical = 12.dp, horizontal = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = slot.displayText,
                                    style = MaterialTheme.typography.bodyLarge
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Gray)
                ) {
                    Text("Cancel")
                }
            }
        }
    }
}

// Time slot data class
data class TimeSlot(
    val hour: Int,
    val minute: Int
) {
    val displayText: String
        get() {
            val hourStr = if (hour > 12) hour - 12 else hour
            val amPm = if (hour >= 12) "PM" else "AM"
            return String.format("%d:%02d %s", hourStr, minute, amPm)
        }
}

// Get available time slots for today (mirrors iOS logic)
private fun getAvailableTimeSlotsForToday(): List<TimeSlot> {
    val slots = mutableListOf<TimeSlot>()
    val australiaTimeZone = TimeZone.getTimeZone("Australia/Sydney")
    val calendar = Calendar.getInstance(australiaTimeZone)
    val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
    val currentMinute = calendar.get(Calendar.MINUTE)
    
    // Generate from 11:30 up to 20:30
    var hour = 11
    var minute = 30
    
    while (hour < 21) {
        // Skip 15:00-15:59 (closed period)
        if (hour != 15) {
            // Only add future time slots
            if (hour > currentHour || (hour == currentHour && minute > currentMinute)) {
                slots.add(TimeSlot(hour, minute))
            }
        }
        minute += 30
        if (minute >= 60) {
            minute = 0
            hour += 1
        }
    }
    
    return slots
}

// Format today's date
private fun formatTodayDate(): String {
    val australiaTimeZone = TimeZone.getTimeZone("Australia/Sydney")
    val dateFormat = SimpleDateFormat("EEEE, MMMM d, yyyy", Locale.getDefault())
    dateFormat.timeZone = australiaTimeZone
    return dateFormat.format(Date())
}

// Format pickup datetime for API
private fun formatPickupDateTime(timeSlot: TimeSlot): String {
    val australiaTimeZone = TimeZone.getTimeZone("Australia/Sydney")
    val calendar = Calendar.getInstance(australiaTimeZone)
    calendar.set(Calendar.HOUR_OF_DAY, timeSlot.hour)
    calendar.set(Calendar.MINUTE, timeSlot.minute)
    calendar.set(Calendar.SECOND, 0)
    
    val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
    dateFormat.timeZone = australiaTimeZone
    return dateFormat.format(calendar.time)
}
