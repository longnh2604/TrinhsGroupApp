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
            
            VStack {
                Group {
                    switch selectedTab {
                        case 0: HomeView()
                            .environmentObject(mainViewModel)
                            .environmentObject(firestoreManager)
                        case 1: MenuView()
                            .environmentObject(mainViewModel)
                        case 2: MyOrdersView()
                            .environmentObject(mainViewModel)
                            .environmentObject(authViewModel)
                            .environmentObject(historyViewModel)
                        case 3: FavoriteView()
                            .environmentObject(mainViewModel)
                            .environmentObject(firestoreManager)
                        case 4: ProfileView()
                            .environmentObject(mainViewModel)
                            .environmentObject(authViewModel)
                            .environmentObject(historyViewModel)
                        default: HomeView()
                            .environmentObject(mainViewModel)
                            .environmentObject(firestoreManager)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.keyboard)
                
                CustomTabBar(selectedTab: $selectedTab)
            }
            
            if mainViewModel.presentedType == .cart {
                CartView()
            } else if mainViewModel.presentedType == .productDetail {
                if let product = mainViewModel.selectedProduct {
                    ProductDetailsCard(product: product)
                        .environmentObject(mainViewModel)
                        .environmentObject(firestoreManager)
                        .ignoresSafeArea()
                        .zIndex(2)
                }
            } else if mainViewModel.presentedType == .checkOut {
                CheckOutView()
            }
            
            if mainViewModel.showLoading {
                LoadingView().ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                content(for: selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.keyboard)

                CustomTabBar(selectedTab: $selectedTab)
            }

            overlayPresentedView()
            loadingOverlay()
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // Initial bootstrapping
            authViewModel.onGetUser()
            mainViewModel.onFetchCategories()
            mainViewModel.onFetchPopularProducts()
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
            MyOrdersView()
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
        case .productDetail:
            if let product = mainViewModel.selectedProduct {
                ProductDetailsCard(product: product)
            }
        case .checkOut:
            CheckOutView()
        case .orderReceived:
            OrderReceivedView()
        case .none:
            EmptyView()
        case .editUserInfo:
            EmptyView()
        case .orderHistory:
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
