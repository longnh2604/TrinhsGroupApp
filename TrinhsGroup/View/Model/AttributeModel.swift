//
//  AttributeModel.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import UIKit
import SwiftyJSON

struct Attribute: Identifiable, Codable  {
    var id: Int
    var name: String
    var options = [String]()
}
