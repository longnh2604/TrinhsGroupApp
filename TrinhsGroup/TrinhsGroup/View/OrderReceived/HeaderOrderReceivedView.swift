//
//  HeaderOrderReceivedView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct HeaderOrderReceivedView: View {
    var body: some View {
        VStack(spacing: 10){
            
            Image("order-received")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100, alignment: .center)
            
            Text("Order Received")
                .fontWeight(.semibold)
            
            Text("Thank you. Your order has \nbeen received.")
                .multilineTextAlignment(.center)
                .font(.footnote)
        }
    }
}

struct HeaderOrderReceivedView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderOrderReceivedView()
            .previewLayout(.sizeThatFits)
    }
}
