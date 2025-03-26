//
//  StripeHelpers.swift
//  TrinhsGroup
//
//  Created by long on 29/07/2022.
//

import Stripe
import StripePaymentSheet

class StripeManager: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://trinhsgroup.com.au/?wc-api=wc_stripe")!
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    func preparePaymentSheet() {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let customerId = json["customer"] as? String,
                  let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                  let paymentIntentClientSecret = json["paymentIntent"] as? String,
                  let publishableKey = json["publishableKey"] as? String else {
                return
            }
            
            DispatchQueue.main.async {
                STPAPIClient.shared.publishableKey = publishableKey
                
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: {
                    var config = PaymentSheet.Configuration()
                    config.merchantDisplayName = "TrinhsKitchen"
                    config.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                    config.allowsDelayedPaymentMethods = true
                    return config
                }())
            }
        }
        task.resume()
    }
    
    func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
            
        // Get the current UIViewController from the key window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            DispatchQueue.main.async {
                paymentSheet.present(from: rootViewController) { paymentResult in
                    DispatchQueue.main.async {
                        self.paymentResult = paymentResult
                    }
                }
            }
        }
    }
}
