//
//  ProductCard.swift
//  TrinhsGroup
//
//  Created by LongNH8 on 1/8/25.
//

import SwiftUI
import Kingfisher

// MARK: - Product Card
struct ProductCard: View {
    var product: Product
    let onAdd: (Product) -> Void

    var body: some View {
        HStack {
            if let src = product.images.first?.src, !src.isEmpty, let url = URL(string: src) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .clipped()
            } else {
                Image(AppAssets.noimage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.subheadline)
            }

            Spacer()

            Button(action: {
                var newProduct = product
                newProduct.meta_data = newProduct.meta_data.filter({ return !$0.key.contains("_") })
                onAdd(newProduct)
            }) {
                Text("+ Add")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
    }
}
