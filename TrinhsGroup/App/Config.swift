//
//  Config.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation

let WOOCOMMERCE_URL = "https://trinhsgroup.com.au"
// CONSUMER_KEY / CONSUMER_SECRET_KEY used to live here as empty strings. Their only
// consumers were the query-string WooCommerce calls in APIClient, which are gone. The
// real read-only key now comes from the untracked Secrets.plist via `AppSecrets`.

///Settings
var APP_NAME = "Trinhsgroup App"
/// In-app about text. Kept in step with the store listings so the two never contradict:
/// only features the app actually has — pickup ordering, no delivery or reservations.
var APP_DESCRIPTION = "Order Trinh's Vietnamese favourites for pickup. Browse the full menu, make a dish yours with add-ons and notes, choose your pickup day and time, follow your order status, and earn points towards vouchers."
var DEVELOPER = "Trinhsgroup"
var COMPABILITY = "iOS 13 or above"
var WEBSITE_LABEL = "Trinhsgroup"
var WEBSITE_LINK = "https://trinhsgroup.au"
var VERSION = "1.0.0"

/// App Store numeric id, used only for the "Rate the app" deep link in Profile. Empty
/// hides that row; the review prompt after an order works without it.
let APP_STORE_ID = "6770763717"
