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
    @State private var currentStripeOrderId: Int? = nil
    
    // Computed property: enable only when payments fetched and a method selected, and pickup time chosen
    private var isSubmitEnabled: Bool {
        let availablePayments = mainViewModel.payments.filter { $0.enabled }
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
                // Handle Stripe payment flow with Payment Sheet
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

                // Create order first
                mainViewModel.onCreateOrder(
                    user: authViewModel.user,
                    productOrders: productOrders,
                    pickupDateTime: formatPickupDateTimeForAPI(pickupDateTime)
                ) { orderId, paymentURLString in
                    // Handle Stripe payment flow
                    guard let orderId = orderId else {
                        print("Failed to create Stripe order")
                        stripeManager.lastError = "Failed to create order. Please try again."
                        return
                    }
                    
                    print("Stripe order created successfully with ID: \(orderId)")
                    print("Payment URL: \(paymentURLString ?? "nil")")
                    
                    // Store order ID for later reference
                    currentStripeOrderId = orderId
                    
                    // Prepare Stripe Payment Sheet from order
                    stripeManager.preparePaymentSheetFromOrder(orderId: orderId) { success in
                        if success {
                            // Present payment sheet with completion handler
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                stripeManager.presentPaymentSheet { result in
                                    // Handle Stripe payment result
                                    switch result {
                                    case .completed:
                                        // Payment successful - navigate to order received
                                        print("Payment completed successfully")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            mainViewModel.reset()
                                            mainViewModel.presentedType = .orderReceived
                                        }
                                    case .canceled:
                                        // User canceled - do nothing, just show message
                                        print("Payment canceled by user")
                                        stripeManager.lastError = "Payment was canceled."
                                    case .failed(let error):
                                        // Payment failed - show error, do NOT navigate
                                        print("Payment failed: \(error.localizedDescription)")
                                        stripeManager.lastError = "Payment failed: \(error.localizedDescription). Please try again."
                                    }
                                }
                            }
                        } else {
                            // Fallback: if payment sheet preparation fails, use payment URL in Safari
                            print("Payment sheet preparation failed, falling back to payment URL")
                            if let paymentURLString = paymentURLString, let url = URL(string: paymentURLString) {
                                print("Opening Safari with payment URL: \(paymentURLString)")
                                checkoutURL = url
                                // Use main thread to update UI
                                DispatchQueue.main.async {
                                    showSafari = true
                                }
                            } else {
                                print("Failed to prepare Stripe payment sheet and no payment URL available")
                                // Show error to user
                                stripeManager.lastError = "Failed to initialize payment. Please try again or contact support."
                            }
                        }
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
                    mainViewModel.reset()
                    mainViewModel.presentedType = .orderReceived
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

                            ForEach(mainViewModel.payments.filter { $0.enabled }) { item in
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
            }
            // Present Safari for the checkout
            .sheet(isPresented: $showSafari, onDismiss: {
                // When Safari is dismissed, check if we need to verify order status
                // Only check if we haven't received a deep link callback
                if let orderId = currentStripeOrderId {
                    print("Safari dismissed, order ID: \(orderId)")
                    // Note: If payment was successful, deep link should have been called
                    // If no deep link was received, payment might still be pending
                    // We'll check order status via API if needed
                }
            }) {
                if let url = checkoutURL {
                    SafariSheet(
                        url: url,
                        isPresented: $showSafari,
                        onDismiss: {
                            print("Safari sheet dismissed")
                            mainViewModel.reset()
                            mainViewModel.presentedType = .orderReceived
                        }
                    )
                }
            }
            .onOpenURL { url in
                // Handle deep link at view level as well (backup)
                guard url.scheme == "trinhsgroup",
                      url.host == "checkout" else { return }

                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let orderId = components?.queryItems?.first(where: {$0.name == "order_id"})?.value
                let status = components?.queryItems?.first(where: {$0.name == "status"})?.value

                print("Deep link received in CheckOutView - Order ID: \(orderId ?? "nil"), Status: \(status ?? "nil")")
                
                // Dismiss Safari
                showSafari = false
                
                // Only navigate to OrderReceivedView if payment status is success/completed
                if let status = status, (status.lowercased() == "completed" || status.lowercased() == "processing" || status.lowercased() == "success") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        mainViewModel.reset()
                        mainViewModel.presentedType = .orderReceived
                    }
                } else {
                    // Payment failed or pending - show error
                    stripeManager.lastError = "Payment was not completed. Please try again or contact support."
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
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredBarTintColor = .systemBackground
        vc.preferredControlTintColor = .label
        vc.dismissButtonStyle = .close
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var parent: SafariSheet
        
        init(_ parent: SafariSheet) {
            self.parent = parent
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // Called when user dismisses Safari
            print("SafariViewController dismissed")
            parent.isPresented = false
            parent.onDismiss?()
        }
    }
}
