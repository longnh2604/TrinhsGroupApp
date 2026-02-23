//
//  MyOrdersView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct MyOrdersView: View {
    enum OrdersFilter {
        case todayOnly
        case pastOnly
    }
    
    var filter: OrdersFilter = .todayOnly
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @State var selectedOrder: Order = Order.default
    
    // Show back button when navigated from Profile (pastOnly filter)
    private var showBackButton: Bool {
        filter == .pastOnly
    }
    
    private var filteredOrders: [Order] {
        let tz = TimeZone(identifier: "Australia/Sydney") ?? .current
        var calendar = Calendar.current
        calendar.timeZone = tz
        guard let todayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) else {
            return historyViewModel.orders
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = tz
        
        func isSameAustralianDay(_ dateString: String) -> Bool {
            guard let date = formatter.date(from: dateString) else { return false }
            return calendar.isDate(date, inSameDayAs: todayStart)
        }
        
        switch filter {
        case .todayOnly:
            return historyViewModel.orders.filter { isSameAustralianDay($0.dateCreated) }
        case .pastOnly:
            return historyViewModel.orders.filter { !isSameAustralianDay($0.dateCreated) }
        }
    }
    
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Custom Navigation Bar with back button for Profile navigation
                if showBackButton {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.body)
                            }
                            .foregroundColor(.accentColor)
                        }
                        
                        Spacer()
                        
                        Text("My Orders")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(hex: "f9f9f9"))
                } else {
                    HomeNavigationBarView(title: "Menu", showNotificationIcon: false)
                        .environmentObject(mainViewModel)
                }
                    
                    if filteredOrders.isEmpty && filter == .todayOnly {
                        // Empty state for today's orders
                        ScrollView {
                            VStack(spacing: 20) {
                                Spacer()
                                    .frame(height: 100)
                                
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                VStack(spacing: 12) {
                                    Text("You don't have any orders today")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("If you'd like to order, don't hesitate to add items to your cart. We're happy and eager to serve you with the best care possible.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .refreshable {
                            historyViewModel.fetchOrders(customerId: authViewModel.user.id)
                        }
                    } else {
                        List {
                            ForEach(filteredOrders) { order in
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
                }
                
                if historyViewModel.showLoading {
                    LoadingView().ignoresSafeArea()
                }
                
            if historyViewModel.showHistoryOrderDetail {
                HistoryOrderDetailView(order: selectedOrder)
                    .environmentObject(historyViewModel)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Fetch orders when entering via bottom tab so the list is populated
            historyViewModel.fetchOrders(customerId: authViewModel.user.id)
            // Always start from list view (not detail overlay)
            historyViewModel.showHistoryOrderDetail = false
        }
    }
}

struct MyOrdersView_Previews: PreviewProvider {
    static var previews: some View {
        MyOrdersView()
    }
}
