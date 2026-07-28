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
    /// How to dismiss. `nil` keeps the original behaviour — clearing
    /// `showHistoryOrderDetail`, which is what MyOrdersView's overlay is driven by.
    /// The in-app notification list passes its own closure instead, because it presents
    /// this view from a different piece of state.
    var onClose: (() -> Void)? = nil

    /// The order as the view model currently knows it, so a status change arriving while
    /// this screen is open re-renders the progress card instead of showing a stale stage.
    private var liveOrder: Order {
        historyViewModel.orders.first(where: { $0.id == order.id }) ?? order
    }

    fileprivate func NavigationBarView() -> some View {
        HStack {
            Button(action: {
                if let onClose {
                    onClose()
                } else {
                    historyViewModel.showHistoryOrderDetail = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Constants.AppColor.shadowColor.opacity(0.6), radius: 4, x: 0, y: 2)
            }
            .padding(.leading, 16)

            Spacer()
        }
        .frame(height: 44)
        .overlay(
            Text(L10n.Profile.orderDetail.localizedKey)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 16))
                .foregroundColor(Constants.AppColor.primaryBlack)
            , alignment: .center
        )
    }

    var body: some View {
        ZStack {
            Constants.AppColor.lightGrayColor
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                NavigationBarView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        OrderProgressCard(
                            order: liveOrder,
                            events: historyViewModel.statusHistory
                        )

                        HistoryOrderItemsView(order: liveOrder)

                        HistoryOrderDetailPaymentView(order: liveOrder)

                        if !liveOrder.customerNote.isEmpty {
                            HistoryOrderNoteView(order: liveOrder)
                        }

                        HistoryOrderAddressView(order: liveOrder)

                        CancelOrderButton(order: liveOrder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            if authViewModel.user.id > 0 {
                historyViewModel.fetchOrders(customerId: authViewModel.user.id)
            }
            historyViewModel.loadStatusHistory(orderID: order.id)
        }
    }
}

// MARK: - Card chrome

/// One titled white card, so every section of this screen shares the same chrome as
/// `OrderProgressCard`.
struct OrderDetailCard<Content: View>: View {

    let title: String
    var icon: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "98A2B3"))
                }
                Text(title)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 11))
                    .foregroundColor(Color(hex: "98A2B3"))
                    .tracking(0.8)
                Spacer(minLength: 0)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
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
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.08))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .padding(.top, 4)
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
