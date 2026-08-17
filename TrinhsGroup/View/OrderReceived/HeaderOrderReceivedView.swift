//
//  HeaderOrderReceivedView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct HeaderOrderReceivedView: View {

    var order: Order

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Animation, icon and tint come from OrderStatusPresentation so this screen cannot drift
    /// from the status screen. A freshly created order is `on-hold`, giving Order_onHold.
    private var presentation: OrderStatusPresentation {
        OrderStatusPresentation(status: order.status)
    }

    var body: some View {
        VStack(spacing: 12) {
            badge

            // This screen's own copy, not the status vocabulary: "we have your order" is a
            // different message from "here is where your order is". The single-source-of-truth
            // rule forbids a second status→copy map, which this is not.
            Text(L10n.OrderReceived.title.localizedKey)
                .font(.custom(Constants.AppFont.boldFont, size: 21))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .multilineTextAlignment(.center)

            Text(L10n.OrderReceived.thankYouMessage.localizedKey)
                .font(.custom(Constants.AppFont.regularFont, size: 13))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Absorbed from the old detail row, which showed the order number and date beside
            // a Total whose value was commented out.
            Text(metaLine)
                .font(.custom(Constants.AppFont.regularFont, size: 11))
                .foregroundColor(Color(hex: "98A2B3"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var badge: some View {
        if let lottieName = presentation.lottieName {
            // Same 168x104 box as the status hero: Order_processing is 1.74:1 and a square
            // frame letterboxes these scenes to half height.
            LottieView(filename: lottieName, isStop: reduceMotion)
                .frame(width: 168, height: 104)
        } else {
            ZStack {
                Circle()
                    .fill(presentation.tint.opacity(0.10))
                    .frame(width: 96, height: 96)

                Image(systemName: presentation.icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(presentation.tint)
            }
        }
    }

    private var metaLine: String {
        guard let placed = order.dateCreated.orderTimelineStamp else {
            return "Order #\(order.number)"
        }
        return "Order #\(order.number)  ·  \(placed)"
    }
}

struct HeaderOrderReceivedView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderOrderReceivedView(order: Order.default)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
