//
//  CouponView.swift
//  TrinhsGroup
//
//  Created by long on 08/08/2022.
//

import SwiftUI

struct CouponView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                withAnimation(.spring()){
                    self.mode.wrappedValue.dismiss()
                }
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 50, height: 50)
            Spacer()
        }
        .padding(.top, 10)
        .frame(width: UIScreen.main.bounds.width, height: 35)
        .overlay(
            Text("Coupon List")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.top, 10)
            , alignment: .center)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationBarView()
                ZStack {
                    Constants.AppColor.lightGrayColor
                        .edgesIgnoringSafeArea(.all)
                    ScrollView(.vertical, showsIndicators: false, content: {
                        ForEach(mainViewModel.coupons) { coupon in
                            CouponItemCellView(coupon: coupon)
                                .onTapGesture {
                                    withAnimation(.easeOut) {
                                        if mainViewModel.coupon.id == coupon.id {
                                            mainViewModel.coupon = .default
                                        } else {
                                            mainViewModel.coupon = coupon
                                        }
                                    }
                                }
                                .environmentObject(mainViewModel)
                        }
                    })
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct CouponView_Previews: PreviewProvider {
    static var previews: some View {
        CouponView()
    }
}
