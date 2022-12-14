//
//  OrderReceivedPricesView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedPricesView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 4){
            HStack {
                Text("Subtotal")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                
                Spacer()
                
                Text(getPriceAndCurrencySymbol(price: String(mainViewModel.receivedOrder.subtotal), currency: "$", currencyPosition: "right"))
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                
        
            }
            
            HStack {
                Text("Shipping( Flat Rate )")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                
                Spacer()
                
                Text(getPriceAndCurrencySymbol(price: "0", currency: "$", currencyPosition: "right"))
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
              
            }
            
            if Double(mainViewModel.receivedOrder.discount_total)! > 0 {
                HStack {
                    Text("Discount")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    
                    Spacer()
                    
                    
                    Text(getPriceAndCurrencySymbol(price: mainViewModel.receivedOrder.discount_total, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                 
                }
            }
            
            
            HStack {
                Text("Total")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .fontWeight(.semibold)
                
                
                Spacer()
                
                Text(getPriceAndCurrencySymbol(price: mainViewModel.receivedOrder.total, currency: "$", currencyPosition: "right"))
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                
            }
        }
        .padding(.vertical)
    }
}

struct OrderReceivedPricesView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedPricesView()
            .environmentObject(MainViewModel())
    }
}
