//
//  StripeHelpers.swift
//  TrinhsGroup
//
//  Created by long on 29/07/2022.
//

import SwiftUI
import Stripe
import StripePaymentSheet

@MainActor
final class StripeManager: ObservableObject {
    // Your backend should return: { customer, ephemeralKey, paymentIntent, publishableKey }
    private let backendCheckoutUrl = URL(string: "https://trinhsgroup.com.au/?wc-api=wc_stripe")!

    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isPreparing = false
    @Published var lastError: String?

    func preparePaymentSheet(completion: @escaping (Bool)->Void) {
        guard !isPreparing else { return }
        isPreparing = true
        lastError = nil

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

    func presentPaymentSheet() {
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
