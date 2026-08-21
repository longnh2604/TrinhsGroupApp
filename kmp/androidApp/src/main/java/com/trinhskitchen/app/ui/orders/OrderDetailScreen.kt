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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.order.OrderProgressBuilder
import com.trinhsgroup.shared.order.OrderStatusPresentation
import com.trinhsgroup.shared.order.OrderStep
import com.trinhsgroup.shared.order.OrderStepState
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
            OrderStatusHero(presentation = presentation, placedAt = order.dateCreated)

            OrderDetailCard(title = "Progress") {
                steps.forEachIndexed { index, step ->
                    ProgressRow(step = step, isLast = index == steps.lastIndex)
                }
            }

            OrderItemsCard(order)

            OrderPaymentSummaryCard(order)

            if (order.customerNote.isNotBlank()) {
                OrderDetailCard(title = "Note") {
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



