//
//  CustomTabBar.swift
//  TrinhsGroup
//
//  Created by longnh on 2025/04/11.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            TabBarItem(icon: "house", index: 0, selectedTab: $selectedTab)
            TabBarItem(icon: "square.grid.2x2", index: 1, selectedTab: $selectedTab)

            ZStack {
                Circle()
                    .foregroundColor(.red)
                    .frame(width: 60, height: 60)
                    .offset(y: -20)
                    .shadow(radius: 4)
                Image(systemName: "fork.knife")
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
                    .offset(y: -20)
            }
            .onTapGesture {
                selectedTab = 2
            }

            TabBarItem(icon: "heart", index: 3, selectedTab: $selectedTab)
            TabBarItem(icon: "person", index: 4, selectedTab: $selectedTab)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }
}

struct TabBarItem: View {
    let icon: String
    let index: Int
    @Binding var selectedTab: Int

    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == index ? .red : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
