//
//  Constant.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

let ALERT_MESSAGE_DURATION: Double      =   3.0

// COLOR
let colorBackground: Color = Color("ColorBackground")
let colorGray: Color = Color(UIColor.systemGray4)

// LAYOUT
let columnSpacing: CGFloat = 10
let rowSpacing: CGFloat = 10
var gridLayout: [GridItem] {
    return Array(repeating: GridItem(.flexible(), spacing: rowSpacing), count: 2)
}

func getPrice(value: Double)->String{
    
    let format = NumberFormatter()
    format.numberStyle = .currency
    format.currencySymbol = ""
    
    return format.string(from: NSNumber(value: value)) ?? ""
}

func getPrice(value: String)->String{
    
    let format = NumberFormatter()
    format.numberStyle = .currency
    format.currencySymbol = ""
    
    return format.string(from: NSNumber(value: Float(value) ?? 0)) ?? ""
}

func getPriceAndCurrencySymbol(price: String, currency: String, currencyPosition: String)->String {
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

enum AnyCodableValue: Codable, Equatable {
    case integer(Int)
    case string(String)
    case float(Float)
    case double(Double)
    case boolean(Bool)
    case null
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        
        if let x = try? container.decode(Float.self) {
            self = .float(x)
            return
        }
        
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        
        if let x = try? container.decode(Bool.self) {
            self = .boolean(x)
            return
        }
        
        if let x = try? container.decode(String.self) {
                 self = .string(x)
                 return
             }
        
        if let _ = try? container.decodeNil() {
                 self = .string("")
                 return
             }
        
        throw DecodingError.typeMismatch(AnyCodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type"))
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .float(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .boolean(let x):
            try container.encode(x)
        case .null:
            try container.encode(self)
            break
        }
    }
    
    //Get safe Values
    var stringValue: String {
        switch self {
        case .string(let s):
            return s
        case .integer(let s):
            return "\(s)"
        case .double(let s):
            return "\(s)"
        case .float(let s):
            return "\(s)"
        default:
            return ""
        }
    }
    
    var intValue: Int {
        switch self {
        case .integer(let s):
            return s
        case .string(let s):
            return (Int(s) ?? 0)
        case .float(let s):
            return Int(s)
        case .null:
            return 0
        default:
            return 0
        }
    }
    
    var floatValue: Float {
        switch self {
        case .float(let s):
            return s
        case .integer(let s):
            return Float(s)
        case .string(let s):
            return (Float(s) ?? 0)
        default:
            return 0
        }
    }
    
    var doubleValue: Double {
        switch self {
        case .double(let s):
            return s
        case .string(let s):
            return (Double(s) ?? 0.0)
        case .integer(let s):
            return (Double(s))
        case .float(let s):
            return (Double(s) ?? 0.0)
        default:
            return 0.0
        }
    }
    
    var booleanValue: Bool {
        switch self {
        case .boolean(let s):
            return s
        case .integer(let s):
            return s == 1
        case .string(let s):
            let bool = (Int(s) ?? 0) == 1
            return bool
        default:
            return false
        }
    }

    
}
