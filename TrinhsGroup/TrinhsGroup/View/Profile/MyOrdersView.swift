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
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                withAnimation(.spring()){
                    historyViewModel.showHistory.toggle()
                }
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 35)
        .overlay(
            Text("My Orders")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
                .background(Color.clear)
            , alignment: .center)
    }
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    NavigationBarView()
                    
                    ScrollView(showsIndicators: false){
                        ForEach(historyViewModel.orders){ order in
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
                    }
                    .padding(.top)
                    
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
