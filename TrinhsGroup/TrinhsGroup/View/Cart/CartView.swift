//
//  CartView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI
import Kingfisher

struct CartView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    init() {
        UITableView.appearance().separatorStyle = .none
    }
    
    @State var isShowPromoCodeView : Bool = false
    var discount = 0
    var deliveryCharges = 0
    
    fileprivate func CheckOutButton() -> some View {
        Button(action: {
            mainViewModel.presentedType = .checkOut
        }) {
            Text("")
                .font(.custom(Constants.AppFont.boldFont, size: 15))
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Color("ColorPrimary"))
                .cornerRadius(0)
        }
        .padding(.horizontal, 0)
        .overlay(
            Text("Checkout")
                .font(.custom(Constants.AppFont.boldFont, size: 15))
                .foregroundColor(.white)
                .padding()
        )
    }
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                mainViewModel.presentedType = .none
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
            Text("My Cart")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
                .background(Color.clear)
            , alignment: .center)
    }
    
    var line: some View {
        VStack {
            Divider()
        }
        .padding(.horizontal, 0)
    }
    
    fileprivate func ApplyCoupon() -> some View {
        return Button(action: {
            mainViewModel.onListCoupons(id: authViewModel.user.id)
            self.isShowPromoCodeView.toggle()
        }) {
            HStack {
                Image("offer")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(.leading, 15)
                    .foregroundColor(Constants.AppColor.primaryBlack)
                
                Text(mainViewModel.coupon.id != Coupon.default.id ? mainViewModel.coupon.code ?? "" : "APPLY COUPON")
                    .font(.custom(Constants.AppFont.regularFont, size: 13))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .padding(.trailing, 15)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .background(Color.white)
            .sheet(isPresented: $isShowPromoCodeView) {
                CouponView().environmentObject(mainViewModel)
        }
    }
    
    var body: some View {
        
        NavigationView {
            
            VStack {
                NavigationBarView()
                
                ZStack {
                    Constants.AppColor.lightGrayColor
                    
                    ScrollView {
                        ZStack(alignment: .top) {
                            VStack {
                                ScrollView(.vertical, showsIndicators: false, content: {
                                    ForEach(Array(mainViewModel.items.enumerated()), id: \.offset) { index, element in
                                        ItemCellTypeThree(product: element)
                                            .padding()
                                            .environmentObject(mainViewModel)
                                    }
                                })
                                    .padding(.bottom, 10)
                                
                                ApplyCoupon()
                                
                                VStack {
                                    HStack {
                                        Text("Item Total")
                                            .font(.custom(Constants.AppFont.regularFont, size: 13))
                                            .foregroundColor(Constants.AppColor.secondaryBlack)
                                        Spacer()
                                        Text(getPriceAndCurrencySymbol(price: String(format: "%.2f", mainViewModel.regularPriceTotal), currency: "$", currencyPosition: "right"))
                                            .font(.custom(Constants.AppFont.boldFont, size: 13))
                                            .foregroundColor(Constants.AppColor.secondaryBlack)
                                    }
                                    .padding(.top, 25)
                                    .padding(.horizontal, 15)
                                    
                                    HStack {
                                        Text("Discount")
                                            .font(.custom(Constants.AppFont.regularFont, size: 13))
                                            .foregroundColor(Constants.AppColor.secondaryBlack)
                                        Spacer()
                                        Text("\(mainViewModel.discounts > 0 ? "-" : "")")
                                            .font(.custom(Constants.AppFont.boldFont, size: 13))
                                            .foregroundColor(Color.init(hex: "036440"))
                                        +
                                        Text("\(getPriceAndCurrencySymbol(price: String(format: "%.2f", mainViewModel.discounts), currency: "$", currencyPosition: "right"))")
                                            .font(.custom(Constants.AppFont.boldFont, size: 13))
                                            .foregroundColor(Color.init(hex: "036440"))
                                    }
                                    .padding(.top, 10)
                                    .padding(.horizontal, 15)
                                    
                                    line.padding(10)
                                    
                                    HStack {
                                        Text("Total Amount")
                                            .font(.custom(Constants.AppFont.boldFont, size: 16))
                                            .foregroundColor(Constants.AppColor.secondaryBlack)
                                        Spacer()
                                        Text(getPriceAndCurrencySymbol(price: String(format: "%.2f", mainViewModel.total), currency: "$", currencyPosition: "right"))
                                            .font(.custom(Constants.AppFont.boldFont, size: 16))
                                            .foregroundColor(Constants.AppColor.secondaryBlack)
                                    }
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 10)
                                    
                                    Spacer()
                                }.background(Color.white)
                                    .padding(.top, 10)
                            }
                        }
                    }.padding(.top, 5)
                    Spacer()
                }
                CheckOutButton()
            }.edgesIgnoringSafeArea(.bottom)
                
                .navigationBarTitle(Text(""), displayMode: .inline)
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
        }
    }
}

struct BagView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
    }
}

struct ItemCellTypeThree: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    let product: Product
    
    fileprivate func plusButton() -> some View {
        return Button(action: {
            withAnimation(.spring()){
                mainViewModel.add(item: product)
            }
        }) {
            Image(systemName: "plus")
                .foregroundColor(.gray)
                .frame(width: 25, height: 25)
        }
    }
    
    fileprivate func minusButton() -> some View {
        return Button(action: {
            withAnimation(.spring()){
                mainViewModel.remove(item: product)
            }
        }) {
            Image(systemName: "minus")
                .foregroundColor(.gray)
                .frame(width: 25, height: 25)
        }
    }
    
    var line: some View {
        VStack {
            Divider()
        }
        .padding(.horizontal, 0)
    }
    
    var body: some View {
        
        ZStack() {
            HStack(alignment: .top) {
                Group{
                    if product.images.count > 0 {
                        KFImage(URL(string:product.images[0].src))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }else{
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color("ColorGray"))
                    }
                }
                .frame(width: 90, height: 120)
                .cornerRadius(1)
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text(product.name.decodingHTMLEntities())
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                            .foregroundColor(Constants.AppColor.primaryBlack)
                            .lineLimit(1)
                        Spacer()
                        Button(action: {
                            
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color.init(hex: "bbbbbb"))
                                .padding(.top, 5)
                        }
                    }
                    
                    if product.meta_data.count > 0 {
                        Text ("Addition:")
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                            .foregroundColor(Constants.AppColor.secondaryBlack)
                            .padding(.bottom, 4)
                        
                        ForEach(product.meta_data, id:\.key) { meta in
                            HStack {
                                Text(meta.key)
                                if let value = Int(meta.value.stringValue), value > 0 {
                                    Text("(+\(getPriceAndCurrencySymbol(price: String(value), currency: "$", currencyPosition: "right")))")
                                }
                            }
                            .font(.custom(Constants.AppFont.regularFont, size: 11))
                            .foregroundColor(Constants.AppColor.secondaryBlack)
                        }
                    }
                    
                    HStack {
                        HStack {
                            minusButton()
                            Text("\(product.quantity)")
                                .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                                .foregroundColor(Constants.AppColor.secondaryBlack)
                                .padding(.horizontal, 5)
                            plusButton()
                        }
                        .background(Constants.AppColor.lightGrayColor)
                        .cornerRadius(5)
                        .padding(.bottom, 10)
                        Spacer()
                        Text(getPriceAndCurrencySymbol(price: product.price, currency: "$", currencyPosition: "right"))
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                            .foregroundColor(Constants.AppColor.primaryBlack)
                    }
                    
                }
                .padding(.init(top: 5, leading: 5, bottom: 5, trailing: 0))
                Spacer()
            }
            .overlay(
                line
                    .padding(.top, 10), alignment: .bottom)
                .frame(height: 130)
                .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}
