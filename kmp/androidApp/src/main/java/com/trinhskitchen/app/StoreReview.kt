package com.trinhskitchen.app

import android.app.Activity
import android.content.Context
import com.google.android.play.core.review.ReviewManagerFactory
import com.trinhskitchen.app.ui.profile.openUrl

/** Play listing, for the Profile row. Falls back to the web page if the Play app is absent. */
private const val PLAY_LISTING_URL = "https://play.google.com/store/apps/details?id=com.trinhskitchen.app"

/**
 * Asks Play for the in-app review sheet. Mirrors the iOS `requestReview` call after an order.
 *
 * Play decides whether the sheet appears, quotas it, and reports nothing about the outcome, so
 * there is no counter or result handling here. Play's policy also forbids asking about
 * sentiment before this runs, so it is never placed behind a "do you like the app?" question.
 * It does nothing on a build that was not installed from Play, an emulator without Play
 * Services included.
 */
fun requestStoreReview(activity: Activity) {
    val manager = ReviewManagerFactory.create(activity)
    manager.requestReviewFlow().addOnCompleteListener { request ->
        if (!request.isSuccessful) {
            println("⭐️ Play review flow unavailable: ${request.exception?.message}")
            return@addOnCompleteListener
        }
        manager.launchReviewFlow(activity, request.result)
    }
}

/** Opens the Play listing so anyone who wants to review can, whatever the prompt quota says. */
fun Context.openPlayListing() = openUrl(PLAY_LISTING_URL)
