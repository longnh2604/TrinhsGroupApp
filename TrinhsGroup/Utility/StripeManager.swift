//
//  StripeHelpers.swift
//  TrinhsGroup
//
//  Created by long on 29/07/2022.
//

import SwiftUI
import Stripe
import StripePaymentSheet

// Response model for Stripe payment intent from WooCommerce
struct StripePaymentIntentResponse: Codable {
    let paymentIntent: String?
    let customer: String?
    let ephemeralKey: String?
    let publishableKey: String?
    
    private enum CodingKeys: String, CodingKey {
        case paymentIntent = "payment_intent"
        case customer
        case ephemeralKey = "ephemeral_key"
        case publishableKey = "publishable_key"
    }
}

@MainActor
final class StripeManager: ObservableObject {
    private let api = WooCommerceAPI()

    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isPreparing = false
    @Published var lastError: String?

    // Prepare payment sheet with payment intent client secret directly
    func preparePaymentSheet(
        paymentIntentClientSecret: String,
        publishableKey: String,
        customerId: String? = nil,
        ephemeralKeySecret: String? = nil,
        skipPreparingCheck: Bool = false,
        completion: @escaping (Bool) -> Void
    ) {
        // Skip preparing check if called from preparePaymentSheetFromOrder (which already sets isPreparing)
        if !skipPreparingCheck {
            guard !isPreparing else {
                print("⚠️ Payment sheet preparation already in progress")
                completion(false)
                return
            }
            isPreparing = true
        }
        lastError = nil

        Task { @MainActor in
            StripeAPI.defaultPublishableKey = publishableKey
            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "TrinhsKitchen"
            config.allowsDelayedPaymentMethods = true
            
            // Add customer if available
            if let customerId = customerId,
               let ephemeralKeySecret = ephemeralKeySecret {
                config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKeySecret)
            }
            
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: config)
            
            // Only reset isPreparing if we set it in this function
            if !skipPreparingCheck {
                self.isPreparing = false
            }
            
            print("✅ Payment sheet prepared successfully")
            completion(true)
        }
    }
    
    // Prepare payment sheet from WooCommerce order
    // This method tries to get payment intent from a custom WordPress endpoint
    func preparePaymentSheetFromOrder(orderId: Int, completion: @escaping (Bool) -> Void) {
        guard !isPreparing else { return }
        isPreparing = true
        lastError = nil

        // Try to get payment intent from WooCommerce custom endpoint
        // This endpoint should be created in WordPress to return payment intent for the order
        api.request(endpoint: .getStripePaymentIntent(orderID: orderId), method: .GET) { [weak self] (result: Result<StripePaymentIntentResponse, Error>) in
            guard let self else { return }
            defer { Task { @MainActor in self.isPreparing = false } }

            switch result {
            case .success(let response):
                print("✅ Successfully received payment intent response")
                print("📦 Payment Intent: \(response.paymentIntent ?? "nil")")
                print("📦 Publishable Key: \(response.publishableKey ?? "nil")")
                print("📦 Customer: \(response.customer ?? "nil")")
                print("📦 Ephemeral Key: \(response.ephemeralKey ?? "nil")")
                
                // If we have payment intent from WooCommerce
                if let paymentIntentClientSecret = response.paymentIntent,
                   let publishableKey = response.publishableKey {
                    print("🔄 Preparing payment sheet...")
                    self.preparePaymentSheet(
                        paymentIntentClientSecret: paymentIntentClientSecret,
                        publishableKey: publishableKey,
                        customerId: response.customer,
                        ephemeralKeySecret: response.ephemeralKey,
                        skipPreparingCheck: true, // Skip check since we already set isPreparing
                        completion: { success in
                            print("📞 Payment sheet preparation completion called with success: \(success)")
                            completion(success)
                        }
                    )
                } else {
                    print("❌ Missing required fields in response")
                    Task { @MainActor in
                        self.lastError = "Payment intent not found in response. Please try again or use another payment method."
                        self.isPreparing = false
                        completion(false)
                    }
                }
            case .failure(let error):
                // If endpoint doesn't exist (404), return false immediately to use payment URL fallback
                print("Failed to get payment intent from endpoint: \(error.localizedDescription)")
                // Check if it's a 404 error (endpoint doesn't exist)
                if let httpError = error as? NSError, httpError.code == 404 {
                    print("Endpoint not found (404), will use payment URL fallback")
                }
                // Return false to trigger payment URL fallback in CheckOutView
                Task { @MainActor in
                    self.isPreparing = false
                    completion(false)
                }
            }
        }
    }
    
    // Legacy method for backward compatibility (using old endpoint)
    func preparePaymentSheet(completion: @escaping (Bool)->Void) {
        guard !isPreparing else { return }
        isPreparing = true
        lastError = nil

        let backendCheckoutUrl = URL(string: "https://trinhsgroup.au/?wc-api=wc_stripe")!
        var req = URLRequest(url: backendCheckoutUrl)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: req) { [weak self] data, resp, error in
            guard let self else { return }
            defer { Task { @MainActor in self.isPreparing = false } }

            if let error = error {
                Task { @MainActor in
                    self.lastError = "Network error: \(error.localizedDescription)"
                    completion(false)
                }
                return
            }

            let http = resp as? HTTPURLResponse
            let bodyText = data.flatMap { String(data:$0, encoding:.utf8) } ?? "<no body>"
            print("Stripe backend status=\(http?.statusCode ?? -1)\nBody:\n\(bodyText)")

            guard
                let data = data,
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String:Any],
                let customerId = json["customer"] as? String,
                let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                let paymentIntentClientSecret = json["paymentIntent"] as? String,
                let publishableKey = json["publishableKey"] as? String
            else {
                Task { @MainActor in
                    self.lastError = "Invalid backend response."
                    completion(false)
                }
                return
            }

            Task { @MainActor in
                StripeAPI.defaultPublishableKey = publishableKey
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "TrinhsKitchen"
                config.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                config.allowsDelayedPaymentMethods = true
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: config)
                completion(true)
            }
        }.resume()
    }

    func presentPaymentSheet(onCompletion: ((PaymentSheetResult) -> Void)? = nil) {
        guard let paymentSheet else { return }

        guard let presenter = UIApplication.shared.topMostViewController() else {
            lastError = "Unable to find a presenter."
            return
        }

        paymentSheet.present(from: presenter) { [weak self] result in
            Task { @MainActor in
                self?.paymentResult = result
                switch result {
                case .completed:
                    self?.lastError = nil
                case .canceled:
                    self?.lastError = nil
                case .failed(let error):
                    self?.lastError = error.localizedDescription
                }
                // Call completion handler if provided
                onCompletion?(result)
            }
        }
    }
}

private extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard
            let scene = connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        if let nav = top as? UINavigationController {
            return nav.visibleViewController
        } else if let tab = top as? UITabBarController {
            return tab.selectedViewController
        }
        return top
    }
}
