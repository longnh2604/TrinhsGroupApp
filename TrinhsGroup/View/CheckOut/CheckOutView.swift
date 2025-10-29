//
//  CheckOutView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct CheckOutView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @StateObject var stripeManager = StripeManager()
    @State private var checkoutURL: URL?
    @State private var showSafari: Bool = false

    fileprivate func SubmitButton() -> some View {
        Button(action: {
            guard authViewModel.checkUserUpdatedBillInfo() else { return }

            if mainViewModel.selectedPayment?.id == "stripe" {
                // 1) Create a WooCommerce order (pending) and get its payment URL
                //    Make sure your onCreateOrder returns the Woo "payment_url" in completion.
                let productOrders = mainViewModel.items.map { item in
                    ProductOrder(
                        id: 0,
                        product_id: item.id,
                        name: item.name,
                        quantity: item.quantity,
                        subtotal: "",
                        total: item.regular_price,
                        price: item.regular_price,
                        meta_data: item.meta_data
                    )
                }

                mainViewModel.onCreateOrder(
                    user: authViewModel.user,
                    productOrders: productOrders
                ) { orderId, paymentURLString in
                    // paymentURLString should be Woo's order payment URL (or checkout url)
                    if let s = paymentURLString, let url = URL(string: s) {
                        checkoutURL = url
                        showSafari = true
                    } else {
                        // TODO: show an alert that we couldn't get a payment URL
                    }
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
            mainViewModel.onCreateOrder(user: authViewModel.user, productOrders: productOrders) { orderId, paymentURL in
                // do nothing
            }
        }) {
            Text("Submit Order")
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
                Color.init(hex: "f9f9f9").edgesIgnoringSafeArea(.all)
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
                DispatchQueue.main.async {
                    mainViewModel.onFetchPamyentMethods()
                }
            }
            // Present Safari for the checkout
            .sheet(isPresented: $showSafari) {
                if let url = checkoutURL {
                    SafariSheet(url: url)
                        .ignoresSafeArea()
                }
            }
            // 2) Handle RETURN deep-link from Woo "Thank you" page
            .onOpenURL { url in
                // Example deep link: myapp://checkout/complete?order_id=123&status=processing
                guard url.scheme == "trinhsgroup",
                      url.host == "checkout" else { return }

                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let path = url.path  // e.g., "/complete"
                let orderId = components?.queryItems?.first(where: {$0.name == "order_id"})?.value
                let status  = components?.queryItems?.first(where: {$0.name == "status"})?.value

                // Dismiss Safari
                showSafari = false
            }
        }
    }
}

struct CheckOutView_Previews: PreviewProvider {
    static var previews: some View {
        CheckOutView()
    }
}

import SafariServices
import SwiftUI

struct SafariSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredBarTintColor = .systemBackground
        vc.preferredControlTintColor = .label
        vc.dismissButtonStyle = .close
        return vc
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
