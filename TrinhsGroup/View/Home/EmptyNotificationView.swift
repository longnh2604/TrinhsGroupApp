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
            VStack(spacing: 12) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color("ColorPrimary").opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "bell")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundColor(Color("ColorPrimary"))
                }
                .padding(.bottom, 8)
                Text("No notifications yet")
                    .font(.custom(Constants.AppFont.boldFont, size: 18))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                Text("Order updates and offers from Trinh's\nwill show up here.")
                    .font(.custom(Constants.AppFont.regularFont, size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
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
