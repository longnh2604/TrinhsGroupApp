//
//  StripeHelpers.swift
//  TrinhsGroup
//
//  Created by long on 29/07/2022.
//

import Stripe
import SwiftUI

class StripeManager: ObservableObject {
  let backendCheckoutUrl = URL(string: "https://trinhsgroup.com.au/?wc-api=wc_stripe")! // Your backend endpoint
  @Published var paymentSheet: PaymentSheet?
  @Published var paymentResult: PaymentSheetResult?

  func preparePaymentSheet() {
    // MARK: Fetch the PaymentIntent and Customer information from the backend
    var request = URLRequest(url: backendCheckoutUrl)
    request.httpMethod = "POST"
    let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
            let customerId = json["customer"] as? String,
            let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
            let paymentIntentClientSecret = json["paymentIntent"] as? String,
            let publishableKey = json["publishableKey"] as? String,
            let self = self else {
        // Handle error
        return
      }

      STPAPIClient.shared.publishableKey = publishableKey
      // MARK: Create a PaymentSheet instance
      var configuration = PaymentSheet.Configuration()
      configuration.merchantDisplayName = "Example, Inc."
      configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
      // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
      // methods that complete payment after a delay, like SEPA Debit and Sofort.
      configuration.allowsDelayedPaymentMethods = true

      DispatchQueue.main.async {
        self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
      }
    })
    task.resume()
  }
}

struct CheckoutView: View {
  @ObservedObject var model = StripeManager()

  var body: some View {
    VStack {
      if model.paymentSheet != nil {
        Text("Ready to pay.")
      } else {
        Text("Loading…")
      }
    }.onAppear { model.preparePaymentSheet() }
  }
}
