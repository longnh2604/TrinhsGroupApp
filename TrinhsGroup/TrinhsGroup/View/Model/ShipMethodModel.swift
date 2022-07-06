//
//  ShipMethodModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct ShipMethod: Identifiable, Codable{
    var id: Int
    var title: String
    var enabled: Bool
    var method_id: String
    var method_title: String
    var settings: ShipSettings
    
    static var `default` : ShipMethod {
        ShipMethod(id: 0, title: "Pickup", enabled: true, method_id: "", method_title:"", settings: ShipSettings(cost: Cost(id: "", value: "0")))
    }
}

struct ShipSettings: Codable{
    var cost: Cost
}

struct Cost: Codable{
    var id: String
    var value: String
}
