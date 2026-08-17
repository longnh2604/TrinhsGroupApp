//
//  NewNotificationsView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct NewNotificationsView: View {

    @ObservedObject var store = NotificationStore.shared
    // Provided by MainView; inherited through HomeView's fullScreenCover.
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
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

    /// One row, used by both sections. Previously only the "New" section had a tap
    /// gesture, which left every already-read notification inert.
    @ViewBuilder
    private func row(_ notification: AppNotification) -> some View {
        NotificationItemView(notification: notification)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.markRead(notification)
                }
                // Entries stored before orderID existed simply mark read.
                if let orderID = notification.orderID {
                    historyViewModel.openOrderFromNotification(orderID: orderID)
                }
            }
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
                                    row(notification)
                                }
                            }

                            if !earlier.isEmpty {
                                sectionHeader("Earlier")
                                    .padding(.top, unread.isEmpty ? 0 : 8)
                                ForEach(earlier) { notification in
                                    row(notification)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .overlay {
            if historyViewModel.isResolvingNotificationOrder {
                LoadingView()
                    .ignoresSafeArea()
            }
        }
        .onAppear(perform: {
            store.syncDeliveredNotifications()
        })
        .fullScreenCover(item: $historyViewModel.notificationOrder) { order in
            HistoryOrderDetailView(order: order) {
                historyViewModel.dismissNotificationOrder()
            }
            .environmentObject(historyViewModel)
            .environmentObject(authViewModel)
        }
        // Without this the failure paths — order deleted, fetch failed — would clear the
        // spinner and then show nothing, leaving the tap looking like it did nothing.
        .alert("Couldn't Open Order", isPresented: Binding(
            get: { !historyViewModel.message.isEmpty },
            set: { if !$0 { historyViewModel.message = "" } }
        )) {
            Button("OK", role: .cancel) { historyViewModel.message = "" }
        } message: {
            Text(historyViewModel.message)
        }
    }
}

struct NewNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NewNotificationsView()
    }
}
