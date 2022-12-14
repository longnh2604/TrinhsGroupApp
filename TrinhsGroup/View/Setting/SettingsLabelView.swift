//
//  SettingsLabelView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct SettingsLabelView: View {
    
    var labelText: String
    var labelImage: String
    
    var body: some View {
        HStack {
            Text(labelText.uppercased())
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
            Spacer()
            Image(systemName: labelImage)
        }
    }
}

struct SettingsLabelView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsLabelView(labelText: "Fruits", labelImage:  "info.circle")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
