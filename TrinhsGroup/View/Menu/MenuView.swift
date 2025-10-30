//
//  MenuView.swift
//  TrinhsGroup
//
//  Created by longnh on 2025/04/14.
//

import SwiftUI
import Kingfisher

struct MenuView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State private var selectedCategory: Category = Category.default
    @State private var searchText: String = ""
    
    private func filteredProducts() -> [Product] {
        if searchText.isEmpty {
            return mainViewModel.categoryProducts.filter { $0.categories.first?.id == selectedCategory.id }
        } else {
            return mainViewModel.products.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.AppColor.lightGrayColor
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HomeNavigationBarView(title: "Menu", showNotificationIcon: false)
                        .environmentObject(mainViewModel)
                    
//                    HStack {
//                        TextField("Search...", text: $searchText)
//                            .padding(10)
//                            .background(Color(.systemGray6))
//                            .cornerRadius(16)
//                    }
//                    .padding(.horizontal)
//                    .padding(.bottom, 8)
                    
                    // Category Selector
                    CategorySelectorView(selectedCategory: $selectedCategory, categories: mainViewModel.categories)
                    
                    // Filtered Products
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredProducts()) { product in
                                ProductCard(product: product) { selectedProduct in
                                    mainViewModel.add(item: selectedProduct)
                                }
                                .onTapGesture {
                                    mainViewModel.selectedProduct = product
                                    mainViewModel.presentedType = .productDetail
                                }
                            }
                        }
                    }
                }
                
                if mainViewModel.isCategoryProductsLoading {
                    LoadingView().ignoresSafeArea()
                }
            }
            .onAppear {
                if let first = mainViewModel.categories.first {
                    selectedCategory = first
                    mainViewModel.onFetchSelectedCategoryProducts(id: first.id)
                }
            }
            .onChange(of: selectedCategory) { newValue in
                mainViewModel.onFetchSelectedCategoryProducts(id: newValue.id)
            }
        }
    }
}

struct CategorySelectorView: View {
    @Binding var selectedCategory: Category
    var categories: [Category]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { category in
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(selectedCategory.id == category.id ? Color.red : Color.clear, lineWidth: 3)
                                .frame(width: 66, height: 66)

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
                        }
                        .padding(.top, 8)

                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(selectedCategory.id == category.id ? .red : .primary)
                    }
                    .padding(.vertical, 8)
                    .onTapGesture {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
