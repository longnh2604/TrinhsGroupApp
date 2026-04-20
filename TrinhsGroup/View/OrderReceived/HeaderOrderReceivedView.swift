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
            
            Image("ic_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100, alignment: .center)
            
            Text(L10n.OrderReceived.title.localizedKey)
                .fontWeight(.semibold)
            
            Text(L10n.OrderReceived.thankYouMessage.localizedKey)
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
