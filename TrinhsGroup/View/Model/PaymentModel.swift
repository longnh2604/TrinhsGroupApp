//
//  PaymentModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Payment: Codable, Hashable, Identifiable {
    
    var id: String
    var title: String
    var description: String
    var enabled: Bool
    var order: Int
    var method_title: String
    var method_description: String
   
    // CodingKeys to map JSON keys to properties
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case enabled
        case order
        case method_title
        case method_description
    }
    
    // Custom Decoder to handle optional fields and different response formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        
        // Handle order field that can be either Int or String
        if let orderInt = try? container.decode(Int.self, forKey: .order) {
            order = orderInt
        } else if let orderString = try? container.decode(String.self, forKey: .order) {
            order = Int(orderString) ?? 0
        } else {
            order = 0
        }
        
        method_title = try container.decodeIfPresent(String.self, forKey: .method_title) ?? title
        method_description = try container.decodeIfPresent(String.self, forKey: .method_description) ?? description
    }
}

struct Setting:  Codable {
    var instructions: SubSettings
}


struct SubSettings:  Codable {
    var value: String
}
