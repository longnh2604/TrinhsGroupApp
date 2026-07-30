//
//  CartView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI
import Kingfisher

struct CartView: View {
    @EnvironmentObject var mainViewModel: MainViewModel

    init() {
        UITableView.appearance().separatorStyle = .none
    }

    @State var showMondayAlert: Bool = false

    /// Check if today is Monday in Australia timezone
    private func isMondayInAustralia() -> Bool {
        let tz = TimeZone(identifier: "Australia/Sydney") ?? .current
        var calendar = Calendar.current
        calendar.timeZone = tz
        let weekday = calendar.component(.weekday, from: Date())
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        return false
        return weekday == 2
    }

    private var isCartEmpty: Bool {
        mainViewModel.items.isEmpty
    }

    fileprivate func CheckOutButton() -> some View {
        Button(action: {
            // Check if today is Monday in Australia
            if isMondayInAustralia() {
                showMondayAlert = true
            } else {
                mainViewModel.presentedType = .checkOut
            }
        }) {
            HStack {
                Text("Checkout")
                    .font(.custom(Constants.AppFont.boldFont, size: 16))
                    .foregroundColor(.white)
                Spacer()
                Text(getPriceAndCurrencySymbol(price: mainViewModel.total, currency: "$", currencyPosition: "left"))
                    .font(.custom(Constants.AppFont.boldFont, size: 16))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color("ColorPrimary"))
            .cornerRadius(16)
            .shadow(color: Color("ColorPrimary").opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .alert("Notice", isPresented: $showMondayAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We sincerely apologize and thank you for your understanding. We are closed on Mondays. We appreciate your understanding and hope you will continue to support us on other days of the week.")
        }
    }

    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                mainViewModel.presentedType = .none
            }) {
                Image(systemName: "arrow.left")
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
            VStack(spacing: 1) {
                Text("My Cart")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 16))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                if !isCartEmpty {
                    Text("\(mainViewModel.numberOfItems) item\(mainViewModel.numberOfItems > 1 ? "s" : "")")
                        .font(.custom(Constants.AppFont.regularFont, size: 11))
                        .foregroundColor(.gray)
                }
            }
            , alignment: .center)
    }

    fileprivate func EmptyCartView() -> some View {
        VStack(spacing: 12) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color("ColorPrimary").opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "cart")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundColor(Color("ColorPrimary"))
            }
            .padding(.bottom, 8)

            Text("Your cart is empty")
                .font(.custom(Constants.AppFont.boldFont, size: 18))
                .foregroundColor(Constants.AppColor.primaryBlack)

            Text("Looks like you haven't added\nanything to your cart yet.")
                .font(.custom(Constants.AppFont.regularFont, size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                mainViewModel.presentedType = .none
            }) {
                Text("Browse Menu")
                    .font(.custom(Constants.AppFont.boldFont, size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .frame(height: 48)
                    .background(Color("ColorPrimary"))
                    .cornerRadius(14)
            }
            .padding(.top, 16)

            Spacer()
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }

    fileprivate func summaryRow(title: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(title)
                .font(.custom(Constants.AppFont.regularFont, size: 14))
                .foregroundColor(Constants.AppColor.secondaryBlack)
            Spacer()
            Text(value)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                .foregroundColor(valueColor)
        }
    }

    fileprivate func OrderSummaryView() -> some View {
        VStack(spacing: 14) {
            summaryRow(title: "Item Total",
                       value: getPriceAndCurrencySymbol(price: mainViewModel.regularPriceTotal, currency: "$", currencyPosition: "left"),
                       valueColor: Constants.AppColor.secondaryBlack)

            if mainViewModel.discounts > 0 {
                summaryRow(title: "Discount",
                           value: "-" + getPriceAndCurrencySymbol(price: mainViewModel.discounts, currency: "$", currencyPosition: "left"),
                           valueColor: Color.init(hex: "036440"))
            }

            Divider()

            HStack {
                Text("Total Amount")
                    .font(.custom(Constants.AppFont.boldFont, size: 16))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                Spacer()
                Text(getPriceAndCurrencySymbol(price: mainViewModel.total, currency: "$", currencyPosition: "left"))
                    .font(.custom(Constants.AppFont.boldFont, size: 16))
                    .foregroundColor(Color("ColorPrimary"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Constants.AppColor.shadowColor.opacity(0.5), radius: 8, x: 0, y: 2)
    }

    var body: some View {

        NavigationView {

            VStack(spacing: 0) {
                NavigationBarView()

                if isCartEmpty {
                    EmptyCartView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(Array(mainViewModel.items.enumerated()), id: \.offset) { index, element in
                                ItemCellTypeThree(product: element)
                                    .environmentObject(mainViewModel)
                            }

                            OrderSummaryView()
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }

                    CheckOutButton()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.AppColor.lightGrayColor.ignoresSafeArea())

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
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Color("ColorPrimary"))
                .clipShape(Circle())
        }
    }

    fileprivate func minusButton() -> some View {
        return Button(action: {
            withAnimation(.spring()){
                mainViewModel.remove(item: product)
            }
        }) {
            Image(systemName: "minus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .frame(width: 26, height: 26)
                .background(Constants.AppColor.lightGrayColor)
                .clipShape(Circle())
        }
    }

    var body: some View {

        HStack(alignment: .top, spacing: 12) {
            OptimizedKFImage(
                url: product.images.first.flatMap { image in URL(string: image.src) },
                width: 80,
                height: 80,
                contentMode: .fill,
                cornerRadius: 12,
                placeholder: Image(systemName: "photo")
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(product.name.decodingHTMLEntities())
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                        .lineLimit(2)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()){
                            mainViewModel.removeAll(item: product)
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(Color.init(hex: "bbbbbb"))
                    }
                }

                // Display product note separately if exists
                if let noteMeta = product.meta_data.first(where: { $0.key == "_note" }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Note:")
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 12))
                            .foregroundColor(Constants.AppColor.secondaryBlack)
                        Text(noteMeta.value.stringValue)
                            .font(.custom(Constants.AppFont.regularFont, size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(3)
                    }
                }

                // The chosen add-ons, read from the choices rather than from meta_data. The old
                // meta entries keyed the line by the group label ("Addition") and bought
                // nothing; each choice now names its own group, so "1st Pho: Beef" reads the
                // way the kitchen ticket does.
                if !product.addOnChoices.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(product.addOnChoices.enumerated()), id: \.offset) { _, choice in
                            HStack(spacing: 4) {
                                Text(choice.groupTitle.isEmpty
                                     ? choice.label
                                     : "\(choice.groupTitle): \(choice.label)")
                                if choice.price != 0 {
                                    Text("(" + (choice.price < 0 ? "-" : "+")
                                         + getPriceAndCurrencySymbol(price: abs(choice.price), currency: "$", currencyPosition: "left")
                                         + ")")
                                }
                            }
                            .font(.custom(Constants.AppFont.regularFont, size: 11))
                            .foregroundColor(.gray)
                        }
                    }
                }

                HStack {
                    HStack(spacing: 10) {
                        minusButton()
                        Text("\(product.quantity)")
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                            .foregroundColor(Constants.AppColor.primaryBlack)
                            .frame(minWidth: 18)
                        plusButton()
                    }
                    Spacer()
                    // unitPrice, not price: the add-ons used to be folded into `price` itself,
                    // and this line has to keep including them now that they no longer are.
                    Text(getPriceAndCurrencySymbol(price: product.unitPrice, currency: "$", currencyPosition: "left"))
                        .font(.custom(Constants.AppFont.boldFont, size: 15))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Constants.AppColor.shadowColor.opacity(0.5), radius: 8, x: 0, y: 2)
    }
}
