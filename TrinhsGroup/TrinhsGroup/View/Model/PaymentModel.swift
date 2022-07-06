//
//  PaymentModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Payment:  Codable, Hashable {
    
    var id: String
    var title: String
    var description: String
    var enabled: Bool
   
    static var `default` : Payment {
        Payment(id: "", title: "", description: "", enabled: false)
    }
}

struct Setting:  Codable {
    var instructions: SubSettings
}


struct SubSettings:  Codable {
    var value: String
}
