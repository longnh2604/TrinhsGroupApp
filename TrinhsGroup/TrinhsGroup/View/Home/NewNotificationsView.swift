//
//  NewNotificationsView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct NewNotificationsView: View {
    
    @AppStorage("notifications") var notifications: Int?
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    @State var newNotifications = [AppNotification]()
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                self.mode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .overlay(
            Text("Notifications")
                .font(.headline)
                .padding(.horizontal, 10)
                .background(Color.init(hex: "f9f9f9"))
            , alignment: .center)
    }
    
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                NavigationBarView()
                    
                    Spacer()
                    
                    ScrollView(showsIndicators: false){
                        ForEach(newNotifications){ notification in
                            NotificationItemView(notification: notification)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                    .padding(.top)
                }
                .onAppear(perform: {
                    newNotifications = UserDefaultsManager.loadNew()
                    notifications = 0
                    UserDefaultsManager.removeNewAll()
            })
            
            if newNotifications.count == 0 {
                EmptyNotificationView()
            }
        }
    }
}

struct NewNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NewNotificationsView()
    }
}
