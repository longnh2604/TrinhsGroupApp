//
//  OrderHistoryItemView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct OrderHistoryItemView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    var order: Order = Order.default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order No #\(order.number)")
                        .fontWeight(.semibold)
                    Text(order.date_created.toDate())
                        .font(.footnote)
                }
                .foregroundColor(.black)
                Spacer()
                Text(order.status.uppercased())
                    .font(.footnote)
                    .padding(4)
                    .foregroundColor(.white)
                    .background(getStatusColor(status: order.status).cornerRadius(4))
            }
            
            HStack {
                Text(order.line_items[0].name)
                    .font(.callout)
                
                Spacer()
                
                Text("show more")
                    .font(.callout)
                
                Image(systemName: "chevron.compact.right")
            }
            .foregroundColor(.black)
            
            Divider()
            
            HStack {
                Text(order.payment_method_title)
                    .padding(4)
                    .foregroundColor(.black)
                    .background(colorGray.cornerRadius(4))
                
                Spacer()
                
                Text("Total")
                
                Text(getPriceAndCurrencySymbol(price: order.total, currency: mainViewModel.appSetting!.currency_symbol.decodingHTMLEntities(), currencyPosition: mainViewModel.appSetting!.currency_position))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                

            }
            .foregroundColor(.black)
        }
        .padding()
        .background(Color.white.cornerRadius(15))
        
    }
    
    func getStatusColor(status: String) -> Color {
        if status == "on-hold" {
            return Color("ColorPrimary")
        }else if status == "processing" {
            return Color("ColorGreen")
        }else if status == "completed" {
            return Color("ColorGray")
        }else{
            return Color("ColorPrimary")
        }
    }
}

struct OrderHistoryItemView_Previews: PreviewProvider {
    static var previews: some View {
        OrderHistoryItemView()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(colorGray)
    }
}
