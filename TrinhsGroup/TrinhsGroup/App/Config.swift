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
var CONSUMER_KEY = "ck_b1900a99761e23483ea2c1c04a6a801f78368f60"
var CONSUMER_SECRET_KEY = "cs_7ce89d016f397d12964598c4cdc5955800330666"

var SECURITY_CODE = "8V06LupAaMBLtQqyqTxmcN42nn27FlejvaoSM3zXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

///Settings
var APP_NAME = "Trinhsgroup App"
var APP_DESCRIPTION = "Trinhsgroup App is the mobile app order for Trinhsgroup.com.au website"
var DEVELOPER = "Longnh"
var COMPABILITY = "iOS 13"
var WEBSITE_LABEL = "Trinhsgroup"
var WEBSITE_LINK = "longnh264@gmail.com"
var VERSION = "1.0.0"
