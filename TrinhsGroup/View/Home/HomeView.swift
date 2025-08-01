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
                                            ProductCard(product: product) { selectedProduct in
                                                mainViewModel.add(item: selectedProduct)
                                            }
                                            .onTapGesture {
                                                mainViewModel.selectedProduct = product
                                                mainViewModel.presentedType = .productDetail
                                            }
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
