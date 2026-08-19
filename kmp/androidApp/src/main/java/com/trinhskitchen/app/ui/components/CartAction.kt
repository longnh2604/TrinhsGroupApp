package com.trinhskitchen.app.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.viewmodel.MainViewModel

/**
 * Cart button with an item-count badge, for a screen's top app bar.
 * Mirrors the bag button in iOS HomeNavigationBarView.
 */
@Composable
fun CartAction(
    viewModel: MainViewModel,
    onOpenCart: () -> Unit
) {
    val items by viewModel.items.collectAsState()
    val count = items.sumOf { it.quantity }

    IconButton(onClick = onOpenCart) {
        BadgedBox(
            badge = {
                if (count > 0) {
                    Badge(containerColor = AppColors.Badge) {
                        Text(
                            text = if (count > 99) "99+" else count.toString(),
                            color = AppColors.BadgeText
                        )
                    }
                }
            }
        ) {
            Icon(
                imageVector = Icons.Default.ShoppingCart,
                contentDescription = "Cart"
            )
        }
    }
}
