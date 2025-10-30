//
//  HistoryOrderDetailPaymentView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderDetailPaymentView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    var order: Order
    
    var body: some View {
        VStack(spacing: 4){
            HStack {
                Text("Subtotal")
                
                Spacer()
                
                Text(getPriceAndCurrencySymbol(price: order.subtotal, currency: "$", currencyPosition: "right"))
            }
            .foregroundColor(.black)
            
            if order.discount > 0 {
                HStack {
                    Text("Discount")

                    Spacer()
                    (
                        Text("-")
                            +
                    Text(getPriceAndCurrencySymbol(price: order.discount, currency: "$", currencyPosition: "right"))
                    )
                }
                .foregroundColor(.black)
            }
            
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(getPriceAndCurrencySymbol(price: Double(order.total) ?? 0, currency: "$", currencyPosition: "right"))
            }
        }
    }
}

struct HistoryOrderDetailPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderDetailPaymentView(order: Order.default)
    }
}
