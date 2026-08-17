//
//  OrderItemsCard.swift
//  TrinhsGroup
//
//  The ITEMS section, shared by the order confirmation screen and the order history detail
//  screen. Previously two files — OrderReceivedItemsView and HistoryOrderItemsView — that
//  were byte-identical apart from their type names.
//

import SwiftUI

struct OrderItemsCard: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.OrderReceived.items.localized.uppercased(),
            icon: "bag"
        ) {
            VStack(spacing: 0) {
                ForEach(Array(order.lineItems.enumerated()), id: \.element.id) { index, item in
                    OrderLineItemRow(item: item)

                    // No rule after the last row — one below the final item reads as a list
                    // that got cut off.
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

struct OrderItemsCard_Previews: PreviewProvider {
    static var previews: some View {
        OrderItemsCard(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
