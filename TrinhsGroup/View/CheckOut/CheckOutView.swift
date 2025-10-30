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
    @State private var selectedPickupDateTime: Date?
    
    // Computed property: enable only when payments fetched and a method selected, and pickup time chosen
    private var isSubmitEnabled: Bool {
        let availablePayments = mainViewModel.payments.filter { $0.enabled && $0.id != "stripe" }
        let hasFetchedPayments = !availablePayments.isEmpty
        let hasSelectedPayment = mainViewModel.selectedPayment != nil
        let hasPickupTime = selectedPickupDateTime != nil
        return hasFetchedPayments && hasSelectedPayment && hasPickupTime
    }
    
    // Format pickup datetime for API
    private func formatPickupDateTimeForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        return formatter.string(from: date)
    }

    fileprivate func SubmitButton() -> some View {
        Button(action: {
            guard authViewModel.checkUserUpdatedBillInfo() else { return }
            guard let pickupDateTime = selectedPickupDateTime else { return }

            if mainViewModel.selectedPayment?.id == "stripe" {
                // 1) Create a WooCommerce order (pending) and get its payment URL
                //    Make sure your onCreateOrder returns the Woo "payment_url" in completion.
                let productOrders = mainViewModel.items.map { item in
                    return ProductOrder(
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
                    productOrders: productOrders,
                    pickupDateTime: formatPickupDateTimeForAPI(pickupDateTime)
                ) { orderId, paymentURLString in
                    // Handle Stripe payment flow
                    if let orderId = orderId {
                        print("Stripe order created successfully with ID: \(orderId)")
                        if let s = paymentURLString, let url = URL(string: s) {
                            checkoutURL = url
                            showSafari = true
                        } else {
                            print("Failed to get payment URL for Stripe")
                            // TODO: show an alert that we couldn't get a payment URL
                        }
                    } else {
                        print("Failed to create Stripe order")
                        // TODO: Show error message to user
                    }
                }

                return
            }

            let productOrders = mainViewModel.items.map { order_item in
                return ProductOrder(
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
            mainViewModel.onCreateOrder(
                user: authViewModel.user, 
                productOrders: productOrders,
                pickupDateTime: formatPickupDateTimeForAPI(pickupDateTime)
            ) { orderId, paymentURL in
                // Handle successful order creation
                if let orderId = orderId {
                    print("Order created successfully with ID: \(orderId)")
                } else {
                    print("Failed to create order")
                    // TODO: Show error message to user
                }
            }
        }) {
            Text("Submit Order")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background((stripeManager.isPreparing || !isSubmitEnabled) ? Color.gray : Color("ColorPrimary"))
                .cornerRadius(25)
        }
        .disabled(stripeManager.isPreparing || !isSubmitEnabled)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9").edgesIgnoringSafeArea(.all)
                VStack {
                    HStack {
                        Button(action: {
                            // Dismiss checkout and go back to previous screen
                            mainViewModel.presentedType = .none
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(Color("ColorPrimary"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 10)

                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Select Payment").font(.headline)

                            ForEach(mainViewModel.payments.filter { $0.enabled && $0.id != "stripe" }) { item in
                                PaymentItemView(item: item)
                                    .environmentObject(mainViewModel)
                            }
                            
                            // Pickup Date & Time Selection
                            PickupDateTimeView(selectedDateTime: $selectedPickupDateTime)
                                .padding(.top, 20)
                            
                            // Subtotal (original, pre-discount), Discount 5%, and final Total
                            let originalTotal = mainViewModel.total
                            let discountValue = originalTotal * 0.05
                            let finalTotal = max(0, originalTotal - discountValue)
                            HStack {
                                Text("Subtotal").foregroundColor(.gray)
                                Spacer()
                                Text(getPriceAndCurrencySymbol(price: originalTotal, currency: "$", currencyPosition: "right"))
                            }
                            .padding(.top, 15)
                            HStack {
                                Text("Discount (5%)").foregroundColor(.gray)
                                Spacer()
                                Text("-" + getPriceAndCurrencySymbol(price: discountValue, currency: "$", currencyPosition: "right"))
                            }
                            .padding(.top, 6)

                            HStack {
                                Text("Total:").foregroundColor(.gray)
                                Spacer()
                                Text(getPriceAndCurrencySymbol(price: finalTotal, currency: "$", currencyPosition: "right"))
                                    .bold()
                            }
                            if let msg = stripeManager.lastError {
                                Text(msg).foregroundColor(.red).font(.footnote)
                            }
                        }
                        .padding(15)
                    }
                    SubmitButton()
                }
                
                if mainViewModel.showLoading {
                    LoadingView().ignoresSafeArea()
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    mainViewModel.onFetchPaymentMethods()
                }
                if mainViewModel.selectedPayment?.id == "stripe" {
                    mainViewModel.selectedPayment = nil
                }
            }
            // Present Safari for the checkout
            .sheet(isPresented: $showSafari) {
                if let url = checkoutURL {
                    SafariSheet(url: url)
                        .ignoresSafeArea()
                }
            }
            .onOpenURL { url in
                guard url.scheme == "trinhsgroup",
                      url.host == "checkout" else { return }

                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let path = url.path  // e.g., "/complete"
                let orderId = components?.queryItems?.first(where: {$0.name == "order_id"})?.value
                let status  = components?.queryItems?.first(where: {$0.name == "status"})?.value

                print("Deep link received - Order ID: \(orderId ?? "nil"), Status: \(status ?? "nil")")
                
                // Dismiss Safari
                showSafari = false
                
                // Navigate to OrderReceivedView after successful payment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    mainViewModel.presentedType = .orderReceived
                }
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
