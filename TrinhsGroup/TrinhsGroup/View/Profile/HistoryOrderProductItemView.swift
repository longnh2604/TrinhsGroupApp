//
//  HistoryOrderProductItemView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderProductItemView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    var productOrder : ProductOrder = ProductOrder.default
    
    var body: some View {
        VStack {
            HStack {
                Text(productOrder.name)
                    .foregroundColor(.black)
                Spacer()
                (
                    Text("\(productOrder.quantity) X ")
                    +
                Text(getPriceAndCurrencySymbol(price: getPrice(value: Double(productOrder.price)), currency: "$", currencyPosition: "right"))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                )
            }
            
            if productOrder.meta_data.count > 0 {
                HStack {
                    Text ("Addition:")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    Spacer()
                }.padding(.top, 8)
                
                HStack {
                    ForEach(productOrder.meta_data, id:\.key) { meta in
                        HStack {
                            Text(meta.key)
                            if let value = Int(meta.value.stringValue), value > 0 {
                                Text("(+\(getPriceAndCurrencySymbol(price: String(value), currency: "$", currencyPosition: "right")))")
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

struct HistoryOrderProductItemView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderProductItemView()
            .previewLayout(.sizeThatFits)
    }
}
