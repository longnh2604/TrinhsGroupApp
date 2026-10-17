package com.trinhskitchen.app.ui.components

import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import com.trinhsgroup.shared.util.HtmlDecoder
import kotlinx.coroutines.withTimeoutOrNull

/** How long a login/signup toast stays up. Matches iOS TOAST_DURATION_NANOSECONDS. */
private const val TOAST_DURATION_MS = 5_000L

/**
 * Snackbar host whose messages may carry WordPress HTML, e.g.
 * "<strong>Error:</strong> Unknown username": <strong>/<b> show bold, other tags are dropped.
 * Mirrors iOS CustomAlertView.
 */
@Composable
fun HtmlSnackbarHost(hostState: SnackbarHostState) {
    SnackbarHost(hostState) { data ->
        Snackbar {
            Text(
                buildAnnotatedString {
                    HtmlDecoder.boldSegments(data.visuals.message).forEach { segment ->
                        if (segment.bold) {
                            withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(segment.text) }
                        } else {
                            append(segment.text)
                        }
                    }
                }
            )
        }
    }
}

/**
 * Shows [message] for 5 seconds. Material's own durations are 4s or 10s, so this shows it
 * indefinitely and cancels after the timeout, which dismisses the snackbar.
 */
suspend fun SnackbarHostState.showToast(message: String) {
    withTimeoutOrNull(TOAST_DURATION_MS) {
        showSnackbar(message, duration = SnackbarDuration.Indefinite)
    }
}
