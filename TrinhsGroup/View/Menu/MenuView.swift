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
                // Check if there's a category to navigate to (from HomeView)
                if let categoryToNavigate = mainViewModel.categoryToNavigate {
                    selectedCategory = categoryToNavigate
                    mainViewModel.selectedCategory = categoryToNavigate
                    mainViewModel.onFetchSelectedCategoryProducts(id: categoryToNavigate.id)
                    // Clear the navigation trigger after processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        mainViewModel.categoryToNavigate = nil
                    }
                } else if let first = mainViewModel.categories.first {
                    selectedCategory = first
                    mainViewModel.onFetchSelectedCategoryProducts(id: first.id)
                }
            }
            .onChange(of: mainViewModel.categoryToNavigate) { category in
                // Handle category navigation from HomeView
                if let category = category {
                    selectedCategory = category
                    mainViewModel.selectedCategory = category
                    mainViewModel.onFetchSelectedCategoryProducts(id: category.id)
                    // Clear the navigation trigger after processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        mainViewModel.categoryToNavigate = nil
                    }
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

                            OptimizedKFImage(
                                url: category.image.flatMap { image in URL(string: image.src) },
                                width: 60,
                                height: 60,
                                contentMode: .fill,
                                cornerRadius: 30,
                                placeholder: Image(AppAssets.noimage)
                            )
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
