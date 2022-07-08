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
    @State var selected = 0
    
    init() {
        UITabBar.appearance().backgroundColor = .white
    }
    
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)
            
            TabView(selection: $selected) {
                HomeView()
                    .environmentObject(mainViewModel)
                    .environmentObject(firestoreManager)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }.tag(0)
                
                CategoryView()
                    .environmentObject(mainViewModel)
                    .tabItem {
                        Image(systemName: "cart.fill")
                        Text("Category")
                    }.tag(1)
                
                FavoriteView()
                    .environmentObject(mainViewModel)
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Favorite")
                    }.tag(2)
                
                ProfileView()
                    .environmentObject(authViewModel)
                    .environmentObject(historyViewModel)
                    .environmentObject(mainViewModel)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }.tag(3)
                
                SettingView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Setting")
                    }.tag(4)
            }
            
            if mainViewModel.showNewSeason {
                SaleProductsView()
                    .environmentObject(mainViewModel)
            }
            
            if mainViewModel.showDiscount {
                DiscountProductsView()
                    .environmentObject(mainViewModel)
            }
            
            if mainViewModel.showCart {
                CartView().environmentObject(mainViewModel)
            }
            
            if mainViewModel.showCheckout {
                CheckOutView()
                    .environmentObject(mainViewModel)
                    .environmentObject(authViewModel)
            }
//            
//            if mainViewModel.showOrderReceived {
//                OrderReceivedView()
//                    .environmentObject(mainViewModel)
//            }
            
            if mainViewModel.showLoading {
                LoadingView().ignoresSafeArea()
            }
        }
        .accentColor(Color("ColorPrimary"))
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear(){
//            mainViewModel.fetchSliders()
            mainViewModel.fetchCategories()
//            mainViewModel.fetchProducts()
//            authViewModel.getUser()
//            historyViewModel.fetchOrders(customerId: authViewModel.id)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
