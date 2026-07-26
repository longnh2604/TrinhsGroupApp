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

    /// Live total: product price plus checked add-ons
    private var currentTotal: Double {
        var total = product.price
        firestoreManager.productAddOns.forEach { addon in
            if addon.checked {
                total += Double(addon.value)
            }
        }
        return total
    }

    // MARK: Image Slider
    fileprivate func ImageSlider() -> some View {
        PagingView(index: $index.animation(), maxIndex: product.images.count - 1) {
            ForEach(product.images) { image in
                OptimizedKFImage(
                    url: URL(string: image.src),
                    contentMode: .fill
                )
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.05))
        .clipped()
        .overlay(
            HStack {
                Button(action: {
                    mainViewModel.presentedType = .none
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Constants.AppColor.primaryBlack)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                }

                Spacer()

                FavoriteButton(
                    isFav: isFavorite,
                    onTap: {
                        mainViewModel.toggleFavorite(product: product)
                        isFavorite.toggle()
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, topInset + 8)
            , alignment: .top)
    }

    // MARK: Title, description and price
    fileprivate func TitlePriceSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name.decodingHTMLEntities())
                .font(.custom(Constants.AppFont.extraBoldFont, size: 21))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .fixedSize(horizontal: false, vertical: true)

            if !product.short_description.decodingHTMLEntities().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(product.short_description.decodingHTMLEntities())
                    .font(.custom(Constants.AppFont.regularFont, size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if product.sale_price > 0 {
                    Text(getPriceAndCurrencySymbol(price: product.sale_price, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.extraBoldFont, size: 20))
                        .foregroundColor(Color("ColorPrimary"))
                    Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.regularFont, size: 15))
                        .foregroundColor(.gray)
                        .strikethrough()
                    Text(getDiscountPercentage(regularPrice: product.regular_price, salePrice: product.sale_price))
                        .font(.custom(Constants.AppFont.boldFont, size: 11))
                        .foregroundColor(Constants.AppColor.secondaryRed)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Constants.AppColor.lightRose)
                        .clipShape(Capsule())
                } else {
                    Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.extraBoldFont, size: 20))
                        .foregroundColor(Color("ColorPrimary"))
                }
                Spacer()
            }
            .padding(.top, 2)
        }
    }

    // MARK: Add-ons
    fileprivate func AddOnsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Make it yours")
                .font(.custom(Constants.AppFont.boldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)

            VStack(spacing: 0) {
                ForEach(firestoreManager.productAddOns.indices, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            firestoreManager.productAddOns[index].checked.toggle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(firestoreManager.productAddOns[index].checked
                                          ? Color("ColorPrimary")
                                          : Color.white)
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(firestoreManager.productAddOns[index].checked
                                            ? Color("ColorPrimary")
                                            : Color.gray.opacity(0.4), lineWidth: 1.5)
                                if firestoreManager.productAddOns[index].checked {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 22, height: 22)

                            Text(firestoreManager.productAddOns[index].content)
                                .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                                .foregroundColor(Constants.AppColor.primaryBlack)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            if firestoreManager.productAddOns[index].value > 0 {
                                Text("+\(getPriceAndCurrencySymbol(price: Double(firestoreManager.productAddOns[index].value), currency: "$", currencyPosition: "right"))")
                                    .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                                    .foregroundColor(Constants.AppColor.secondaryBlack)
                            }
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    if index < firestoreManager.productAddOns.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(Constants.AppColor.lightGrayColor)
            .cornerRadius(14)
        }
    }

    // MARK: Special note
    fileprivate func NoteSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Special note")
                .font(.custom(Constants.AppFont.boldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)

            ZStack(alignment: .topLeading) {
                if productNote.isEmpty {
                    Text("Any special instructions for this dish? (e.g. no chilli, less sauce)")
                        .font(.custom(Constants.AppFont.regularFont, size: 13))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $productNote)
                    .font(.custom(Constants.AppFont.regularFont, size: 13))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                    .frame(minHeight: 90, maxHeight: 180)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .focused($isNoteFocused)
                    .onChange(of: productNote) { newValue in
                        let lines = newValue.components(separatedBy: .newlines).count
                        noteHeight = min(max(100, CGFloat(lines * 20) + 40), 200)
                    }
                    .onChange(of: isNoteFocused) { focused in
                        if focused {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("noteSection", anchor: .center)
                                }
                            }
                        }
                    }
            }
            .background(Constants.AppColor.lightGrayColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isNoteFocused ? Color("ColorPrimary").opacity(0.5) : Color.clear, lineWidth: 1.5)
            )

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
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color("ColorPrimary"))
                        .cornerRadius(10)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .id("noteSection")
    }

    // MARK: Add to cart
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
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                    Text("Added!")
                        .font(.custom(Constants.AppFont.boldFont, size: 16))
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    Text("Add to Cart")
                        .font(.custom(Constants.AppFont.boldFont, size: 16))
                        .foregroundColor(.white)
                    Spacer()
                    Text(getPriceAndCurrencySymbol(price: currentTotal, currency: "$", currencyPosition: "right"))
                        .font(.custom(Constants.AppFont.boldFont, size: 16))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color("ColorPrimary"))
            .cornerRadius(16)
            .shadow(color: Color("ColorPrimary").opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .animation(.easeInOut(duration: 0.2), value: isAdded)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ImageSlider()

                            // Content sheet overlapping the image
                            VStack(alignment: .leading, spacing: 20) {
                                TitlePriceSection()

                                if !firestoreManager.productAddOns.isEmpty {
                                    AddOnsSection()
                                }

                                NoteSection(proxy: proxy)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                DetailRoundedCorner(radius: 24, corners: [.topLeft, .topRight])
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 10, y: -4)
                            )
                            .padding(.top, -24)
                            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 60 : 0)
                        }
                    }
                }

                // Bottom action bar
                AddToCartButton()
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.06), radius: 8, y: -2)
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
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

            // Transparent TextEditor background so the note field can use the app's card color
            UITextView.appearance().backgroundColor = .clear
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

// MARK: - Rounded corner helper (top-only radius for the content sheet)
fileprivate struct DetailRoundedCorner: Shape {
    var radius: CGFloat = 24
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
