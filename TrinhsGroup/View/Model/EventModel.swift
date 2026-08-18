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
    /// Card artwork, 140x196pt on screen. See the Firestore field notes in docs/.
    var imgURL: String
    /// Small caps line above the title, e.g. "FAMILY SHARING".
    var eyebrow: String
    /// Price or summary line under the title.
    var subtitle: String
    /// Highlighted chip along the bottom of the card.
    var detail: String
    /// Full poster opened when the card is tapped. Empty hides the "View poster" hint.
    var posterURL: String
    /// Off takes the event out of the carousel without deleting the document. Absent
    /// counts as on, so documents written before this field existed still show.
    var active: Bool

    /// The wording is part of the artwork, so VoiceOver has nothing to read off the card
    /// without this.
    var accessibilityLabel: String {
        [eyebrow, title, subtitle, detail]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    init(_ dic: [String: Any]) {
        self.id = (dic["id"] as? Int) ?? Int(dic["id"] as? String ?? "") ?? 0
        self.content = dic["content"] as? String ?? ""
        self.type = dic["type"] as? String ?? ""
        self.imgURL = dic["imgURL"] as? String ?? ""
        self.title = dic["title"] as? String ?? ""
        self.link = dic["link"] as? String ?? ""
        self.eyebrow = dic["eyebrow"] as? String ?? ""
        self.subtitle = dic["subtitle"] as? String ?? ""
        self.detail = dic["detail"] as? String ?? ""
        self.posterURL = dic["posterURL"] as? String ?? ""
        self.active = dic["active"] as? Bool ?? true
    }
}
