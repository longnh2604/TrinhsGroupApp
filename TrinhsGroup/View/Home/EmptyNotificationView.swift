//
//  EmptyNotificationView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct EmptyNotificationView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "bell")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100, alignment: .center)
                    .foregroundColor(Color("ColorPrimary"))
                Text("Empty Notification")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("ColorPrimary"))
                Spacer()
            }
            Spacer()
        }
    }
}

struct EmptyNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyNotificationView()
    }
}
