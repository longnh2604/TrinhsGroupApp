//
//  CustomNavigationBarView.swift
//  TrinhsGroup
//
//  Created by longnh on 2023/03/27.
//

import SwiftUI

struct CustomNavigationBarView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        HStack {
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
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
            , alignment: .center)
    }
}

struct CustomNavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        HomeNavigationBarView(showNotifications: .constant(false))
            .previewLayout(.sizeThatFits)
            .environmentObject(MainViewModel())
    }
}
