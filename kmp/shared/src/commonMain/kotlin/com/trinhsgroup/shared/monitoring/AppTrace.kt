package com.trinhsgroup.shared.monitoring

/**
 * One timed span reported to the platform's performance monitor.
 *
 * FB-7. App start and every HTTP request are captured by Firebase Performance on its own,
 * so this only wraps the spans nothing else measures: the waits a customer actually sits
 * through, from the tap to the screen being usable. Those are named in [TraceName].
 *
 * Mirrors Swift's `AppTrace` in `TrinhsGroup/Utility/PerformanceTrace.swift`, deliberately
 * — the two platforms have to time the same boundary for their numbers to be comparable.
 */
expect class AppTrace(name: String) {
    /**
     * Ends the span, tagging it with whether the work succeeded.
     *
     * The attribute is what makes the number usable: a request that fails fast and one that
     * succeeds slowly otherwise land in the same distribution, and the p95 stops meaning
     * anything. In the console this shows up as a filterable `success` dimension.
     */
    fun stop(success: Boolean)
}

/**
 * The spans FB-7 asks for.
 *
 * Firebase matches traces by name across releases and across platforms, so these strings are
 * the identity of the metric in the console — renaming one starts a new, empty history, and
 * letting one drift from its Swift counterpart splits iOS and Android into separate metrics.
 */
object TraceName {
    const val MENU_LOAD = "menu_load"
    const val ORDER_PREVIEW = "order_preview"
    const val ORDER_SUBMIT = "order_submit"
}
