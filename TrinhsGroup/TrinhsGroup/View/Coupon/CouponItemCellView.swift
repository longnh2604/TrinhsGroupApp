//
//  CouponItemCellView.swift
//  TrinhsGroup
//
//  Created by long on 08/08/2022.
//

import SwiftUI

struct RadioButtonView: View {
    
    @Binding var checked: Bool
    let action: () -> Void
    
    var body: some View {
        Group {
            if checked {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                }.onTapGesture {
                    action()
                    self.checked = false
                }
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .onTapGesture {
                        action()
                        self.checked = true
                    }
            }
        }
    }
}

struct CouponItemCellView: View {
    
    var coupon: Coupon
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        HStack {
            Text(coupon.code ?? "")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.leading, 15)
            
            Text(coupon.isPercent ? "-\(coupon.amount ?? "")%" : "-\(getPriceAndCurrencySymbol(price: coupon.amount ?? "", currency: "$", currencyPosition: "right")))")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                .foregroundColor(Constants.AppColor.secondaryRed)
            
            Spacer()
            
            if coupon.id == mainViewModel.coupon.id {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                }
                .padding(.trailing, 15)
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .padding(.trailing, 15)
            }
        }
        .frame(height: 80)
        .background(Color.white)
        .cornerRadius(2)
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .clipped()
    }
}

struct CouponItemCellView_Previews: PreviewProvider {
    static var previews: some View {
        CouponItemCellView(coupon: Coupon.default)
    }
}
