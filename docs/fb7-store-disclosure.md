# FB-7 — store disclosure and console verification

The code half of FB-7 is on `feat/fb7-performance-monitoring`. This file covers the half that
lives in web consoles and cannot be committed: the store data disclosures the two new SDKs
require, and how to prove the traces are actually arriving.

Do the disclosures **before** submitting a build. A build that ships Crashlytics or
Performance without them is the disclosure mismatch that caused the 2026-08-18 rejection.

## What the new SDKs collect

| SDK | Collects | Tied to the customer's identity |
|---|---|---|
| Firebase Crashlytics | Crash stack traces, device model, OS version, a per-install UUID | No |
| Firebase Performance | Trace durations, network request timings, device/carrier/OS | No |

Neither is used for tracking in the App Store sense: nothing is shared with data brokers and
nothing is joined to third-party data for advertising.

## App Store Connect — App Privacy

App Store Connect → the app → App Privacy → Edit. Under **Diagnostics**, add:

- **Crash Data** — used for App Functionality; not linked to identity; not used for tracking.
- **Performance Data** — used for App Functionality; not linked to identity; not used for tracking.
- **Other Diagnostic Data** — used for App Functionality; not linked to identity; not used for tracking.
  (Crashlytics' own privacy manifest declares this one, so the label has to match it.)

These must agree with `TrinhsGroup/PrivacyInfo.xcprivacy`, which is compared against the label
at review. That file also declares the customer data the order payload already sends — name,
email, phone, physical address — so check the existing label still lists those too.

> The customer-data entries in the manifest were derived from the billing block in
> `MainServices.onCreateOrder`. They are a legal declaration: have someone at Trinhs confirm
> the list is complete before submitting.

## Google Play Console — Data safety

Play Console → the app → Policy → App content → Data safety. Under
**App info and performance**, add:

- **Crash logs** — collected, not shared; purpose: Analytics and App functionality; not
  required for the app to work; not linked to identity.
- **Diagnostics** — collected, not shared; purpose: Analytics and App functionality; not
  required; not linked to identity.

## Verifying it works

Neither product shows anything in the console until a real build reports. Both take time —
Crashlytics is minutes, Performance is up to 12 hours for the first data on a new app, and
under an hour after that.

**1. Crash reporting, with symbols.**

Build and run a Release build on a device (a Debug build has no dSYM to upload, and the
upload phase deliberately skips itself there). Force a crash, then relaunch — Crashlytics
sends the report on the *next* launch, never the crashing one.

- iOS: add `fatalError("FB-7 test crash")` behind a button, or attach and call
  `fatalError()` from the debugger. Remove it afterwards.
- Android: `throw RuntimeException("FB-7 test crash")`.

In Firebase Console → Crashlytics the report should show named frames, not raw addresses. If
it shows addresses, the dSYM upload phase did not run — check the build log for the
`[FB-7] Upload Crashlytics dSYMs` phase.

**2. The four traces.**

Firebase Console → Performance → Custom traces (Dashboard for app start):

| Trace | Where it comes from | Exercise it by |
|---|---|---|
| `_app_start` | Automatic, both SDKs | Cold-launching the app |
| `menu_load` | `MainServices.fetchSelectedCategoryProducts` / `MainViewModel.onFetchSelectedCategoryProducts` | Opening Menu, switching category |
| `order_preview` | `MainServices.fetchOrderQuote` / `MainViewModel.onFetchOrderQuote` | Changing the basket at checkout |
| `order_submit` | `MainServices.onCreateOrder` / `MainViewModel.onCreateOrder` | Placing an order |

Each carries a `success` attribute, so filter on it — a fast failure and a slow success
otherwise average together and the p95 stops meaning anything.

**3. Cost of the SDKs.**

The plan asks for release size and cold-start time measured before and after. Take both from
a Release build on the same device, comparing against `main`:

- iOS size: Xcode → Organizer → the archive → App Store Connect app-size report.
- Android size: the `.aab` size, and Play Console → App bundle explorer → download size.
- Cold start: `_app_start` in the Firebase console once data lands, or
  `adb shell am start -W -n com.trinhskitchen.app/.MainActivity` on Android.

## Not done here

A third-party APM, custom metric dashboards, and alerting rules were all skipped, per the
plan. Firebase's own console covers "regularly test and optimize"; revisit if it proves blind
to something real.
