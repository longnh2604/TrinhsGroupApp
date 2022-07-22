//
//  EventModel.swift
//  TrinhsGroup
//
//  Created by long on 08/07/2022.
//

import Foundation

struct AppEvent: Identifiable {
    var id: Int
    var content: String
    var type: String
    var title: String
    var link: String
    var imgURL: String
    
    init(_ dic: [String: Any]) {
        self.id = dic["id"] as? Int ?? 0
        self.content = dic["content"] as? String ?? ""
        self.type = dic["type"] as? String ?? ""
        self.imgURL = dic["imgURL"] as? String ?? ""
        self.title = dic["title"] as? String ?? ""
        self.link = dic["link"] as? String ?? ""
    }
}
