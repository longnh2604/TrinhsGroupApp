//
//  ShippingItemView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct ShippingItemView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var item: ShipMethod
    
    var body: some View {
        HStack {
            ZStack{
                
                if mainViewModel.selectedShip.id == item.id{
                    
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
                
                if mainViewModel.selectedShip.id == item.id{
                    
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
                    mainViewModel.selectedShip = item
                }
            }
            Text(item.title)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                .foregroundColor(Constants.AppColor.primaryBlack)
            Spacer()
            
//            Text(getPriceAndCurrencySymbol(price: item.settings.cost.value, currency: "$", currencyPosition: "right"))
//                .font(.custom(Constants.AppFont.semiBoldFont, size: 16))
//                .foregroundColor(Constants.AppColor.primaryBlack)
//                .padding(.trailing, 5)
        }
        
    }
}

struct ShippingItemView_Previews: PreviewProvider {
    static var previews: some View {
        ShippingItemView(item: ShipMethod.default)
            .previewLayout(.sizeThatFits)
    }
}
