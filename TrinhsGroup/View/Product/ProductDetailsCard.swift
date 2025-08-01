//
//  ProductDetailsCard.swift
//  TrinhsGroup
//
//  Created by LongNH8 on 1/8/25.
//

import SwiftUI
import Kingfisher

struct ProductDetailsCard: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State var product: Product
    @State var index = 0
    @State private var isAdded = false
    
    var topInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }
    
    fileprivate func ImageSlider() -> some View {
        return PagingView(index: $index.animation(), maxIndex: product.images.count - 1) {
            ForEach(product.images) { image in
                KFImage(URL(string:image.src))
                    .resizable()
                    .scaledToFill()
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
    }
    
    fileprivate func AddToCartButton() -> some View {
        Button(action: {
            withAnimation(.spring()){
                var newPrice = product.price
                firestoreManager.productAddOns.forEach { addon in
                    if addon.checked {
                        product.meta_data.append(ProductMetaData(id: addon.id, key: addon.content, value: .string(String(addon.value))))
                        newPrice += Double(addon.value)
                    }
                }
                product.price = Double(newPrice)
                product.regular_price = Double(newPrice)
                product.meta_data = product.meta_data.filter({ return !$0.key.contains("_") })
                mainViewModel.add(item: product)
            }
            // Animation trigger
            withAnimation {
                isAdded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    isAdded = false
                }
            }
        }) {
            HStack(spacing: 8) {
                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(isAdded ? "Added!" : "Add To Cart")
                    .font(.custom(Constants.AppFont.boldFont, size: 18))
                    .foregroundColor(.white)
                    .animation(.easeInOut(duration: 0.2), value: isAdded)
            }
            .frame(height: 70)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color("ColorPrimary"))
            .cornerRadius(14)
        }
        .padding(.horizontal, 0)
        .shadow(color: Color.black.opacity(0.1), radius: 6, y: 2)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    ZStack {
                        Constants.AppColor.lightGrayColor
                            .edgesIgnoringSafeArea(.all)
                        VStack(alignment: .leading) {
                            ImageSlider()

                            VStack(alignment: .leading) {
                                HStack {
                                    Text(product.short_description.decodingHTMLEntities())
                                        .font(.custom(Constants.AppFont.semiBoldFont, size: 18))
                                        .foregroundColor(Constants.AppColor.secondaryBlack)
                                    Spacer(minLength: 10)
                                }
                                .padding([.horizontal], 15)
                                .padding(.top, 8)

                                Text(product.name)
                                    .font(.custom(Constants.AppFont.extraBoldFont, size: 16))
                                    .foregroundColor(Constants.AppColor.secondaryBlack)
                                    .lineLimit(nil)
                                    .padding([.horizontal], 15)
                                    .padding(.top, -5)
                                    .padding(.bottom, 5)

                                HStack {
                                    if product.sale_price > 0 {
                                        Text(getPriceAndCurrencySymbol(price: product.sale_price, currency: "$", currencyPosition: "right"))
                                            .font(.custom(Constants.AppFont.boldFont, size: 16))
                                            .foregroundColor(Constants.AppColor.secondaryBlack)
                                        Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                                            .font(.custom(Constants.AppFont.regularFont, size: 15))
                                            .foregroundColor(.gray) .strikethrough()
                                        Text(getDiscountPercentage(regularPrice: product.regular_price, salePrice: product.sale_price))
                                            .font(.custom(Constants.AppFont.regularFont, size: 15))
                                            .foregroundColor(Constants.AppColor.secondaryRed)
                                    } else {
                                        Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                                            .font(.custom(Constants.AppFont.boldFont, size: 16))
                                            .foregroundColor(Constants.AppColor.secondaryBlack)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.bottom, 8)
                                .padding(.horizontal, 15)
                            }
                            .background(Color.white)
                            .padding(.bottom, 5)
                            
                            VStack(alignment: .leading) {
                                ForEach(firestoreManager.productAddOns.indices, id:\.self) { index in
                                    HStack {
                                        CheckBoxView(checked: $firestoreManager.productAddOns[index].checked)
                                        Text("\(firestoreManager.productAddOns[index].content)")
                                        if firestoreManager.productAddOns[index].value > 0 {
                                            Text("(+\(getPriceAndCurrencySymbol(price: Double(firestoreManager.productAddOns[index].value), currency: "$", currencyPosition: "right")))")
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.bottom, 5)
                            .background(Color.white)

                            VStack(alignment: .leading) {
                                Text("Product Details")
                                    .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                                    .foregroundColor(Constants.AppColor.secondaryBlack)
                                    .padding(.top, 10)
                                    .padding(.horizontal, 15)
                                
                                Text(product.description.decodingHTMLEntities())
                                    .font(.custom(Constants.AppFont.lightFont, size: 13))
                                    .foregroundColor(Constants.AppColor.secondaryBlack)
                                    .padding(.vertical, 8)
                                    .lineSpacing(2)
                                    .padding(.horizontal, 15)
                                    .lineLimit(nil)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(Color.white)
                            .padding(.top, -3)
                        }
                    }
                }
                
                AddToCartButton()
            }
            .padding(.top, topInset)
            
            // Close button at top right
            Button(action: {
                mainViewModel.presentedType = .none
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            .padding(.top, topInset + 8)
            .padding(.trailing, 8)
        }
        .onAppear {
            if let id = product.categories.first?.id {
                firestoreManager.fetchProductAddOns(categoryId: id)
            }
        }
    }
}
