package com.trinhskitchen.app.ui.profile

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import com.trinhskitchen.app.ui.theme.AppColors

/** The shop's own Facebook page — the channel the kitchen actually watches. */
const val SUPPORT_URL = "https://www.facebook.com/Vietnamesecuisine.8890/"

/** Opens a link in whatever the customer browses with. */
fun Context.openUrl(url: String) {
    try {
        startActivity(Intent(Intent.ACTION_VIEW, url.toUri()))
    } catch (e: ActivityNotFoundException) {
        println("🔗 No app to open $url: ${e.message}")
    }
}

/**
 * The legal text, kept in the app rather than behind a link so it is readable without a
 * connection and cannot change under a customer who has already agreed to it. Same wording as
 * iOS ProfileView's LegalDocument.
 */
enum class LegalDocument(val title: String, val sections: List<Pair<String, String>>) {
    TERMS(
        title = "Terms of Service",
        sections = listOf(
            "About these terms" to "These Terms govern your use of the Trinhs Kitchen Group app and its online ordering features. By using the app or placing an order, you agree to these Terms.",
            "Accounts" to "You are responsible for providing accurate account, contact, and pickup information and for keeping your password confidential. Please contact us promptly if you believe your account has been accessed without permission.",
            "Orders and pickup" to "Orders are requests to purchase food and are subject to acceptance, availability, and confirmation by Trinhs Kitchen Group. You must review your order, selected pickup time, and contact details before submitting it. Pickup times may change when necessary to prepare your order safely and accurately.",
            "Prices, payments, and refunds" to "Prices, promotions, menu items, and availability may change. Payment is processed through the payment method selected at checkout, including Stripe where available. Refunds, changes, and cancellations are handled in accordance with applicable law and our store policies; please contact us as soon as possible if you need help with an order.",
            "Vouchers and rewards" to "Vouchers, coupons, and reward points are subject to the conditions shown in the app or at issue. They may have expiry dates, minimum-order requirements, usage limits, and exclusions. They cannot be exchanged for cash unless required by law.",
            "Acceptable use" to "Do not misuse the app, interfere with its operation, submit fraudulent orders, attempt to access another person's account, or use the app in a way that violates applicable law.",
            "Changes and contact" to "We may update these Terms when our services or legal obligations change. Continued use after an update means you accept the revised Terms. For questions about an order or these Terms, contact Trinhs Kitchen Group through our website or support channels."
        )
    ),
    PRIVACY(
        title = "Privacy Policy",
        sections = listOf(
            "Our commitment" to "Trinhs Kitchen Group respects your privacy. This Policy explains how the app handles information when you create an account, place an order, use rewards, receive notifications, or update your profile.",
            "Information we collect" to "We collect account details such as your name, email address, phone number, billing and pickup information, order history, selected products, vouchers, reward activity, and any special instructions you provide with an order.",
            "Profile photos" to "If you choose to upload a profile photo, the app sends it to our WordPress Media Library and associates its URL with your customer profile. You can remove your profile photo in the app.",
            "How we use information" to "We use information to create and fulfil orders, arrange pickup, process payments, manage your account and rewards, provide support, improve app reliability, and send order-status notifications and offers where permitted.",
            "Service providers" to "Our services may use WooCommerce and WordPress for customer and order management, Stripe for supported payment processing, and Firebase services for app notifications and app features. These providers process information only as needed to provide their services.",
            "Sharing" to "We do not sell personal information. We share information with service providers and staff only when needed to process orders, provide support, meet legal obligations, protect our rights, or operate the app.",
            "Retention and security" to "We retain information for as long as reasonably needed for orders, accounts, legal obligations, dispute resolution, and business records. We use reasonable safeguards, but no internet service can guarantee absolute security.",
            "Your choices and contact" to "You may update account details, remove your profile photo, manage notification permissions in your device settings, or ask us about your personal information by contacting Trinhs Kitchen Group through our website or support channels.",
            "Updates to this Policy" to "We may update this Policy as our app or legal obligations change. The latest version is available in this screen. Effective date: 24 July 2026."
        )
    )
}

@Composable
fun LegalDocumentDialog(document: LegalDocument, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(text = document.title, fontWeight = FontWeight.Bold) },
        text = {
            Column(
                modifier = Modifier
                    .heightIn(max = 420.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                document.sections.forEach { (heading, body) ->
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(
                            text = heading,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.TextPrimary
                        )
                        Text(
                            text = body,
                            style = MaterialTheme.typography.bodySmall,
                            color = AppColors.TextSecondary
                        )
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Close") } }
    )
}
