//
//  OrderPaymentSummaryCard.swift
//  TrinhsGroup
//
//  The money breakdown, shared by the confirmation screen and the order history detail
//  screen. One copy because the two previously disagreed: the confirmation screen
//  reverse-engineered the discount as total / 0.95, and the history screen looked for it in
//  discount_total, where the app discount never appears — so it showed a subtotal and a total
//  with nothing in between to explain the gap.
//

import SwiftUI

struct OrderPaymentSummaryCard: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.Profile.paymentSummary.localized.uppercased(),
            icon: "creditcard"
        ) {
            VStack(spacing: 9) {
                row(L10n.Common.subtotal.localized, amount: order.subtotal)

                // Each fee carries the server's own label and figure — "Discount 5%", "-1.63".
                // The app deliberately does not know the rate: assuming it was the bug this
                // replaces. Identified by offset because FeeLine has no id and two fees may
                // legitimately share a name.
                ForEach(Array(order.fees.enumerated()), id: \.offset) { _, fee in
                    row(
                        fee.name,
                        amount: fee.amount,
                        tint: fee.amount < 0 ? Color(hex: "57A733") : nil
                    )
                }

                // discount_total is voucher discounts only.
                if order.discount > 0 {
                    row(
                        L10n.OrderReceived.discount.localized,
                        amount: -order.discount,
                        tint: Color(hex: "57A733")
                    )
                }

                Rectangle()
                    .fill(Color(hex: "EDEFF2"))
                    .frame(height: 1)
                    .padding(.vertical, 2)

                row(
                    L10n.Common.total.localized,
                    amount: Double(order.total) ?? 0,
                    emphasised: true
                )

                if !order.paymentMethodTitle.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 10))
                        Text(order.paymentMethodTitle)
                            .font(.custom(Constants.AppFont.regularFont, size: 12))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .padding(.top, 2)
                }
            }
        }
    }

    /// One money line. A negative `amount` prints as `-$1.23` rather than `$-1.23`.
    private func row(
        _ label: String,
        amount: Double,
        tint: Color? = nil,
        emphasised: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(.custom(
                    emphasised ? Constants.AppFont.semiBoldFont : Constants.AppFont.regularFont,
                    size: emphasised ? 15 : 14
                ))
                .foregroundColor(Constants.AppColor.primaryBlack)

            Spacer()

            Text(
                (amount < 0 ? "-" : "")
                + getPriceAndCurrencySymbol(
                    price: abs(amount),
                    currency: "$",
                    currencyPosition: "left"
                )
            )
                .font(.custom(
                    emphasised ? Constants.AppFont.boldFont : Constants.AppFont.regularFont,
                    size: emphasised ? 16 : 14
                ))
                .foregroundColor(tint ?? Constants.AppColor.primaryBlack)
        }
    }
}

struct OrderPaymentSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        OrderPaymentSummaryCard(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
