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
    @State private var selectedTab = 0
    
    init() {
        UITabBar.appearance().backgroundColor = .white
    }
    
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
            
            if mainViewModel.showLoading {
                LoadingView().ignoresSafeArea()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .onAppear() {
            authViewModel.onGetUser()
            mainViewModel.onFetchCategories()
            mainViewModel.onFetchPopularProducts()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
