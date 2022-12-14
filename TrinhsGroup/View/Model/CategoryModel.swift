//
//  CategoryModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Category: Identifiable, Codable {
    var id: Int
    var image: WooImage?
    var name: String
    
    static var `default` : Category {
        Category(id: 0, image: WooImage(id: 0, src: "https://asilarslan.com/trendy/wp-content/uploads/2021/04/pexels-apostolos-vamvouras-2285500.jpg"), name: "")
    }
}
