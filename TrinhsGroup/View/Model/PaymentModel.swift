//
//  PaymentModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Payment:  Codable, Hashable, Identifiable {
    
    var id: String
    var title: String
    var description: String
    var enabled: Bool
    var order: Int
    var method_title: String
    var method_description: String
   
    // Custom Decoder to handle nil `sale_price`
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decode(String.self, forKey: .description)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        order = try container.decode(Int.self, forKey: .order)
        method_title = try container.decode(String.self, forKey: .method_title)
        method_description = try container.decode(String.self, forKey: .method_description)
    }
}

struct Setting:  Codable {
    var instructions: SubSettings
}


struct SubSettings:  Codable {
    var value: String
}
