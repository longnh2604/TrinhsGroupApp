//
//  OptimizedKFImage.swift
//  TrinhsGroup
//
//  Created on 2025/01/27.
//

import SwiftUI
import Kingfisher

struct OptimizedKFImage: View {
    let url: URL?
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var contentMode: SwiftUI.ContentMode = .fit
    var cornerRadius: CGFloat = 0
    var placeholder: Image? = nil
    @State private var didFailToLoad = false
    
    var body: some View {
        Group {
            if let url = url, !didFailToLoad {
                KFImage(url)
                    .placeholder {
                        FoodImageLoadingPlaceholder(cornerRadius: cornerRadius)
                            .frame(width: width, height: height)
                    }
                    .cacheMemoryOnly(false) // Use disk cache for better performance
                    .fade(duration: 0.2) // Smooth fade transition
                    .onSuccess { _ in
                        didFailToLoad = false
                    }
                    .onFailure { _ in
                        didFailToLoad = true
                    }
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: width, height: height)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .onAppear {
                        // Preload image to cache
                        preloadImage(url: url)
                    }
            } else {
                if let placeholder = placeholder {
                    placeholder
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: width, height: height)
                        .foregroundColor(.gray.opacity(0.3))
                        .cornerRadius(cornerRadius)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: width, height: height)
                        .cornerRadius(cornerRadius)
                }
            }
        }
    }
    
    // Preload image to cache for faster subsequent loads
    private func preloadImage(url: URL) {
        // Use Kingfisher's built-in prefetching for better performance
        ImagePrefetcher(urls: [url]).start()
    }
}

/// A polished temporary state shown while a remote food image is downloading.
/// The caller's supplied placeholder remains reserved for missing or failed images.
private struct FoodImageLoadingPlaceholder: View {
    let cornerRadius: CGFloat
    @State private var shimmerPosition: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.99, green: 0.95, blue: 0.91), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.24, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.45))

                    Capsule()
                        .fill(Color.red.opacity(0.16))
                        .frame(width: min(proxy.size.width * 0.42, 72), height: 6)
                }

                LinearGradient(
                    colors: [.clear, .white.opacity(0.65), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(24))
                .offset(x: shimmerPosition * (proxy.size.width * 2))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                    shimmerPosition = 1
                }
            }
        }
        .accessibilityLabel("Loading food image")
    }
}
