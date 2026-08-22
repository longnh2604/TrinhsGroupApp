package com.trinhskitchen.app.firebase

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.trinhskitchen.app.MainActivity
import com.trinhskitchen.app.R
import com.trinhsgroup.shared.storage.NotificationStore
import org.koin.android.ext.android.inject

/**
 * Receives pushes and records them, so the bell screen has a history and the tap can open the
 * order the push is about. Mirrors what AppDelegate does on iOS.
 *
 * Fires in every state, because `trinh-push-notify` 1.4.0 sends Android a data-only message
 * (title and body in `data`, `priority: high`) and leaves the `notification` block off. With one
 * present the FCM SDK would draw the tray notification itself and never call this, so the app
 * would never see the order id — that is the whole reason for the split payload. iOS is told
 * separately through `apns.payload.aps.alert` and behaves as it always did.
 */
class PushMessagingService : FirebaseMessagingService() {

    private val store: NotificationStore by inject()
    private val pushTokens: PushTokens by inject()

    override fun onNewToken(token: String) {
        pushTokens.register()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val id = message.messageId ?: message.sentTime.toString()
        val title = message.notification?.title ?: message.data["title"].orEmpty()
        val body = message.notification?.body ?: message.data["body"].orEmpty()
        val orderId = message.data[KEY_ORDER_ID]?.toIntOrNull()

        store.add(id = id, title = title, content = body, date = message.sentTime, orderId = orderId)
        if (title.isEmpty() && body.isEmpty()) return

        val tap = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(KEY_MESSAGE_ID, id)
            orderId?.let { putExtra(KEY_ORDER_ID, it.toString()) }
        }
        val manager = getSystemService(NotificationManager::class.java)
        ensureChannel(manager)
        manager.notify(
            id,
            0,
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setWhen(message.sentTime)
                .setContentIntent(
                    PendingIntent.getActivity(
                        this,
                        id.hashCode(),
                        tap,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                )
                .build()
        )
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Order updates", NotificationManager.IMPORTANCE_HIGH)
        )
    }

    companion object {
        /** `trinh-push-notify` sends the order id as a string. */
        const val KEY_ORDER_ID = "order_id"
        const val KEY_MESSAGE_ID = "notification_id"
        private const val CHANNEL_ID = "order_updates"
    }
}

/**
 * Pulls the app's own pushes that are still in the system tray into the history. Android's
 * answer to iOS `syncDeliveredNotifications()`.
 *
 * A backstop rather than the main path since the server stopped sending a `notification` block:
 * [PushMessagingService.onMessageReceived] now records every push, order id included. What is
 * left for this to catch is a tray that outlived the store — an entry posted by the old payload,
 * or by a server that starts sending `notification` again. The tray keeps no custom payload, so
 * what it recovers has no order id and is not tappable; `upsert` prefers the id already stored,
 * so this can never blank out a good entry.
 */
fun syncTrayNotifications(context: Context, store: NotificationStore) {
    val manager = context.getSystemService(NotificationManager::class.java) ?: return
    for (posted in manager.activeNotifications) {
        val extras = posted.notification.extras
        store.add(
            id = posted.tag ?: posted.id.toString(),
            title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty(),
            content = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty(),
            date = posted.postTime
        )
    }
}
