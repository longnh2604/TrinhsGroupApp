//
//  HistoryOrderDetailView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct HistoryOrderDetailView: View {

    @EnvironmentObject var historyViewModel: HistoryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
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
            Text(L10n.Profile.orderDetail.localizedKey)
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
                            .padding(.bottom, 10)

                        CancelOrderButton(order: order)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                })
                .padding(.top)
            }).zIndex(0)
        }
        .onAppear {
            if authViewModel.user.id > 0 {
                historyViewModel.fetchOrders(customerId: authViewModel.user.id)
            }
        }
    }
}

private struct CancelOrderButton: View {
    var order: Order
    @EnvironmentObject var historyViewModel: HistoryViewModel

    private let cancellableStatuses = ["pending", "on-hold", "processing"]

    var body: some View {
        if cancellableStatuses.contains(order.status) {
            VStack(spacing: 8) {
                Button(role: .destructive) {
                    historyViewModel.showCancelConfirm = true
                } label: {
                    HStack {
                        if historyViewModel.isCancelling {
                            ProgressView()
                                .tint(.red)
                        }
                        Text(historyViewModel.isCancelling ? "Cancelling…" : "Cancel Order")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.08))
                    .foregroundColor(.red)
                    .cornerRadius(10)
                }
                .disabled(historyViewModel.isCancelling)
                .confirmationDialog(
                    "Cancel Order #\(order.number)?",
                    isPresented: $historyViewModel.showCancelConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Yes, Cancel Order", role: .destructive) {
                        historyViewModel.cancelOrder(orderID: order.id)
                    }
                    Button("Keep Order", role: .cancel) {}
                } message: {
                    Text("This cannot be undone.")
                }
            }
        }
    }
}

struct HistoryOrderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderDetailView(order: Order.default)
            .environmentObject(HistoryViewModel())
            .environmentObject(AuthViewModel())
    }
}
