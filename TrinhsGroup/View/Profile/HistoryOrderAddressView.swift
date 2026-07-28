//
//  HistoryOrderAddressView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderAddressView: View {

    var order: Order

    /// Street address, then suburb/state/postcode — skipping whatever the order left blank,
    /// so a missing field does not leave a stray comma or an empty row.
    private var addressLines: [String] {
        let name = "\(order.billing.first_name) \(order.billing.last_name)"
            .trimmingCharacters(in: .whitespaces)

        let locality = [
            order.billing.city,
            order.billing.state,
            order.billing.postcode
        ]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        return [name, order.billing.address_1, locality].filter { !$0.isEmpty }
    }

    var body: some View {
        OrderDetailCard(
            // Previously titled with the generic "Status" string while showing an address —
            // a copy/paste slip, and confusing next to a card that really is about status.
            title: L10n.Profile.pickupDetails.localized.uppercased(),
            icon: "mappin.and.ellipse"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if !addressLines.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(addressLines, id: \.self) { line in
                            Text(line)
                                .font(.custom(Constants.AppFont.regularFont, size: 14))
                                .foregroundColor(Constants.AppColor.primaryBlack)
                        }
                    }
                }

                if !order.billing.phone.isEmpty {
                    contactRow(icon: "phone.fill", text: order.billing.phone)
                }

                if !order.billing.email.isEmpty {
                    contactRow(icon: "envelope.fill", text: order.billing.email)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func contactRow(icon: String, text: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "98A2B3"))
                .frame(width: 14)

            Text(text)
                .font(.custom(Constants.AppFont.regularFont, size: 13))
                .foregroundColor(Constants.AppColor.secondaryBlack)

            Spacer(minLength: 0)
        }
    }
}

struct HistoryOrderAddressView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderAddressView(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
