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
    @State private var isFavorite: Bool = false
    @State var product: Product
    @State var index = 0
    @State private var isAdded = false
    @State private var productNote: String = ""
    @State private var noteHeight: CGFloat = 60
    @FocusState private var isNoteFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var topInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }
    
    // MARK: Image Slider + Favorite overlay
    fileprivate func ImageSlider() -> some View {
        ZStack(alignment: .bottomTrailing) {
            PagingView(index: $index.animation(), maxIndex: product.images.count - 1) {
                ForEach(product.images) { image in
                    KFImage(URL(string:image.src))
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }
            }
            .aspectRatio(4/3, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.05))
            .clipped()
            
            FavoriteButton(
                isFav: isFavorite,
                onTap: {
                    mainViewModel.toggleFavorite(product: product)
                    isFavorite.toggle()
                }
            )
            .padding(.trailing, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }
    
    fileprivate func AddToCartButton() -> some View {
        Button(action: {
            withAnimation(.spring()){
                var newProduct = product
                newProduct.meta_data = []
                var newPrice = product.price
                firestoreManager.productAddOns.forEach { addon in
                    if addon.checked {
                        newProduct.meta_data.append(ProductMetaData(id: addon.id, key: addon.content, value: .string(String(addon.value))))
                        newPrice += Double(addon.value)
                    }
                }
                
                // Add product note to meta_data if not empty
                if !productNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    newProduct.meta_data.append(ProductMetaData(
                        id: 0,
                        key: "_note",
                        value: .string(productNote.trimmingCharacters(in: .whitespacesAndNewlines))
                    ))
                }
                
                newProduct.price = Double(newPrice)
                newProduct.regular_price = Double(newPrice)
                newProduct.meta_data = newProduct.meta_data.filter({ return !$0.key.contains("_") || $0.key == "_note" })
                mainViewModel.add(item: newProduct)
                
                // Reset note after adding to cart
                productNote = ""
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
            
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack {
                            Constants.AppColor.lightGrayColor
                                .edgesIgnoringSafeArea(.all)
                            VStack(alignment: .leading, spacing: 0) {
                            ImageSlider()
                                .frame(maxWidth: .infinity)
                                .padding(.top, topInset)
                            
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
                            
                            // Product Note Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Special Instructions / Note")
                                    .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                                    .foregroundColor(Constants.AppColor.secondaryBlack)
                                    .padding(.top, 15)
                                    .padding(.horizontal, 15)
                                
                                ZStack(alignment: .topLeading) {
                                    if productNote.isEmpty {
                                        Text("Add any special instructions or notes for this product...")
                                            .font(.custom(Constants.AppFont.lightFont, size: 14))
                                            .foregroundColor(.gray.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 12)
                                    }
                                    
                                    TextEditor(text: $productNote)
                                        .font(.custom(Constants.AppFont.lightFont, size: 14))
                                        .foregroundColor(Constants.AppColor.secondaryBlack)
                                        .frame(minHeight: 100, maxHeight: 200)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .focused($isNoteFocused)
                                        .onChange(of: productNote) { newValue in
                                            // Auto-expand text view based on content
                                            let lines = newValue.components(separatedBy: .newlines).count
                                            noteHeight = min(max(100, CGFloat(lines * 20) + 40), 200)
                                        }
                                        .onChange(of: isNoteFocused) { focused in
                                            if focused {
                                                // Scroll to note section when focused
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        proxy.scrollTo("noteSection", anchor: .center)
                                                    }
                                                }
                                            }
                                        }
                                }
                                .padding(.horizontal, 15)
                                .padding(.bottom, 10)
                                
                                // Dismiss keyboard button (shown when keyboard is visible)
                                if isNoteFocused || keyboardHeight > 0 {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            isNoteFocused = false
                                        }) {
                                            HStack {
                                                Image(systemName: "keyboard.chevron.compact.down")
                                                Text("Done")
                                            }
                                            .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color("ColorPrimary"))
                                            .cornerRadius(8)
                                        }
                                        .padding(.horizontal, 15)
                                        .padding(.bottom, 5)
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                            .id("noteSection")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(Color.white)
                            .padding(.top, 5)
                            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 60 : 0)
                        }
                    }
                    }
                }
                
                AddToCartButton()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // Close button fixed at top right - doesn't scroll
            VStack {
                HStack {
                    Spacer()
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
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // existing code
            firestoreManager.productAddOns = []
            if let id = product.categories.first?.id {
                firestoreManager.fetchProductAddOns(categoryId: id)
            }

            // init favorite state from MainViewModel
            isFavorite = mainViewModel.isFavorite(productId: product.id)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
}
