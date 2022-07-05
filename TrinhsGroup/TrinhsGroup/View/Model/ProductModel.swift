//
//  ProductModel.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import Foundation

struct Product: Identifiable, Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id, name, short_description, description, price, regular_price, sale_price, images, attributes
    }
    
    var id: Int
    var name: String
    var short_description: String
    var description: String
    var price: String
    var regular_price: String
    var sale_price: String
    var images = [WooImage]()
    var quantity: Int = 0
    var attributes = [Attribute]()
    
    var color: String = ""
    var size: String = ""
    
    var totalPrice: Double { return Double(price)! * Double(quantity) }
    
    static var `default` : Product {
        Product(id: 0, name: "Test", short_description: "Test Short Description", description: "Test Description", price: "10",regular_price:"10", sale_price: "10", images: [WooImage(id: 0, src: "https://asilarslan.com/grocery/wp-content/uploads/2021/04/cocacola_PNG10-500x500-1.png")])
    }
}
