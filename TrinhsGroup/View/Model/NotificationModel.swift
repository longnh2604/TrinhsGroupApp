//
//  NotificationModel.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import Foundation

struct AppNotification: Identifiable,Codable {
    var id: Int = UUID().hashValue
    var title: String
    var content: String
}
