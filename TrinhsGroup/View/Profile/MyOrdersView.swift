//
//  MyOrdersView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct MyOrdersView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @State var selectedOrder: Order = Order.default
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HomeNavigationBarView(title: "Menu", showNotificationIcon: false)
                        .environmentObject(mainViewModel)
                    
                    List {
                        ForEach(historyViewModel.orders) { order in
                            OrderHistoryItemView(order: order)
                                .padding(.horizontal)
                                .padding(.bottom)
                                .environmentObject(mainViewModel)
                                .onTapGesture {
                                    withAnimation(.easeOut){
                                        selectedOrder = order
                                        historyViewModel.showHistoryOrderDetail.toggle()
                                    }
                                }
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .refreshable {
                        historyViewModel.fetchOrders(customerId: authViewModel.user.id)
                    }
                    .padding(.top)
                }
                
                if historyViewModel.showLoading {
                    LoadingView().ignoresSafeArea()
                }
                
                if historyViewModel.showHistoryOrderDetail {
                    HistoryOrderDetailView(order: selectedOrder)
                        .environmentObject(historyViewModel)
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct MyOrdersView_Previews: PreviewProvider {
    static var previews: some View {
        MyOrdersView()
    }
}
