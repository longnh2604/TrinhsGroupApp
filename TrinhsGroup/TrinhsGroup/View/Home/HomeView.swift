//
//  HomeView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

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
                    HomeNavigationBarView(showNotifications: $showNotifications)
                        .environmentObject(mainViewModel)
                    ScrollView {
                        VStack {
                            if mainViewModel.sliders.count != 0 {
                                ImageSliderView()
                                    .environmentObject(mainViewModel)
                            }
                            SaleView()
                                .environmentObject(mainViewModel)
                            DiscountView()
                                .environmentObject(mainViewModel)
                            
                            Spacer()
                        }
                    }.edgesIgnoringSafeArea(.top)
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
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
