//
//  OrderDetailCard.swift
//  TrinhsGroup
//
//  The white rounded section used by every order card, on both the confirmation screen and
//  the order history detail screen. Lived inside HistoryOrderDetailView.swift while only one
//  screen used it.
//

import SwiftUI

struct OrderDetailCard<Content: View>: View {

    let title: String
    var icon: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "98A2B3"))
                }
                Text(title)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 11))
                    .foregroundColor(Color(hex: "98A2B3"))
                    .tracking(0.8)
                Spacer(minLength: 0)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
