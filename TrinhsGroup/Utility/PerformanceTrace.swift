//
//  PerformanceTrace.swift
//  TrinhsGroup
//
//  FB-7 — performance monitoring.
//

import FirebasePerformance

/// One timed span reported to Firebase Performance.
///
/// App start (`_app_start`) and every HTTP request are captured by the SDK on its own, so
/// this only wraps the spans nothing else measures: the waits a customer actually sits
/// through, from the tap to the screen being usable. Those are named in `AppTrace.Name`.
///
/// The trace is optional all the way down because `Performance.startTrace` returns nil when
/// collection is off — a debug build with performance disabled, or a user on a build where
/// the SDK failed to configure. Nothing here should ever be the reason a screen breaks.
struct AppTrace {
    /// The spans FB-7 asks for. Firebase matches traces by name across releases, so these
    /// strings are the identity of the metric in the console — renaming one starts a new,
    /// empty history.
    enum Name {
        static let menuLoad = "menu_load"
        static let orderPreview = "order_preview"
        static let orderSubmit = "order_submit"
    }

    private let trace: Trace?

    init(_ name: String) {
        trace = Performance.startTrace(name: name)
    }

    /// Ends the span, tagging it with whether the work succeeded.
    ///
    /// The attribute is what makes the number usable: a request that fails fast and one that
    /// succeeds slowly otherwise land in the same distribution, and the p95 stops meaning
    /// anything. In the console this shows up as a filterable `success` dimension.
    func stop(success: Bool) {
        trace?.setValue(success ? "true" : "false", forAttribute: "success")
        trace?.stop()
    }
}
