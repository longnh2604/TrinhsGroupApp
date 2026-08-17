//
//  HistoryOrderNoteView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderNoteView: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.Profile.note.localized.uppercased(),
            icon: "text.bubble"
        ) {
            Text(order.customerNote)
                .font(.custom(Constants.AppFont.regularFont, size: 14))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HistoryOrderNoteView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderNoteView(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
