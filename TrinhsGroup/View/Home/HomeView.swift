//
//  HomeView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State var showNotifications = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.AppColor.lightGrayColor
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    HomeNavigationBarView(title: "Home", showNotificationIcon: true, showNotifications: $showNotifications)
                        .environmentObject(mainViewModel)
                    
                    ScrollView {
                        VStack {
                            // Promotions
                            VStack(alignment: .leading) {
                                Text("Promotions")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                TabView {
                                    ForEach(0..<3) { _ in
                                        Image(AppAssets.promotions)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .cornerRadius(15)
                                            .padding(.horizontal)
                                    }
                                }
                                .frame(height: 150)
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                            }
                            
                            // Categories
                            VStack(alignment: .leading) {
                                Text("Categories")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(mainViewModel.categories, id: \.id) { category in
                                            VStack {
                                                if let src = category.image?.src, !src.isEmpty, let url = URL(string: src) {
                                                    KFImage(url)
                                                        .resizable()
                                                        .cacheOriginalImage()
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(Circle())
                                                } else {
                                                    Image(AppAssets.noimage)
                                                        .resizable()
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(Circle())
                                                }
                                                
                                                Text(category.name)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Popular
                            if !mainViewModel.popularProducts.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Popular")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    VStack(spacing: 16) {
                                        ForEach(mainViewModel.popularProducts, id: \.id) { product in
                                            ProductCard(product: product)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            Spacer()
                        }
                    }.edgesIgnoringSafeArea(.top)
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showNotifications, content: {
            NewNotificationsView()
        })
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product

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
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", 4.5))
                }
                .font(.caption)
                .foregroundColor(.gray)
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.subheadline)
            }

            Spacer()

            Button(action: {}) {
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
