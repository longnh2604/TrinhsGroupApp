//
//  CheckOutView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct CheckOutView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    fileprivate func SubmitButton() -> some View {
        Button(action: {
            if !authViewModel.checkUserUpdatedBillInfo() { return }
            
            if mainViewModel.selectedPayment.id == Payment.default.id {
//                mainViewModel.dialogMessage = "Please select payment method"
//                mainViewModel.showDialog.toggle()
                return
            }
            
            var productOrders = [ProductOrder]()

            for order_item in mainViewModel.items {
                productOrders.append(ProductOrder(id: 0, product_id: order_item.id, name: order_item.name, quantity: order_item.quantity, subtotal: "", total: "", price: 0))
            }

//            var shippingOrders = [ShippingOrder]()
//            shippingOrders.append(ShippingOrder(method_id: mainViewModel.selectedShip.method_id, total: mainViewModel.selectedShip.settings.cost.value))

            mainViewModel.onCreateOrder(user: authViewModel.user,productOrders: productOrders)
        }) {
            Text("Submit Order")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Color("ColorPrimary"))
                .cornerRadius(25)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                self.mainViewModel.presentedType = .cart
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .overlay(
            Text("Checkout")
                .font(.headline)
                .padding(.horizontal, 10)
                .background(Color.init(hex: "f9f9f9"))
            , alignment: .center)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    NavigationBarView()
                    ScrollView {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Delivery Option")
                                    .font(.headline)
                                Spacer(minLength: 20)
                            }
                            .padding(.top, 5)
                            
                            ZStack(alignment: .top) {
                                Rectangle()
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                                    .shadow(color: Color.init(hex: "dddddd"), radius: 2, x: 0.8, y: 0.8)
                                VStack(alignment: .leading, spacing: 10){
                                    ForEach(mainViewModel.shipMethods) { item in
                                        ShippingItemView(item: item).environmentObject(mainViewModel)
                                    }
                                }
                                .padding(5)
                            }
                            
                            HStack {
                                Text("Select Payment")
                                    .font(.headline)
                                Spacer(minLength: 20)
                            }
                            .padding(.top, 10)
                            
                            ZStack(alignment: .top) {
                                Rectangle()
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                                    .shadow(color: Color.init(hex: "dddddd"), radius: 2, x: 0.8, y: 0.8)
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(mainViewModel.payments.filter({ $0.enabled == true}), id: \.self) { item in
                                        PaymentItemView(item: item)
                                            .environmentObject(mainViewModel)
                                    }
                                    if mainViewModel.selectedPayment.description != "" {
                                        Text(mainViewModel.selectedPayment.description)
                                            .multilineTextAlignment(.leading)
                                            .padding(.horizontal, 10).fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(5)
                            }
                            
                            HStack {
                                Text("Order:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(getPriceAndCurrencySymbol(price: String(mainViewModel.subtotal), currency: "$", currencyPosition: "right"))
                                    .bold()
                            }.padding(.top, 30)
                            
//                            HStack {
//                                Text("Delivery Charges:")
//                                    .foregroundColor(.gray)
//                                Spacer()
//                                Text(getPriceAndCurrencySymbol(price: mainViewModel.selectedShip.settings.cost.value, currency: "$", currencyPosition: "right"))
//                                    .bold()
//                            }.padding(.top, 15)
                            
                            HStack {
                                Text("Total:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(getPriceAndCurrencySymbol(price: String(mainViewModel.total), currency: "$", currencyPosition: "right"))
                                    .bold()
                            }.padding(.top, 15)
                            Spacer()
                        }.padding(15)
                    }
                    SubmitButton()
                }
                if mainViewModel.showLoading {
                    LoadingView().ignoresSafeArea()
                }
                if !authViewModel.message.isEmpty {
                    CustomAlertView(message: authViewModel.message)
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear(){
                mainViewModel.fetchPayments()
                mainViewModel.fetchZones()
            }
        }
    }
}

struct CheckOutView_Previews: PreviewProvider {
    static var previews: some View {
        CheckOutView()
    }
}
