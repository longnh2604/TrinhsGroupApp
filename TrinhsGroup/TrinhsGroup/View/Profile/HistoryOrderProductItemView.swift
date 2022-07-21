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
