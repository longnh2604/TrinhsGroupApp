//
//  CheckOutView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI
import Stripe

struct CheckOutView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @StateObject var stripeManager = StripeManager()

    fileprivate func SubmitButton() -> some View {
        Button {
            guard authViewModel.checkUserUpdatedBillInfo() else { return }

            if mainViewModel.selectedPayment?.id == "stripe" {
                if stripeManager.paymentSheet == nil {
                    stripeManager.preparePaymentSheet { ok in
                        if ok { stripeManager.presentPaymentSheet() }
                    }
                } else {
                    stripeManager.presentPaymentSheet()
                }
                return
            }

            let productOrders = mainViewModel.items.map { order_item in
                ProductOrder(
                    id: 0,
                    product_id: order_item.id,
                    name: order_item.name,
                    quantity: order_item.quantity,
                    subtotal: "",
                    total: order_item.regular_price,
                    price: order_item.regular_price,
                    meta_data: order_item.meta_data
                )
            }
            mainViewModel.onCreateOrder(user: authViewModel.user, productOrders: productOrders)
        } label: {
            Text(stripeManager.isPreparing ? "Preparing…" : "Submit Order")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color("ColorPrimary"))
                .cornerRadius(25)
        }
        .disabled(stripeManager.isPreparing)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9").ignoresSafeArea()
                VStack {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Select Payment").font(.headline)
                            ForEach(mainViewModel.payments.filter { $0.enabled }) { item in
                                PaymentItemView(item: item)
                                    .environmentObject(mainViewModel)
                            }
                            HStack {
                                Text("Total:").foregroundColor(.gray)
                                Spacer()
                                Text(getPriceAndCurrencySymbol(price: mainViewModel.total, currency: "$", currencyPosition: "right"))
                                    .bold()
                            }
                            .padding(.top, 15)
                            if let msg = stripeManager.lastError {
                                Text(msg).foregroundColor(.red).font(.footnote)
                            }
                        }
                        .padding(15)
                    }
                    SubmitButton()
                }
            }
            .onAppear {
                // Only fetch payment methods here.
                mainViewModel.onFetchPamyentMethods() // (typo?) onFetchPaymentMethods
                // Do NOT prepare Stripe here; do it on demand.
            }
        }
    }
}
