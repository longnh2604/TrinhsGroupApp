package com.trinhsgroup.shared.monitoring

/**
 * No-op.
 *
 * The iOS app does not link this framework yet — it still runs its own Swift
 * `MainServices`, which is where its `menu_load` / `order_preview` / `order_submit` traces
 * are started (`TrinhsGroup/Utility/PerformanceTrace.swift`). An actual is required all the
 * same, because the common code that calls it has to compile for iOS.
 *
 * When the iOS app does link Shared, this is the one place to fill in — `Performance.startTrace`
 * via the FirebasePerformance cinterop — and the Swift-side traces come out, so that the same
 * span is not reported twice under the same name.
 */
actual class AppTrace actual constructor(name: String) {
    actual fun stop(success: Boolean) {}
}
