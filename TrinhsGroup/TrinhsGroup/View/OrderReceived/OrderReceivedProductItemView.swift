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
                    Text(getPriceAndCurrencySymbol(price: String(productOrder.price), currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                )
                
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
