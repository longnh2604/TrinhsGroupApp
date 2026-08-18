package com.trinhskitchen.app.ui.orders

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.order.OrderStatusPresentation
import com.trinhsgroup.shared.util.DateTimeUtils
import com.trinhsgroup.shared.util.PriceFormatting
import com.trinhsgroup.shared.viewmodel.HistoryViewModel

/**
 * Which slice of the customer's orders to show.
 *
 * Mirrors iOS MyOrdersView's filter: the Orders tab is today's business, and older orders are
 * reached from the profile, so the two never repeat an order between them.
 */
enum class OrdersFilter { TODAY_ONLY, PAST_ONLY }

/**
 * The customer's orders.
 * Mirrors Swift's MyOrdersView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyOrdersScreen(
    historyViewModel: HistoryViewModel,
    filter: OrdersFilter = OrdersFilter.TODAY_ONLY,
    onNavigateBack: (() -> Unit)? = null,
    onOpenOrder: (Order) -> Unit
) {
    val orders by historyViewModel.orders.collectAsState()
    val isLoading by historyViewModel.showLoading.collectAsState()

    LaunchedEffect(Unit) { historyViewModel.fetchOrders() }

    val shown = orders.filter { DateTimeUtils.isToday(it.dateCreated) == (filter == OrdersFilter.TODAY_ONLY) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        TopAppBar(
            title = {
                Text(
                    text = if (filter == OrdersFilter.TODAY_ONLY) "My Orders" else "Past Orders",
                    fontWeight = FontWeight.Bold
                )
            },
            navigationIcon = {
                onNavigateBack?.let {
                    IconButton(onClick = it) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Primary,
                titleContentColor = Color.White,
                navigationIconContentColor = Color.White
            )
        )

        PullToRefreshBox(
            isRefreshing = isLoading,
            onRefresh = { historyViewModel.fetchOrders() },
            modifier = Modifier.fillMaxSize()
        ) {
            if (shown.isEmpty()) {
                EmptyOrders(filter)
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(shown, key = { it.id }) { order ->
                        OrderRow(order = order, onClick = { onOpenOrder(order) })
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyOrders(filter: OrdersFilter) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = Icons.Filled.ReceiptLong,
                contentDescription = null,
                tint = AppColors.TextHint,
                modifier = Modifier.size(56.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = if (filter == OrdersFilter.TODAY_ONLY) "No orders today" else "No past orders",
                style = MaterialTheme.typography.titleMedium,
                color = AppColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Your orders will appear here once you've placed one.",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary
            )
        }
    }
}

@Composable
private fun OrderRow(order: Order, onClick: () -> Unit) {
    val presentation = OrderStatusPresentation.of(order.status)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = presentation.tint.color.copy(alpha = 0.15f)
            ) {
                Icon(
                    imageVector = presentation.icon.vector,
                    contentDescription = null,
                    tint = presentation.tint.color,
                    modifier = Modifier
                        .padding(8.dp)
                        .size(22.dp)
                )
            }

            Spacer(modifier = Modifier.size(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Order #${order.number}",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.TextPrimary
                )
                Text(
                    text = presentation.title,
                    style = MaterialTheme.typography.bodySmall,
                    color = presentation.tint.color
                )
                Text(
                    text = DateTimeUtils.toDisplayDate(order.dateCreated),
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextSecondary
                )
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = PriceFormatting.getPriceAndCurrencySymbol(order.total.toDoubleOrNull() ?: 0.0),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary
                )
                Text(
                    text = "${order.lineItems.sumOf { it.quantity }} item(s)",
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextSecondary
                )
            }
        }
    }
}
