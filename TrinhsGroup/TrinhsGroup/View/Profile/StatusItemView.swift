//
//  StatusItemView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct StatusItemView: View {
    
    var current: String
    var status: String
    var date: String
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .center, spacing: 0){
                colorGray
                    .clipShape(Rectangle())
                    .frame(width: 5, height: 25)
                    .offset(y: 5)
                    .zIndex(0)
                if current == status {
                    Color("ColorPrimary")
                        .clipShape(Circle())
                        .frame(width: 15, height: 15)
                        .zIndex(1)
                } else {
                    colorGray
                        .clipShape(Circle())
                        .frame(width: 15, height: 15)
                        .zIndex(1)
                }
                colorGray
                    .clipShape(Rectangle())
                    .frame(width: 5, height: 25)
                    .offset(y: -5)
                    .zIndex(0)
            }
            .frame(height: 45)
            
            
            Text(status.uppercased())
                .padding(4)
                .foregroundColor(.white)
                .background(Color("ColorPrimary").cornerRadius(4))
            
            Spacer()
            
            if current == status {
                Text(date.toDate())
                    .foregroundColor(.black)
                    .font(.footnote)
            }
        }
    }
}

struct StatusItemView_Previews: PreviewProvider {
    static var previews: some View {
        StatusItemView(current: "on-hold", status: "pending payment", date: "18 April 21 05:05")
            .previewLayout(.sizeThatFits)
        
        StatusItemView(current: "on-hold", status: "on-hold", date: "18 April 21 05:05")
            .previewLayout(.sizeThatFits)
    }
}
