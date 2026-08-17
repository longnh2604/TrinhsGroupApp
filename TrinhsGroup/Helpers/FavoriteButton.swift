//
//  FavoriteButton.swift
//  TrinhsGroup
//
//  Created by longnh on 2025/10/26.
//

import SwiftUI

struct FavoriteButton: View {
    let isFav: Bool
    let onTap: () -> Void
    
    @State private var animateScale = false
    
    var body: some View {
        Button(action: {
            onTap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0.2)) {
                animateScale = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.2)) {
                    animateScale = false
                }
            }
        }) {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isFav ? .red : .white)
                .padding(10)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
                .scaleEffect(animateScale ? 1.2 : 1.0)
                .shadow(color: Color.black.opacity(0.25), radius: 4, y: 2)
        }
        .accessibilityLabel(Text(isFav ? "Remove from favorites" : "Add to favorites"))
    }
}
