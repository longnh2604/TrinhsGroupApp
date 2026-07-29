//
//  OrderLineItemRow.swift
//  TrinhsGroup
//
//  One purchased line, shared by the confirmation screen and the order history detail screen
//  so the same order reads identically in both places.
//

import SwiftUI

struct OrderLineItemRow: View {

    var item: LineItem = LineItem.default

    /// Indent for the secondary lines, so add-ons and the note hang under the product name
    /// rather than under the quantity chip. 30 (chip minWidth) + 12 (stack spacing).
    private let textInset: CGFloat = 42

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                // Quantity as a chip — clearer than "2 X $12.00" run together, and it lets the
                // money column line up down the card.
                Text("\(item.quantity)×")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 12))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .frame(minWidth: 30)
                    .padding(.vertical, 5)
                    .background(Color(hex: "F2F4F7"))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(item.name)
                    .font(.custom(Constants.AppFont.regularFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)

                Spacer(minLength: 8)

                // Every row here has to add up to the Subtotal below, so each reduction from
                // it is explained by exactly one row. `subtotal` is the line's pre-discount
                // figure; `total` is post-coupon, and summing that instead would double-count
                // a voucher that the Discount row already shows.
                Text(getPriceAndCurrencySymbol(
                    price: Double(item.subtotal) ?? (item.price * Double(item.quantity)),
                    currency: "$",
                    currencyPosition: "left"
                ))
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                    .padding(.top, 3)
            }

            // Names only, never a price. The server prices every line from the catalog and
            // treats add-on meta as text, so it never charges for these — a "+$3.00" here
            // would reconcile with nothing in the payment card below.
            if !item.addOns.isEmpty {
                Text(item.addOns.map(\.key).joined(separator: " · "))
                    .font(.custom(Constants.AppFont.regularFont, size: 11))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, textInset)
            }

            if let note = item.note {
                Text("“\(note)”")
                    .font(.custom(Constants.AppFont.regularFont, size: 12))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, textInset)
            }
        }
    }
}

struct OrderLineItemRow_Previews: PreviewProvider {
    static var previews: some View {
        OrderLineItemRow(item: LineItem.default)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
