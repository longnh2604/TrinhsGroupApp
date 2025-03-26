//
//  Config.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation
import SwiftUI

/// ONBOARD HELPER SCREENS
var ONBOARD_ENABLED = true

///Onboard Data
var ONBOARD_DATA: [Onboard] = [
    Onboard(title: "Online Order", headline: "Online order easily", image: "onboard-1", gradientColors: [Color("ColorBlue"), Color("ColorBlue")]),
    Onboard(title: "Discount", headline: "Use discount code", image: "onboard-2", gradientColors: [Color("ColorGreen"), Color("ColorGreen")]),
    Onboard(title: "Payment Method", headline: "Multiple Payment method like bank transfer, payid", image: "onboard-3", gradientColors: [Color("ColorRed"), Color("ColorRed")])
]

///Woocommerce
var WOOCOMMERCE_URL = "https://trinhsgroup.com.au"
var CONSUMER_KEY = "ck_06a325c37f15382c68001a78af0e37af2085719c"
var CONSUMER_SECRET_KEY = "cs_32c917fb8b82f86fc8305ae501b1d9096b12e461"

var SECURITY_CODE = ""

///Settings
var APP_NAME = "Trinhsgroup App"
var APP_DESCRIPTION = "Trinhsgroup App is the mobile app order for Trinhsgroup.com.au website"
var DEVELOPER = "Trinhsgroup"
var COMPABILITY = "iOS 13 or above"
var WEBSITE_LABEL = "Trinhsgroup"
var WEBSITE_LINK = "https://trinhsgroup.com.au"
var VERSION = "1.0.0"
