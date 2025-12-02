//
//  OrderReceivedProductItemView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedProductItemView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    var productOrder : ProductOrder = ProductOrder.default
    
    var body: some View {
        VStack {
            HStack {
                Text(productOrder.name)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                Spacer()
                (
                    Text("\(productOrder.quantity) X ")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                        +
                    Text(getPriceAndCurrencySymbol(price: productOrder.price, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                )
            }
            
            // Display product note separately if exists
            if let noteMeta = productOrder.meta_data.first(where: { $0.key == "_note" }) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Note:")
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                            .foregroundColor(Constants.AppColor.secondaryBlack)
                        Spacer()
                    }
                    HStack {
                        Text(noteMeta.value.stringValue)
                            .font(.custom(Constants.AppFont.regularFont, size: 12))
                            .foregroundColor(Constants.AppColor.secondaryBlack)
                            .lineLimit(3)
                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
            
            // Display other meta_data (addons) excluding note
            let addons = productOrder.meta_data.filter { $0.key != "_note" }
            if addons.count > 0 {
                HStack {
                    Text ("Addition:")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    Spacer()
                }.padding(.top, 8)
                
                HStack {
                    ForEach(addons, id:\.key) { meta in
                        HStack {
                            Text(meta.key)
                            if let value = Int(meta.value.stringValue), value > 0 {
                                Text("(+\(getPriceAndCurrencySymbol(price: Double(value), currency: "$", currencyPosition: "right")))")
                            }
                        }
                        .font(.custom(Constants.AppFont.regularFont, size: 11))
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                    }
                    Spacer()
                }.padding(.top, 8)
            }
            
            Divider()
        }
        .padding(.top)
    }
}

struct OrderReceivedProductItemView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedProductItemView()
            .previewLayout(.sizeThatFits)
    }
}
