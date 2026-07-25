//
//  NewNotificationsView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct NewNotificationsView: View {

    @ObservedObject var store = NotificationStore.shared
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    private var unread: [AppNotification] {
        store.notifications.filter { !$0.isRead }
    }

    private var earlier: [AppNotification] {
        store.notifications.filter { $0.isRead }
    }

    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                self.mode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Constants.AppColor.shadowColor.opacity(0.6), radius: 4, x: 0, y: 2)
            }
            .padding(.leading, 16)

            Spacer()

            if store.unreadCount > 0 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.markAllRead()
                    }
                }) {
                    Text("Mark all read")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 12))
                        .foregroundColor(Color("ColorPrimary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("ColorPrimary").opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 44)
        .overlay(
            VStack(spacing: 1) {
                Text("Notifications")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 16))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                if store.unreadCount > 0 {
                    Text("\(store.unreadCount) unread")
                        .font(.custom(Constants.AppFont.regularFont, size: 11))
                        .foregroundColor(Color("ColorPrimary"))
                }
            }
            , alignment: .center)
    }

    fileprivate func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.custom(Constants.AppFont.boldFont, size: 13))
                .foregroundColor(Constants.AppColor.secondaryBlack)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    var body: some View {
        ZStack {
            Constants.AppColor.lightGrayColor
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                NavigationBarView()

                if store.notifications.isEmpty {
                    EmptyNotificationView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            if !unread.isEmpty {
                                sectionHeader("New")
                                ForEach(unread) { notification in
                                    NotificationItemView(notification: notification)
                                        .padding(.horizontal, 16)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                store.markRead(notification)
                                            }
                                        }
                                }
                            }

                            if !earlier.isEmpty {
                                sectionHeader("Earlier")
                                    .padding(.top, unread.isEmpty ? 0 : 8)
                                ForEach(earlier) { notification in
                                    NotificationItemView(notification: notification)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .onAppear(perform: {
            store.syncDeliveredNotifications()
        })
    }
}

struct NewNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NewNotificationsView()
    }
}
