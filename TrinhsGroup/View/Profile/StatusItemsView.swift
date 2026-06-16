//
//  StatusItemsView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct StatusItemsView: View {

    var order: Order

    private static let happyPath = ["pending", "on-hold", "processing", "completed"]
    private static let terminalFailures: Set<String> = ["cancelled", "refunded", "failed"]

    var body: some View {
        VStack(alignment: .leading){
            Text(L10n.Profile.orderStatus.localizedKey)
                .fontWeight(.semibold)
                .foregroundColor(Color("ColorPrimary"))

            VStack(alignment: .leading, spacing: 0) {
                if Self.terminalFailures.contains(order.status) {
                    StatusItemView(
                        current: order.status,
                        status: order.status,
                        date: order.dateModified,
                        activeColor: failureColor(for: order.status)
                    )
                } else {
                    ForEach(Self.happyPath, id: \.self) { status in
                        StatusItemView(current: order.status, status: status, date: order.dateModified)
                    }
                }
            }
        }
    }

    private func failureColor(for status: String) -> Color {
        switch status {
        case "refunded": return .orange
        case "cancelled", "failed": return .red
        default: return Color("ColorPrimary")
        }
    }
}

struct StatusItemsView_Previews: PreviewProvider {
    static var previews: some View {
        StatusItemsView(order: Order.default)
            .previewLayout(.sizeThatFits)
    }
}
