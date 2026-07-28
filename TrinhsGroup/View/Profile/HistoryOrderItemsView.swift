//
//  HistoryOrderItemsView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderItemsView: View {
    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.OrderReceived.items.localized.uppercased(),
            icon: "bag"
        ) {
            VStack(spacing: 0) {
                ForEach(Array(order.lineItems.enumerated()), id: \.element.id) { index, item in
                    HistoryOrderProductItemView(productOrder: item)

                    if index < order.lineItems.count - 1 {
                        Rectangle()
                            .fill(Color(hex: "EDEFF2"))
                            .frame(height: 1)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
    }
}

struct HistoryOrderItemsView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderItemsView(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
