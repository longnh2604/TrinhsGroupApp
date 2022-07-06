//
//  Constant.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

// COLOR
let colorBackground: Color = Color("ColorBackground")
let colorGray: Color = Color(UIColor.systemGray4)

// LAYOUT
let columnSpacing: CGFloat = 10
let rowSpacing: CGFloat = 10
var gridLayout: [GridItem] {
    return Array(repeating: GridItem(.flexible(), spacing: rowSpacing), count: 2)
}

func getPriceAndCurrencySymbol(price: String, currency: String, currencyPosition: String)->String{
    if currencyPosition == "right" {
        return "\(price)\(currency)"
    } else if currencyPosition == "right_space" {
        return "\(price) \(currency)"
    } else if currencyPosition == "left" {
        return "\(currency)\(price)"
    } else {
        return "\(currency) \(price)"
    }
}

func getDiscountPercentage(regularPrice: String, salePrice: String)->String{
    let percentage: Int = (100 * (Int(regularPrice)! - Int(salePrice)!)) / Int(regularPrice)!
    return "\(percentage)% OFF"
}

struct Constants {
    struct AppColor {
        static let primaryBlack = Color.init(hex: "1F1F1F")
        static let secondaryBlack = Color.init(hex: "464B5F")
        static let lightGrayColor = Color.init(hex: "F9F9F9")
        static let primaryRed = Color.init(hex: "CB2D3E")
        static let secondaryRed = Color.init(hex: "EF473A")
        static let gradientRedHorizontal = LinearGradient(gradient: Gradient(colors: [Color.init(hex: "CB2D3E"), Color.init(hex: "EF473A")]), startPoint: .leading, endPoint: .trailing)
        static let gradientRedVertical = LinearGradient(gradient: Gradient(colors: [Color.init(hex: "CB2D3E"), Color.init(hex: "EF473A")]), startPoint: .bottom, endPoint: .top)
        static let shadowColor = Color.init(hex: "dddddd")
        static let lightGreen = Color.init(hex: "e8fbe8")
    }
    
    struct AppFont {
        static let extraBoldFont = "OpenSans-ExtraBold"
        static let boldFont = "OpenSans-Bold"
        static let semiBoldFont = "OpenSans-SemiBold"
        static let regularFont = "OpenSans-Regular"
        static let lightFont = "OpenSans-Light"
    }
}
