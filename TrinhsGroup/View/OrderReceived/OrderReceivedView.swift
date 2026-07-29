//
//  OrderReceivedView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                mainViewModel.presentedType = .none
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .overlay(
            Text(L10n.OrderReceived.checkout.localizedKey)
                .font(.headline)
                .padding(.horizontal, 10)
                .background(Color.init(hex: "f9f9f9"))
            , alignment: .center)
    }
    
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                NavigationBarView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        HeaderOrderReceivedView(order: mainViewModel.receivedOrder)

                        OrderReceivedItemsView(order: mainViewModel.receivedOrder)

                        OrderPaymentSummaryCard(order: mainViewModel.receivedOrder)

                        OrderReceivedDetailView(order: mainViewModel.receivedOrder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct OrderReceivedView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedView()
            .environmentObject(MainViewModel())
    }
}
