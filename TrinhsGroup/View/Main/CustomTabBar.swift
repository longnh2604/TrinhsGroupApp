//
//  CustomTabBar.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            TabBarItem(icon: "house", title: L10n.Tab.home, index: 0, selectedTab: $selectedTab)
            TabBarItem(icon: "square.grid.2x2", title: L10n.Tab.menu, index: 1, selectedTab: $selectedTab)
            ordersButton
            TabBarItem(icon: "heart", title: L10n.Tab.favorites, index: 3, selectedTab: $selectedTab)
            TabBarItem(icon: "person", title: L10n.Tab.profile, index: 4, selectedTab: $selectedTab)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }

    /// Raised centre button. It used to show `fork.knife`, which reads as "food" while the
    /// destination is the order list.
    private var ordersButton: some View {
        Button(action: { selectedTab = 2 }) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .foregroundColor(.red)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 4)
                    Image(systemName: "list.bullet.clipboard.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                }
                .offset(y: -18)

                Text(L10n.Tab.orders.localizedKey)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(selectedTab == 2 ? .red : .gray)
                    .offset(y: -14)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityAddTraits(selectedTab == 2 ? [.isButton, .isSelected] : .isButton)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let index: Int
    @Binding var selectedTab: Int

    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title.localizedKey)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(selectedTab == index ? .red : .gray)
            .frame(maxWidth: .infinity)
        }
        .accessibilityAddTraits(selectedTab == index ? [.isButton, .isSelected] : .isButton)
    }
}
