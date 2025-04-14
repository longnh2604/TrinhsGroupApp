//
//  HomeNavigationBarView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct HomeNavigationBarView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    // Optional custom title (default = "Home")
    var title: String = "Home"
    
    // Show/hide notification icon
    var showNotificationIcon: Bool = true
    
    // Optional binding for notification toggle
    var showNotifications: Binding<Bool>? = nil
    
    var body: some View {
        HStack {
            if showNotificationIcon, let showNotifications = showNotifications {
                Button(action: {
                    withAnimation(.spring()) {
                        showNotifications.wrappedValue.toggle()
                    }
                }) {
                    Image(systemName: "bell")
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                        .frame(height: 30)
                        .padding(.leading, 15)
                }
            } else {
                // Empty space if notification icon is hidden (optional)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 30, height: 30)
                    .padding(.leading, 15)
            }

            Spacer()
            
            Button(action: {
                mainViewModel.presentedType = .cart
            }) {
                if mainViewModel.numberOfItems != 0 {
                    Image(systemName: "bag")
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                        .frame(height: 30)
                        .padding(.trailing, 15)
                        .overlay(
                            Text("\(mainViewModel.numberOfItems)")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .padding(5)
                                .background(Color("ColorPrimary"))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .offset(x: 5, y: 5)
                        )
                } else {
                    Image(systemName: "bag")
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                        .frame(height: 30)
                        .padding(.trailing, 15)
                }
            }
        }
        .frame(width: getRect().width, height: 35)
        .background(Constants.AppColor.lightGrayColor)
        .overlay(
            Text(title)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 20))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10),
            alignment: .center
        )
    }
}

