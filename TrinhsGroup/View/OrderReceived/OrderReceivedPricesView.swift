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
                Text(L10n.Common.subtotal.localizedKey)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                
                Spacer()
                
                Text(getPriceAndCurrencySymbol(price: mainViewModel.receivedOrder.subtotal, currency: "$", currencyPosition: "right"))
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                
        
            }
            
            // Show Discount 5% line derived from final total
            let finalTotal = Double(mainViewModel.receivedOrder.total) ?? 0
            let originalFromFinal = finalTotal > 0 ? (finalTotal / 0.95) : mainViewModel.receivedOrder.subtotal
            let discountValue = max(0, originalFromFinal - finalTotal)
            if discountValue > 0 {
                HStack {
                    Text(L10n.OrderReceived.discount.localizedKey)
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    
                    Spacer()
                    
                    Text(getPriceAndCurrencySymbol(price: discountValue, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                }
            }
            
            HStack {
                Text(L10n.Common.total.localizedKey)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(getPriceAndCurrencySymbol(price: finalTotal, currency: "$", currencyPosition: "right"))
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
