//
//  PaymentItemView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct PaymentItemView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var item: Payment
    
    var body: some View {
        HStack {
            ZStack {
                
                if mainViewModel.selectedPayment.id == item.id{
                    
                    Color("ColorPrimary")
                        .clipShape(Circle())
                        .frame(width: 35, height: 35)
                }
                
                Color("ColorPrimary")
                    .clipShape(Circle())
                    .frame(width: 35, height: 35)
                
                Color.white
                    .clipShape(Circle())
                    .frame(width: 30, height: 30)
                
                // checkmark for selected one...
                
                if mainViewModel.selectedPayment.id == item.id{
                    
                    Color("ColorPrimary")
                        .clipShape(Circle())
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            .frame(width: 40, height: 40)
            .onTapGesture {
                withAnimation{
                    mainViewModel.selectedPayment = item
                }
            }
            Text(item.title)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                .foregroundColor(Constants.AppColor.primaryBlack)
            Spacer()
        }
    }
}

struct PaymentItemView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentItemView(item: Payment.default)
            .previewLayout(.sizeThatFits)
    }
}
