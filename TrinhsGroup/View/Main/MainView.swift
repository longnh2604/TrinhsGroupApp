//
//  MainView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager

    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            Constants.AppColor.lightGrayColor
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                content(for: selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.keyboard)
                
                Spacer()

                CustomTabBar(selectedTab: $selectedTab)
            }

            overlayPresentedView()
            loadingOverlay()
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // Initial bootstrapping - only run once
            authViewModel.onGetUser()
            mainViewModel.onFetchCategories()
            mainViewModel.onFetchPopularProducts()
        }
        .onChange(of: selectedTab) { newValue in
            // Reset Profile navigation when leaving Profile tab
            if newValue != 4 {
                authViewModel.showEditProfile = false
                authViewModel.showEditAddress = false
                mainViewModel.showOrderReceived = false
            }
            // Also reset order detail overlay when switching tabs
            historyViewModel.showHistoryOrderDetail = false
        }
        .onChange(of: mainViewModel.categoryToNavigate) { category in
            // Navigate to Menu tab (index 1) when category is selected from HomeView
            if category != nil {
                selectedTab = 1
            }
        }
    }
}

// MARK: - Content & Overlays
private extension MainView {
    @ViewBuilder
    func content(for tab: Int) -> some View {
        switch tab {
        case 0:
            HomeView()
        case 1:
            MenuView()
        case 2:
            MyOrdersView(filter: .todayOnly)
        case 3:
            FavoriteView()
        case 4:
            ProfileView()
        default:
            HomeView()
        }
    }

    @ViewBuilder
    func overlayPresentedView() -> some View {
        switch mainViewModel.presentedType {
        case .cart:
            CartView()
                .zIndex(2)
        case .productDetail:
            if let product = mainViewModel.selectedProduct {
                ProductDetailsCard(product: product)
                    .environmentObject(mainViewModel)
                    .environmentObject(firestoreManager)
                    .ignoresSafeArea()
                    .zIndex(2)
            }
        case .checkOut:
            CheckOutView()
                .zIndex(2)
        case .orderReceived:
            OrderReceivedView()
                .zIndex(2)
        case .none, .editUserInfo, .orderHistory:
            EmptyView()
        }
    }

    @ViewBuilder
    func loadingOverlay() -> some View {
        if mainViewModel.showLoading {
            LoadingView()
                .ignoresSafeArea()
        }
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
