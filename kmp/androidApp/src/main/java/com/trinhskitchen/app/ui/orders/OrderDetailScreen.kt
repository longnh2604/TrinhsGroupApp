package com.trinhskitchen.app.ui.orders

import androidx.compose.foundation.background
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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
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
import com.trinhsgroup.shared.model.LineItem
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.order.OrderProgressBuilder
import com.trinhsgroup.shared.order.OrderStatusPresentation
import com.trinhsgroup.shared.order.OrderStep
import com.trinhsgroup.shared.order.OrderStepState
import com.trinhsgroup.shared.util.DateTimeUtils
import com.trinhsgroup.shared.util.PriceFormatting
import com.trinhsgroup.shared.viewmodel.HistoryViewModel

/**
 * One order: where it is, what is in it, what it cost.
 * Mirrors Swift's HistoryOrderDetailView plus OrderProgressCard.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderDetailScreen(
    historyViewModel: HistoryViewModel,
    onNavigateBack: () -> Unit
) {
    val order by historyViewModel.selectedOrder.collectAsState()
    val timeline by historyViewModel.statusHistory.collectAsState()
    val isCancelling by historyViewModel.isCancelling.collectAsState()
    val message by historyViewModel.message.collectAsState()

    var showCancelConfirm by remember { mutableStateOf(false) }

    LaunchedEffect(order.id) { historyViewModel.loadStatusHistory(order.id) }

    val presentation = OrderStatusPresentation.of(order.status)
    // The server's timeline when it has one; the order's own dates when it doesn't, so the rail
    // always says something rather than standing empty.
    val events = timeline.ifEmpty { OrderProgressBuilder.fallbackEvents(order) }
    val steps = OrderProgressBuilder.steps(order.status, events)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        TopAppBar(
            title = { Text("Order #${order.number}", fontWeight = FontWeight.Bold) },
            navigationIcon = {
                IconButton(onClick = onNavigateBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Primary,
                titleContentColor = Color.White,
                navigationIconContentColor = Color.White
            )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            StatusHero(presentation = presentation, placedAt = order.dateCreated)

            DetailCard(title = "Progress") {
                steps.forEachIndexed { index, step ->
                    ProgressRow(step = step, isLast = index == steps.lastIndex)
                }
            }

            DetailCard(title = "Items") {
                order.lineItems.forEach { item -> ItemRow(item) }
            }

            DetailCard(title = "Payment") {
                SummaryRow("Subtotal", PriceFormatting.getPriceAndCurrencySymbol(order.subtotal))

                if (order.discount > 0) {
                    SummaryRow(
                        label = "Discount",
                        value = "-" + PriceFormatting.getPriceAndCurrencySymbol(order.discount),
                        valueColor = AppColors.Success
                    )
                }

                // Fee lines carry the server's own label — the cash-on-pickup discount arrives
                // here as a negative fee, and older orders still carry the withdrawn app 5%.
                order.fees.forEach { fee ->
                    val isDiscount = fee.amount < 0
                    SummaryRow(
                        label = fee.name.ifEmpty { "Fee" },
                        value = (if (isDiscount) "-" else "") +
                            PriceFormatting.getPriceAndCurrencySymbol(kotlin.math.abs(fee.amount)),
                        valueColor = if (isDiscount) AppColors.Success else AppColors.TextPrimary
                    )
                }

                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                SummaryRow(
                    label = "Total",
                    value = PriceFormatting.getPriceAndCurrencySymbol(order.total.toDoubleOrNull() ?: 0.0),
                    bold = true
                )

                if (order.paymentMethodTitle.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "Paid by ${order.paymentMethodTitle}",
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }
            }

            if (order.customerNote.isNotBlank()) {
                DetailCard(title = "Note") {
                    Text(
                        text = order.customerNote,
                        style = MaterialTheme.typography.bodyMedium,
                        color = AppColors.TextPrimary
                    )
                }
            }

            if (message.isNotEmpty()) {
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.Primary
                )
            }

            // Only offered while the order could still plausibly be cancelled; the server has
            // the final say and its refusal is shown as the message above.
            if (!presentation.isTerminal && order.status != "completed") {
                OutlinedButton(
                    onClick = { showCancelConfirm = true },
                    enabled = !isCancelling,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    if (isCancelling) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            color = AppColors.Primary
                        )
                    } else {
                        Text("Cancel this order", color = AppColors.Primary)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    if (showCancelConfirm) {
        AlertDialog(
            onDismissRequest = { showCancelConfirm = false },
            title = { Text("Cancel order?") },
            text = { Text("Order #${order.number} will be cancelled. This can't be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    showCancelConfirm = false
                    historyViewModel.cancelOrder(order.id)
                }) { Text("Cancel order", color = AppColors.Primary) }
            },
            dismissButton = {
                TextButton(onClick = { showCancelConfirm = false }) { Text("Keep it") }
            }
        )
    }
}

@Composable
private fun StatusHero(presentation: OrderStatusPresentation, placedAt: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = presentation.tint.color.copy(alpha = 0.12f)),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = presentation.icon.vector,
                contentDescription = null,
                tint = presentation.tint.color,
                modifier = Modifier.size(34.dp)
            )
            Spacer(modifier = Modifier.width(14.dp))
            Column {
                Text(
                    text = presentation.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary
                )
                if (presentation.subtitle.isNotEmpty()) {
                    Text(
                        text = presentation.subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }
                if (placedAt.isNotEmpty()) {
                    Text(
                        text = "Placed ${DateTimeUtils.toDisplayDate(placedAt)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun ProgressRow(step: OrderStep, isLast: Boolean) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Surface(
                shape = CircleShape,
                color = when (step.state) {
                    OrderStepState.UPCOMING -> AppColors.SurfaceVariant
                    else -> step.tint.color
                }
            ) {
                Icon(
                    imageVector = step.icon.vector,
                    contentDescription = null,
                    tint = if (step.state == OrderStepState.UPCOMING) AppColors.TextHint else Color.White,
                    modifier = Modifier
                        .padding(7.dp)
                        .size(18.dp)
                )
            }
            if (!isLast) {
                Box(
                    modifier = Modifier
                        .width(2.dp)
                        .height(28.dp)
                        .background(
                            if (step.state == OrderStepState.DONE) step.tint.color
                            else AppColors.Divider
                        )
                )
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.padding(top = 4.dp)) {
            Text(
                text = step.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (step.state == OrderStepState.CURRENT) FontWeight.Bold else FontWeight.Normal,
                color = if (step.state == OrderStepState.UPCOMING) AppColors.TextHint else AppColors.TextPrimary
            )
            step.timestamp?.let { stamp ->
                Text(
                    text = stamp,
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextSecondary
                )
            }
        }
    }
}

@Composable
private fun ItemRow(item: LineItem) {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "${item.quantity} × ${item.name}",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextPrimary,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = PriceFormatting.getPriceAndCurrencySymbol(item.total.toDoubleOrNull() ?: 0.0),
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextPrimary
            )
        }

        // What the customer chose, grouped the way the server listed it.
        item.addOnLabels.forEach { label ->
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.TextSecondary
            )
        }

        item.note?.let { note ->
            Text(
                text = "\"$note\"",
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.TextSecondary
            )
        }
    }
}

@Composable
private fun DetailCard(title: String, content: @Composable () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            content()
        }
    }
}

@Composable
private fun SummaryRow(
    label: String,
    value: String,
    bold: Boolean = false,
    valueColor: Color = AppColors.TextPrimary
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            color = if (bold) AppColors.TextPrimary else AppColors.TextSecondary
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            color = valueColor
        )
    }
}
