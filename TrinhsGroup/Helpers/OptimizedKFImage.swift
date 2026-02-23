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
    
    var body: some View {
        Group {
            if let url = url {
                KFImage(url)
                    .placeholder {
                        if let placeholder = placeholder {
                            placeholder
                                .resizable()
                                .aspectRatio(contentMode: contentMode)
                                .foregroundColor(.gray.opacity(0.3))
                        } else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    .cacheMemoryOnly(false) // Use disk cache for better performance
                    .fade(duration: 0.2) // Smooth fade transition
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

