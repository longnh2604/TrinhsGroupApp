# TrinhsGroup iOS App — Project Guide

## System Overview

**TrinhsGroup** is an iOS e-commerce mobile app built with SwiftUI that connects to the [trinhsgroup.com.au](https://trinhsgroup.com.au) WooCommerce store. It allows users to browse products by category, add items to cart, apply coupons, choose shipping methods, and check out with multiple payment options (Stripe, bank transfer).

### Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 13+) |
| Architecture | MVVM + Combine |
| Backend API | WooCommerce REST API v3 |
| Auth | JWT (`/wp-json/jwt-auth/v1/token`) |
| Real-time / Events | Firebase Firestore |
| Push Notifications | Firebase Messaging |
| Payments | Stripe SDK |
| Image Loading | Kingfisher |
| JSON Parsing | SwiftyJSON + Codable |
| Animations | Lottie |
| Dependency Manager | CocoaPods |

### Architecture Pattern — MVVM + Combine

```
View  ──(reads)──▶  ViewModel  ──(subscribes to)──▶  Service  ──(calls)──▶  APIClient / Firebase
 │                      │                                                          │
 └─(@EnvironmentObject)─┘                                                  WooCommerce REST / Firestore
```

- **Services** expose Combine `AnyPublisher` streams (`loadingPublisher`, `errorPublisher`, domain publishers).
- **ViewModels** bind service publishers to `@Published` properties via `Combine`.
- **Views** consume ViewModels injected as `@EnvironmentObject`.

---

## Project Structure

```
TrinhsGroup/
├── App/
│   ├── TrinhsGroupApp.swift   # @main entry, bootstraps ViewModels
│   ├── AppDelegate.swift      # Firebase setup, push notifications
│   ├── Config.swift           # App-wide constants (WooCommerce URL, keys, feature flags)
│   └── ContentView.swift      # Placeholder (unused)
│
├── Helpers/                   # Reusable UI components
│   ├── CheckBoxView.swift
│   ├── CustomAlertView.swift
│   ├── FloatingButton.swift
│   ├── LoadingView.swift
│   ├── LottieLoadingView.swift
│   ├── MyApiClient.swift
│   ├── PagingView.swift
│   └── SwiftUICardFormView.swift  # Stripe card form wrapper
│
├── Utility/                   # Core cross-cutting utilities
│   ├── Constant.swift
│   ├── Extensions.swift       # String html2AttributedString, Color hex init, etc.
│   ├── FirestoreManager.swift # Firestore: events, product add-ons
│   ├── StripeManager.swift
│   └── UserDefaultsManager.swift
│
└── View/
    ├── Authorization/         # LoginView, SignupView, ForgetPasswordView
    ├── Cart/                  # CartView
    ├── Category/              # CategoryView, CategoryProductsView, CategoryRowView
    ├── CheckOut/              # CheckOutView, PaymentItemView, ShippingItemView
    ├── Favorites/             # FavoriteView
    ├── Home/                  # HomeView, DiscountView, SaleView, ImageSliderView, Notifications
    ├── ItemDetails/           # ItemDetailsView, ItemDetailsNavigationBarView
    ├── Main/                  # MainView (TabBar root — 5 tabs)
    ├── Model/                 # Data models (Codable structs)
    │   ├── ProductModel.swift
    │   ├── UserModel.swift
    │   ├── OrderModel.swift
    │   ├── CategoryModel.swift
    │   ├── CouponModel.swift
    │   ├── PaymentModel.swift
    │   ├── ShipMethodModel.swift
    │   ├── BillingModel.swift
    │   ├── ShippingModel.swift
    │   ├── ZoneModel.swift
    │   ├── SliderModel.swift
    │   ├── EventModel.swift
    │   ├── NotificationModel.swift
    │   ├── AttributeModel.swift
    │   ├── WooImageModel.swift
    │   └── AppSetting.swift
    ├── Networking/
    │   ├── APIClient.swift    # URLSession-based WooCommerce REST calls
    │   └── NetworkAdapter.swift
    ├── Onboard/               # OnboardingView, OnboardCardView, StartButtonView
    ├── OrderReceived/         # Post-checkout confirmation screens
    ├── Profile/               # ProfileView, EditProfileView, EditAddressView, HistoryOrdersView
    ├── Services/              # Combine-based service layer
    │   ├── AuthServices.swift
    │   ├── MainServices.swift
    │   └── HistoryServices.swift
    ├── Setting/               # SettingView, SettingsRowView, SettingsLabelView
    └── ViewModel/
        ├── AuthViewModel.swift     # Login, signup, profile update
        ├── MainViewModel.swift     # Cart, categories, orders, shipping, coupons
        └── HistoryViewModel.swift  # Order history
```

---

## App Flow

```
Launch
  └─▶ Onboarding (first launch, ONBOARD_ENABLED=true)
        └─▶ Auth check (isLogin in AppStorage)
              ├─▶ Not logged in → SignupView / LoginView
              └─▶ Logged in → MainView (TabBar)
                    ├── Tab 0: Home       (deals, sales, discounts, promotions)
                    ├── Tab 1: Category   (browse by category → products)
                    ├── Tab 2: Favorites  (saved/liked products)
                    ├── Tab 3: Profile    (account info, order history)
                    └── Tab 4: Settings   (app info, links)
                    
                    Overlay sheets (driven by MainViewModel.presentedType):
                    ├── CartView
                    ├── CheckOutView
                    └── OrderReceivedView
```

---

## Key Configs (`App/Config.swift`)

| Variable | Purpose |
|---|---|
| `ONBOARD_ENABLED` | Toggle onboarding screens |
| `WOOCOMMERCE_URL` | Base URL for WooCommerce REST |
| `CONSUMER_KEY / CONSUMER_SECRET_KEY` | WooCommerce API credentials |
| `SECURITY_CODE` | Custom JWT security header |
| `APP_NAME`, `VERSION` | Display values |

> **Security note:** Credentials are hardcoded in `Config.swift`. Do not commit changes to these values or expose them publicly.

---

## CocoaPods Dependencies

```ruby
pod 'Kingfisher'          # Async image loading & caching
pod 'SwiftyJSON'          # JSON parsing helper
pod 'Firebase/Core'
pod 'Firebase/Messaging'  # Push notifications
pod 'Firebase/Firestore'  # Events & product add-ons real-time DB
pod 'Stripe'              # Payment processing
pod 'lottie-ios'          # Lottie animations (loading screens)
```

After cloning, run: `pod install` then open `TrinhsGroup.xcworkspace`.

---

## Agent Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `ios-senior-dev` | `/ios-senior-dev` | iOS Swift/SwiftUI senior developer — feature impl, architecture review, code quality |
| `ios-tester` | `/ios-tester` | iOS senior tester — test plan design, verification, QA sign-off |

---

## Conventions

- **Naming**: Views use `View` suffix, ViewModels use `ViewModel`, Services use `Services`.
- **State sharing**: Use `@EnvironmentObject` for ViewModels passed down the tree.
- **No unit tests exist yet** — test coverage is tracked in `plan/tasks.md`.
- **SwiftUI only** — no UIKit views except `AppDelegate` and `UITabBar.appearance()`.
- **Combine streams** — always cancel subscriptions in `cancellableSet: Set<AnyCancellable>`.
