//
//  OrderReceivedView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import StoreKit
import SwiftUI

struct OrderReceivedView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.requestReview) private var requestReview
    
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

                        OrderItemsCard(order: mainViewModel.receivedOrder)

                        OrderPaymentSummaryCard(order: mainViewModel.receivedOrder)

                        OrderReceivedDetailView(order: mainViewModel.receivedOrder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear(perform: askForReview)
    }

    /// A completed order is the one moment the app has earned an opinion. StoreKit decides
    /// whether the sheet actually appears and caps it at three times a year, so there is no
    /// counter here — and per Play's equivalent rule on Android, no "are you happy?" question
    /// in front of it either.
    private func askForReview() {
        // Let the receipt settle first, so the sheet does not land mid-transition.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            requestReview()
        }
    }
}

struct OrderReceivedView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedView()
            .environmentObject(MainViewModel())
    }
}
