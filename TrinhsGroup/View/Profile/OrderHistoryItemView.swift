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
                    Text(String(format: L10n.Profile.orderNoFormat.localized, order.number))
                        .fontWeight(.semibold)
                    Text(order.dateCreated.toAustraliaDateTime())
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
                Text(order.lineItems[0].name)
                    .font(.callout)
                
                Spacer()
                
                Text(L10n.Profile.showMore.localizedKey)
                    .font(.callout)
                
                Image(systemName: "chevron.compact.right")
            }
            .foregroundColor(.black)
            
            Divider()
            
            HStack {
                Text(order.paymentMethodTitle)
                    .padding(4)
                    .foregroundColor(.black)
                    .background(colorGray.cornerRadius(4))
                
                Spacer()
                
                Text(L10n.Common.total.localizedKey)
                
//                Text(getPriceAndCurrencySymbol(price: order.discountTotal, currency: "$", currencyPosition: "left"))
//                    .foregroundColor(Constants.AppColor.primaryBlack)
                
            }
            .foregroundColor(.black)
        }
        .padding()
        .background(Color.white.cornerRadius(15))
        
    }
    
    func getStatusColor(status: String) -> Color {
        switch status {
        case "on-hold":    return Color("ColorPrimary")
        case "processing": return Color("ColorGreen")
        case "completed":  return Color("ColorGray")
        case "cancelled":  return Color.red
        case "refunded":   return Color.orange
        case "pending":    return Color.gray
        default:           return Color("ColorPrimary")
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
