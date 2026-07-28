//
//  HistoryOrderProductItemView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderProductItemView: View {

    var productOrder: LineItem = LineItem.default

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Quantity as a chip — clearer than "2 X $12.00" run together, and it lets the
            // money column line up down the card.
            Text("\(productOrder.quantity)×")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 12))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .frame(minWidth: 30)
                .padding(.vertical, 5)
                .background(Color(hex: "F2F4F7"))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(productOrder.name)
                .font(.custom(Constants.AppFont.regularFont, size: 14))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            Spacer(minLength: 8)

            // WooCommerce's `total` is the line total after any discount, which is what the
            // payment summary below adds up. Multiplying price × quantity here would
            // disagree with it on a discounted line.
            Text(getPriceAndCurrencySymbol(
                price: Double(productOrder.total) ?? (productOrder.price * Double(productOrder.quantity)),
                currency: "$",
                currencyPosition: "left"
            ))
                .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.top, 3)
        }
    }
}

struct HistoryOrderProductItemView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderProductItemView()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
