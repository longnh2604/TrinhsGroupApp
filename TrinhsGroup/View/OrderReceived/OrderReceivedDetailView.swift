//
//  OrderReceivedDetailView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedDetailView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order No")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ColorPrimary"))
                    Text("#\(mainViewModel.receivedOrder.number)")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ColorPrimary"))
                    Text(mainViewModel.receivedOrder.date_created.toDate())
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ColorPrimary"))
                    
                    Text(getPriceAndCurrencySymbol(price: mainViewModel.receivedOrder.total, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                        .foregroundColor(Constants.AppColor.primaryBlack)
           
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .fontWeight(.semibold)
                    .foregroundColor(Color("ColorPrimary"))
                Text(mainViewModel.receivedOrder.billing.email)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
            }
        }
    }
}

struct OrderReceivedDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedDetailView()
            .previewLayout(.sizeThatFits)
            .environmentObject(MainViewModel())
    }
}
