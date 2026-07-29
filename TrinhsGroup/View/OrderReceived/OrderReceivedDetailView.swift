//
//  OrderReceivedDetailView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedDetailView: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.Common.email.localized.uppercased(),
            icon: "envelope"
        ) {
            Text(order.billing.email)
                .font(.custom(Constants.AppFont.regularFont, size: 14))
                .foregroundColor(Constants.AppColor.primaryBlack)
        }
    }
}

struct OrderReceivedDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedDetailView(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
