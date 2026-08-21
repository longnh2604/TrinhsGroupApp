package com.trinhskitchen.app.ui.components

import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.storage.NotificationStore
import org.koin.compose.koinInject

/**
 * The bar every tab wears: the screen's own name in the middle, dark on a near-white ground.
 * Mirrors iOS HomeNavigationBarView.
 *
 * Light rather than brand red on purpose — the bell and bag counts are red, and red on red is
 * a badge nobody can read.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppTopBar(
    title: String,
    navigationIcon: @Composable () -> Unit = { BarIconSpacer() },
    actions: @Composable RowScope.() -> Unit = {}
) {
    CenterAlignedTopAppBar(
        title = { Text(text = title, fontWeight = FontWeight.SemiBold) },
        navigationIcon = navigationIcon,
        actions = actions,
        colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
            containerColor = AppColors.Background,
            titleContentColor = AppColors.TextPrimary,
            navigationIconContentColor = AppColors.BarIcon,
            actionIconContentColor = AppColors.BarIcon
        )
    )
}

/** The bell, with the count of pushes not yet read. Left of the title, as on iOS. */
@Composable
fun NotificationBell(onClick: () -> Unit) {
    val store: NotificationStore = koinInject()
    val notifications by store.notifications.collectAsState()
    val unread = notifications.count { !it.isRead }

    IconButton(onClick = onClick) {
        BadgedBox(
            badge = {
                if (unread > 0) {
                    Badge(containerColor = AppColors.Badge) {
                        Text(
                            text = if (unread > 99) "99+" else unread.toString(),
                            color = AppColors.BadgeText
                        )
                    }
                }
            }
        ) {
            Icon(
                imageVector = Icons.Outlined.Notifications,
                contentDescription = "Notifications"
            )
        }
    }
}

/** Keeps the title centred on screens with nothing to put on the left, as iOS does. */
@Composable
private fun BarIconSpacer() {
    Spacer(modifier = Modifier.size(48.dp))
}
