//
//  NotificationItemView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct NotificationItemView: View {

    var notification: AppNotification

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: notification.date, relativeTo: Date())
    }

    var body: some View {

        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.isRead
                          ? Constants.AppColor.lightGrayColor
                          : Color("ColorPrimary").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundColor(notification.isRead ? Color.gray : Color("ColorPrimary"))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Text(notification.title)
                        .font(.custom(notification.isRead ? Constants.AppFont.semiBoldFont : Constants.AppFont.boldFont, size: 14))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                        .lineLimit(2)

                    Spacer()

                    Text(relativeTime)
                        .font(.custom(Constants.AppFont.regularFont, size: 10))
                        .foregroundColor(.gray)
                        .padding(.top, 2)

                    if !notification.isRead {
                        Circle()
                            .fill(Color("ColorPrimary"))
                            .frame(width: 8, height: 8)
                            .padding(.top, 4)
                    }
                }

                Text(notification.content)
                    .font(.custom(Constants.AppFont.regularFont, size: 13))
                    .foregroundColor(notification.isRead ? .gray : Constants.AppColor.secondaryBlack)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(notification.isRead ? Color.clear : Color("ColorPrimary").opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Constants.AppColor.shadowColor.opacity(0.4), radius: 6, x: 0, y: 2)
    }
}

struct NotificationItemView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationItemView(notification: AppNotification(title: "Title", content: "Content"))
            .previewLayout(.sizeThatFits)
    }
}
