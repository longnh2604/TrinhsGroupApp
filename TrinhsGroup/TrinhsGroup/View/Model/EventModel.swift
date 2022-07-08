//
//  EventModel.swift
//  TrinhsGroup
//
//  Created by long on 08/07/2022.
//

import Foundation

struct AppEvent: Identifiable, Codable {
    var id: Int
    var content: String
    var type: String
    var title: String
    var link: String
    var imgURL: String
}
