//
//  HistoryOrderDetailView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct HistoryOrderDetailView: View {
    
    @EnvironmentObject var historyViewModel: HistoryViewModel
    var order: Order
    
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                historyViewModel.showHistoryOrderDetail = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .overlay(
            Text("Order Detail")
                .font(.headline)
                .padding(.horizontal, 10)
                .background(Color.init(hex: "f9f9f9"))
            , alignment: .center)
    }
    
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 5, content: {
                // NAVBAR
                NavigationBarView()
                
                // DEATIL BOTTOM PART
                VStack(alignment: .center, spacing: 0, content: {
                    
                    ScrollView(showsIndicators: false){
                        
                        HistoryOrderDetailDetailView(order: order)
                            .padding(.top)

                        Divider()
                            .padding(.vertical)

                        HistoryOrderItemsView(order: order)


                        HistoryOrderDetailPaymentView(order: order)


                        Divider()
                            .padding(.vertical)

                        StatusItemsView(order: order)

                        Divider()
                            .padding(.vertical)

                        HistoryOrderNoteView(order: order)

                        Divider()
                            .padding(.vertical)

                        HistoryOrderAddressView(order: order)
                            .padding(.bottom, 30)
                        
                    }
                    .padding(.horizontal)
                })
                .padding(.top)
            }).zIndex(0)
        }
    }
}

struct HistoryOrderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderDetailView(order: Order.default)
            .environmentObject(HistoryViewModel())
    }
}
