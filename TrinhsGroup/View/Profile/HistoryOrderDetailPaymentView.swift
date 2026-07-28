//
//  HistoryOrderDetailPaymentView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderDetailPaymentView: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.Profile.paymentSummary.localized.uppercased(),
            icon: "creditcard"
        ) {
            VStack(spacing: 9) {
                row(L10n.Common.subtotal.localized, amount: order.subtotal)

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

struct HistoryOrderDetailPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderDetailPaymentView(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
