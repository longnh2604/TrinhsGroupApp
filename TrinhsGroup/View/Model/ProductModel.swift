//
//  ProductModel.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import Foundation

struct Product: Identifiable, Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id, name, short_description, description, price, regular_price, sale_price, images, attributes, categories, meta_data
    }
    
    var id: Int
    var name: String
    var short_description: String
    var description: String
    var price: Double
    var regular_price: Double
    var sale_price: Double
    var images = [WooImage]()
    var quantity: Int = 0
    var attributes = [Attribute]()
    var categories = [Category]()
    var meta_data = [ProductMetaData]()
    
    var color: String = ""
    var size: String = ""
    
    var totalPrice: Double { return price * Double(quantity) }
    
    var cartIdentifier: String {
        // Always sort to make the identifier order-independent!
        let metaString = meta_data
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.stringValue)" }
            .joined(separator: "&")
        return name + "|" + metaString
    }
    
    func getProductAddonOnly() -> [ProductMetaData] {
        return meta_data.filter({ !$0.key.contains("_") || !$0.key.contains("epafw") })
    }
    
    // Custom Decoder to handle nil `sale_price`
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        short_description = try container.decode(String.self, forKey: .short_description)
        description = try container.decode(String.self, forKey: .description)
        images = try container.decodeIfPresent([WooImage].self, forKey: .images) ?? []
        attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []
        categories = try container.decodeIfPresent([Category].self, forKey: .categories) ?? []
        meta_data = try container.decodeIfPresent([ProductMetaData].self, forKey: .meta_data) ?? []
        
        // Handle price conversion from String to Double
        let priceString = try container.decode(String.self, forKey: .price)
        price = Double(priceString) ?? 0
        
        let regularPriceString = try container.decode(String.self, forKey: .regular_price)
        regular_price = Double(regularPriceString) ?? 0
        
        let salePriceString = try container.decodeIfPresent(String.self, forKey: .sale_price) ?? ""
        sale_price = Double(salePriceString) ?? 0
    }
}

struct ProductAddOns: Identifiable, Codable {
    var id: Int
    var productId: Int
    var content: String
    var value: Int
    var checked: Bool
    
    init(_ dic: [String: Any]) {
        self.id = dic["categoryId"] as? Int ?? 0
        self.productId = dic["productId"] as? Int ?? 0
        self.content = dic["content"] as? String ?? ""
        self.value = dic["value"] as? Int ?? 0
        self.checked = false
    }
}

struct ProductMetaData: Identifiable, Codable, Equatable {
    static func == (lhs: ProductMetaData, rhs: ProductMetaData) -> Bool {
        return lhs.value == rhs.value && lhs.key == rhs.key
    }
    
    var id: Int
    var key: String
    var value: AnyCodableValue
}
