//
//  StripeUICardView.swift
//  TrinhsGroup
//
//  Created by long on 29/07/2022.
//

import SwiftUI
import Stripe

@available(iOS 13.0.0, *)
struct SwiftUICardFormView: View {
    
    @State private var paymentMethodParams: STPPaymentMethodParams = STPPaymentMethodParams()
    @State private var cardFormIsComplete: Bool = false
    
    var body: some View {
        VStack {
            STPCardFormView.Representable(paymentMethodParams: $paymentMethodParams,
                                          isComplete: $cardFormIsComplete)
                .padding()
            Button(action: {
                print("Process payment...")
            }, label: {
                Text("Buy")
            }).disabled(!cardFormIsComplete)
            .padding()
        }
    }
}

@available(iOS 13.0.0, *)
struct SwiftUICardFormView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUICardFormView()
    }
}
