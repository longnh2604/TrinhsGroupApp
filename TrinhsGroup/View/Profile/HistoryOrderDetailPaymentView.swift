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
            
            //            HStack {
            //                Text("Shipping( Flat Rate )")
            //
            //                Spacer()
            //                
            //                Text(getPriceAndCurrencySymbol(price: order.shipping_lines[0].total, currency: "$", currencyPosition: "right"))
            //
            //            }
            //            .foregroundColor(.black)
            
            //            if order.discountTotal > 0 {
            //                HStack {
            //                    Text("Discount")
            //
            //                    Spacer()
            //                    
            //                    (
            //                        Text("-")
            //                            +
            //                    Text(getPriceAndCurrencySymbol(price: order.discountTotal, currency: "$", currencyPosition: "right"))
            //                    )
            //
            //                }
            //                .foregroundColor(.black)
            //            }
            
            
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                
                
                Spacer()
            }
        }
                
//        Text(getPriceAndCurrencySymbol(price: order.total, currency: "$", currencyPosition: "right"))
//        
//            }
//            .foregroundColor(.black)
//        }
//        .padding(.vertical)
    }
}

struct HistoryOrderDetailPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderDetailPaymentView(order: Order.default)
    }
}
