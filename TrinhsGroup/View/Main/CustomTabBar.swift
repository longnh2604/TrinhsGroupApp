//
//  CustomTabBar.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @State private var bottomInset: CGFloat = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            TabBarItem(icon: "house", title: L10n.Tab.home, index: 0, selectedTab: $selectedTab)
            TabBarItem(icon: "square.grid.2x2", title: L10n.Tab.menu, index: 1, selectedTab: $selectedTab)
            ordersButton
            TabBarItem(icon: "heart", title: L10n.Tab.favorites, index: 3, selectedTab: $selectedTab)
            TabBarItem(icon: "person", title: L10n.Tab.profile, index: 4, selectedTab: $selectedTab)
        }
        .padding(.horizontal)
        // Home-indicator devices: sink 40% of the way into the bottom inset, so the labels sit
        // just above the indicator instead of a full inset plus padding off the edge.
        // Home-button devices have no inset, so they keep breathing room above the edge.
        .padding(.bottom, bottomInset > 0 ? -bottomInset * 0.4 : 12)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .background(
            // Must NOT ignore the safe area: a reader that does reports an inset of 0.
            // Re-read on rotation, where the inset changes.
            GeometryReader { proxy in
                Color.clear
                    .onAppear { bottomInset = proxy.safeAreaInsets.bottom }
                    .onChange(of: proxy.safeAreaInsets.bottom) { bottomInset = $0 }
            }
        )
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
                // Negative padding, not offset: the circle still rises above the bar, but the
                // bar no longer reserves that height as dead space under the other tabs.
                .padding(.top, -18)

                Text(L10n.Tab.orders.localizedKey)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(selectedTab == 2 ? .red : .gray)
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
