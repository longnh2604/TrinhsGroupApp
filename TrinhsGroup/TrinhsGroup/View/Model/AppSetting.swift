//
//  AppSetting.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation

struct AppSetting: Codable {
    var status: String
    var code: String
    var currency_symbol: String
    var currency_position: String
    var thousand_separator: String
    var decimal_separator: String
    var number_of_decimals: String
}
