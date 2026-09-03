package com.trinhsgroup.shared.monitoring

import com.google.firebase.perf.FirebasePerformance

/**
 * Firebase Performance custom trace.
 *
 * Started in the constructor so the span begins where the object is created, which is what
 * the call sites read like. Nothing here can fail loudly: the SDK returns a Trace even
 * before Firebase finishes initialising, and dropping a measurement is always preferable to
 * breaking the screen being measured.
 */
actual class AppTrace actual constructor(name: String) {
    private val trace = FirebasePerformance.getInstance().newTrace(name).apply { start() }

    actual fun stop(success: Boolean) {
        trace.putAttribute("success", success.toString())
        trace.stop()
    }
}
