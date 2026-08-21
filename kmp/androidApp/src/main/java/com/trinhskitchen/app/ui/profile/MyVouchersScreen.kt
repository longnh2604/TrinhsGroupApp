package com.trinhskitchen.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.VoucherResponse
import com.trinhsgroup.shared.util.PriceFormatting
import com.trinhsgroup.shared.viewmodel.PointsViewModel

/** 1 point = $1, redeemable in tens — the same four options iOS offers. */
private val REDEEM_OPTIONS = listOf(10, 20, 50, 100)

/**
 * Points balance, redeem chips and the voucher wallet.
 * Mirrors iOS ProfileView's rewards card plus MyVouchersView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyVouchersScreen(
    pointsViewModel: PointsViewModel,
    onNavigateBack: () -> Unit
) {
    val balance by pointsViewModel.balance.collectAsState()
    val allVouchers by pointsViewModel.allVouchers.collectAsState()
    val isLoadingVouchers by pointsViewModel.isLoadingVouchers.collectAsState()
    val showRedeemSuccess by pointsViewModel.showRedeemSuccess.collectAsState()
    val showRedeemError by pointsViewModel.showRedeemError.collectAsState()
    val redeemResponse by pointsViewModel.lastRedeemResponse.collectAsState()
    val message by pointsViewModel.message.collectAsState()

    var pendingRedeem by remember { mutableStateOf<Int?>(null) }

    LaunchedEffect(Unit) {
        pointsViewModel.fetchPoints()
        pointsViewModel.fetchVouchers()
    }

    // A fresh voucher only shows up if the wallet is re-read.
    LaunchedEffect(showRedeemSuccess) {
        if (showRedeemSuccess) pointsViewModel.fetchVouchers()
    }

    val points = balance?.toInt() ?: 0
    val available = allVouchers.filter { it.status == "active" && !it.isExpired }
    val history = allVouchers.filterNot { it.status == "active" && !it.isExpired }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        TopAppBar(
            title = { Text(text = "My Vouchers", fontWeight = FontWeight.Bold) },
            navigationIcon = {
                IconButton(onClick = onNavigateBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back"
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Background,
                titleContentColor = AppColors.TextPrimary,
                navigationIconContentColor = AppColors.BarIcon,
                actionIconContentColor = AppColors.BarIcon
            )
        )

        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = AppColors.Primary),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "Reward Points",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                        Text(
                            text = "$points points",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "Redeem in tens — 10 points is a $10 voucher.",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                        Row(
                            modifier = Modifier.padding(top = 12.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            REDEEM_OPTIONS.forEach { option ->
                                AssistChip(
                                    onClick = { pendingRedeem = option },
                                    enabled = pointsViewModel.canRedeem(option),
                                    label = { Text("$$option") },
                                    colors = AssistChipDefaults.assistChipColors(
                                        containerColor = Color.White,
                                        labelColor = AppColors.Primary
                                    )
                                )
                            }
                        }
                    }
                }
            }

            if (isLoadingVouchers) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = AppColors.Primary)
                    }
                }
            }

            item { SectionTitle("Available (${available.size})") }

            if (available.isEmpty() && !isLoadingVouchers) {
                item {
                    Text(
                        text = "No vouchers yet. Redeem points to create one.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = AppColors.TextSecondary
                    )
                }
            }

            items(available, key = { it.id }) { voucher ->
                VoucherCard(voucher = voucher, isAvailable = true)
            }

            if (history.isNotEmpty()) {
                item { SectionTitle("History (${history.size})") }
                items(history, key = { it.id }) { voucher ->
                    VoucherCard(voucher = voucher, isAvailable = false)
                }
            }
        }
    }

    pendingRedeem?.let { option ->
        AlertDialog(
            onDismissRequest = { pendingRedeem = null },
            title = { Text("Redeem $option points?") },
            text = {
                Text("Redeem $option points for a $$option voucher.\n\nThis action cannot be undone.")
            },
            confirmButton = {
                TextButton(onClick = {
                    pointsViewModel.redeemPoints(option)
                    pendingRedeem = null
                }) { Text("Redeem") }
            },
            dismissButton = {
                TextButton(onClick = { pendingRedeem = null }) { Text("Cancel") }
            }
        )
    }

    if (showRedeemSuccess) {
        AlertDialog(
            onDismissRequest = { pointsViewModel.clearSuccess() },
            title = { Text("Voucher created") },
            text = {
                val response = redeemResponse
                Text(
                    if (response != null) {
                        "Your voucher code is:\n${response.couponCode}\n\n" +
                            "Value: ${PriceFormatting.getPriceAndCurrencySymbol(response.amount)}\n" +
                            "Remaining points: ${response.balance.toInt()}"
                    } else {
                        "Your voucher has been created successfully."
                    }
                )
            },
            confirmButton = {
                TextButton(onClick = { pointsViewModel.clearSuccess() }) { Text("OK") }
            }
        )
    }

    if (showRedeemError) {
        AlertDialog(
            onDismissRequest = { pointsViewModel.clearError() },
            title = { Text("Error") },
            text = { Text(message) },
            confirmButton = {
                TextButton(onClick = { pointsViewModel.clearError() }) { Text("OK") }
            }
        )
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold,
        color = AppColors.TextPrimary
    )
}

@Composable
private fun VoucherCard(voucher: VoucherResponse, isAvailable: Boolean) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "${PriceFormatting.getPriceAndCurrencySymbol(voucher.amount)} off",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isAvailable) AppColors.Primary else AppColors.TextSecondary
                )
                Text(
                    text = voucher.code.uppercase(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppColors.TextSecondary
                )
                Text(
                    text = if (isAvailable) {
                        "Valid until ${voucher.formattedExpiryDate}"
                    } else if (voucher.isExpired) {
                        "Expired ${voucher.formattedExpiryDate}"
                    } else {
                        "Used"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextHint
                )
            }
        }
    }
}
