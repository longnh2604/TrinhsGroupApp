# TrinhsGroup iOS — Task Board

> Last updated: 2026-05-27
> Owner: LongNH8

---

## Status Legend

| Symbol | Meaning |
|---|---|
| `[ ]` | Pending |
| `[~]` | In Progress |
| `[x]` | Done |
| `[!]` | Blocked |

---

## Backlog

### Architecture & Code Quality

| # | Task | Status | Priority | Notes |
|---|---|---|---|---|
| A-01 | Separate API credentials from Config.swift into .xcconfig / environment variables | `[ ]` | High | Credentials are hardcoded — security risk |
| A-02 | Extract direct URLSession calls from MainViewModel into Services layer | `[ ]` | High | `fetchProducts`, `fetchPayments`, `fetchZones`, `fetchShipMethods` bypass the service layer |
| A-03 | Add proper error handling — replace silent print() with user-facing alerts | `[ ]` | Medium | Most catch blocks only print to console |
| A-04 | Introduce a BaseViewModel with shared loading/error state | `[ ]` | Medium | DRY up duplicate @Published showLoading/message |
| A-05 | Add Combine-based NetworkAdapter to centralize URLSession requests | `[ ]` | Medium | NetworkAdapter.swift exists but unused |

### Features

| # | Task | Status | Priority | Notes |
|---|---|---|---|---|
| F-01 | Coupon validation — wire up min/max amount feedback to user alerts | `[ ]` | High | Logic exists but alert display is commented out |
| F-02 | Favorites persistence — save to UserDefaults or Firestore | `[ ]` | High | FavoriteView exists but no persistence |
| F-03 | Push notifications deep-link handling | `[ ]` | Medium | Firebase Messaging connected, deep-link routing not implemented |
| F-04 | Product search / filter | `[ ]` | Medium | No search functionality in current build |
| F-05 | Order status refresh in history | `[ ]` | Low | History fetches once on appear, no pull-to-refresh |

### Testing

| # | Task | Status | Priority | Notes |
|---|---|---|---|---|
| T-01 | Write unit tests for MainViewModel cart logic (add/remove/reset) | `[ ]` | High | No tests exist |
| T-02 | Write unit tests for AuthViewModel validation | `[ ]` | High | No tests exist |
| T-03 | Write unit tests for price calculations (subtotal, discounts, total) | `[ ]` | High | Logic is in MainViewModel — testable |
| T-04 | Write UI tests for auth flow (login, signup) | `[ ]` | Medium | |
| T-05 | Write UI tests for checkout flow | `[ ]` | Medium | |

### Infrastructure

| # | Task | Status | Priority | Notes |
|---|---|---|---|---|
| I-01 | Configure CI/CD (Xcode Cloud or GitHub Actions) | `[ ]` | Medium | No CI currently |
| I-02 | Add SwiftLint for code style enforcement | `[ ]` | Low | |
| I-03 | Set up crash reporting (Firebase Crashlytics) | `[ ]` | Medium | Firebase Core is installed |

---

## In Progress

| # | Task | Assignee | Started | Notes |
|---|---|---|---|---|
| — | — | — | — | — |

---

## Done

| # | Task | Completed | Notes |
|---|---|---|---|
| D-01 | Project bootstrap — SwiftUI + CocoaPods setup | 2022-06-27 | |
| D-02 | WooCommerce REST API integration | 2022-07-04 | APIClient.swift |
| D-03 | Firebase Firestore integration (events, product add-ons) | 2022-07-08 | FirestoreManager.swift |
| D-04 | Auth flow (Login, Signup, Forgot Password) | 2022-07-04 | JWT + AppStorage |
| D-05 | Category browsing & product listing | 2022-07-04 | |
| D-06 | Cart management (add/remove/reset) | 2022-07-04 | In-memory only |
| D-07 | Checkout flow with Stripe payment | 2022-07-04 | StripeManager.swift |
| D-08 | Order history | 2022-07-04 | HistoryViewModel.swift |
| D-09 | Discount / coupon code system | 2022-05-27 | Basic validation |
| D-10 | App Store upload fix + account creation issue | 2026-05-27 | Commit b86445c |

---

## Blocked

| # | Task | Blocked By | Notes |
|---|---|---|---|
| — | — | — | — |
