//
//  HomeNavigationBarView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct HomeNavigationBarView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @Binding var showNotifications: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.spring()){
                    showNotifications.toggle()
                }
            }, label: {
                Image(systemName: "bell")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .frame(height: 30)
                    .padding(.leading, 15)
            })
            
            Spacer()
            Button(action: {
                mainViewModel.presentedType = .cart
            }, label: {
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
                }else{
                    Image(systemName: "bag")
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                        .frame(height: 30)
                        .padding(.trailing, 15)
                }
                
            })
            
        }
        .frame(width: getRect().width, height: 35)
        .overlay(
            Text("Home")
                .font(.custom(Constants.AppFont.boldFont, size: 20))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
            , alignment: .center)
    }
}

struct HomeNavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        HomeNavigationBarView(showNotifications: .constant(false))
            .previewLayout(.sizeThatFits)
            .environmentObject(MainViewModel())
    }
}
