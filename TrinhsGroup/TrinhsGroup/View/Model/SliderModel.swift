//
//  SliderModel.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import Foundation

struct Slider: Identifiable, Codable{
    
    var id: Int
    var title: String
    var image: String
    
    static var `default` : Slider {
        Slider(id: 0, title: "", image: "https://asilarslan.com/grocery/wp-content/uploads/2021/04/close-up-man-delivering-food-2-e1618696795311.png")
    }
}
