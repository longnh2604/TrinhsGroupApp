//
//  FavoriteView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct FavoriteView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    
    var body: some View {
        NavigationView {
            VStack {
                HomeNavigationBarView(title: "Favorite", showNotificationIcon: false)
                    .environmentObject(mainViewModel)
                
                ZStack {
                    Constants.AppColor.lightGrayColor
                        .edgesIgnoringSafeArea(.all)
                    
                    contentView // <- moved logic here
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            // Only load from storage if MainViewModel has no favorites
            if mainViewModel.favoriteProducts.isEmpty {
                mainViewModel.loadFavoritesFromStorage()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var contentView: some View {
        if mainViewModel.favoriteProducts.isEmpty {
            emptyStateView
        } else {
            favoritesGridView
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 36, weight: .regular))
                .foregroundColor(.gray)
            Text("No favorites yet")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 16))
                .foregroundColor(.gray)
            Text("Tap the heart on any product to save it here.")
                .font(.custom(Constants.AppFont.lightFont, size: 13))
                .foregroundColor(.gray)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.top, 80)
    }
    
    private var favoritesGridView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: gridLayout, spacing: 15) {
                    ForEach(mainViewModel.favoriteProducts) { product in
                        ItemCellView(product: product)
                            .environmentObject(mainViewModel)
                            .environmentObject(firestoreManager)
                            .onTapGesture {
                                withAnimation(.easeOut) {
                                    mainViewModel.selectedProduct = product
                                    mainViewModel.presentedType = .productDetail
                                }
                            }
                    }
                }
                .padding(15)
                .padding(.bottom, 130)
            }
        }
    }
}
