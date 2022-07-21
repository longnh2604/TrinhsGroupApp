//
//  ItemDetailsView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI
import Kingfisher

struct ItemDetailsView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var product: Product
    @Binding var show : Bool
    @State var index = 0
    @State private var color: String = ""
    @State private var size: String = ""
    @State private var webViewHeight: CGFloat = .zero
    @State private var showDialog = false
    
    
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
    
    fileprivate func SelectSizeView() -> some View {
        return VStack(alignment: .leading) {
            Text("Select Size")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .padding(.top, 10)
            
            HStack {
                if let options = product.attributes.first(where: {$0.name == "Size"})?.options {
                    ForEach(options, id: \.self) { size in
                        Button(action: {
                            self.size = size
                            self.product.size = size
                        }) {
                            Text(size)
                                .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                                .foregroundColor(self.size == size ? Constants.AppColor.secondaryRed : Constants.AppColor.secondaryBlack)
                                .frame(width: 40, height: 30)
                        }
                        .overlay(RoundedRectangle(cornerRadius: 5)
                        .stroke(self.size == size ? Constants.AppColor.secondaryRed : Constants.AppColor.secondaryBlack, lineWidth: self.size == size ? 1.0 : 0.3))
                    }
                    Spacer()
                }
                
            }
            .padding(.top, 15)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 15)
        .background(Color.white)
        .padding(.bottom, 5)
    }
    
    fileprivate func SelectColorView() -> some View {
        return VStack(alignment: .leading) {
            Text("Select Color")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .padding(.top, 10)

            HStack {
                if let options = product.attributes.first(where: {$0.name == "Color"})?.options {
                    ForEach(options, id: \.self) { color in
                        Button(action: {
                            self.color = color
                            self.product.color = color
                        }) {
                            Text(color)
                                .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                                .foregroundColor(self.color == color ? Constants.AppColor.secondaryRed : Constants.AppColor.secondaryBlack)
                                .frame(height: 30)
                                .padding(.horizontal, 10)
                        }
                        .overlay(RoundedRectangle(cornerRadius: 5)
                        .stroke(self.color == color ? Constants.AppColor.secondaryRed : Constants.AppColor.secondaryBlack, lineWidth: self.color == color ? 1.0 : 0.3))
                    }
                    Spacer()
                }

            }
            .padding(.top, 15)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 15)
        .background(Color.white)
        .padding(.bottom, 5)
    }
    
    fileprivate func AddToCartButton() -> some View {
        Button(action: {
            withAnimation(.spring()){
                mainViewModel.add(item: product)
                show.toggle()
            }
        }) {
            Text("")
                .frame(height: 55)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Color("ColorPrimary"))
                .cornerRadius(0)
        }
        .padding(.horizontal, 0)
        .overlay(
            Text("Add To Cart")
                .font(.custom(Constants.AppFont.boldFont, size: 15))
                .foregroundColor(.white)
        )
    }
    
    var body: some View {
        VStack {
            ItemDetailsNavigationBarView(show: $show, product: product)
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
                                .font(.custom(Constants.AppFont.lightFont, size: 13))
                                .foregroundColor(Constants.AppColor.secondaryBlack)
                                .lineLimit(nil)
                                .padding([.horizontal], 15)
                                .padding(.top, -5)
                                .padding(.bottom, 5)

                            HStack {
                                if product.sale_price != "" {
                                    Text(getPriceAndCurrencySymbol(price: product.sale_price, currency: "$", currencyPosition: "right"))
                                        .font(.custom(Constants.AppFont.boldFont, size: 14))
                                        .foregroundColor(Constants.AppColor.secondaryBlack)
                                    Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                                        .font(.custom(Constants.AppFont.regularFont, size: 13))
                                        .foregroundColor(.gray) .strikethrough()
                                    Text(getDiscountPercentage(regularPrice: product.regular_price, salePrice: product.sale_price))
                                        .font(.custom(Constants.AppFont.regularFont, size: 13))
                                        .foregroundColor(Constants.AppColor.secondaryRed)
                                }else{
                                    Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                                        .font(.custom(Constants.AppFont.boldFont, size: 14))
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
                            if let options = product.attributes.first?.options {
                                ForEach(options, id: \.self) { option in
                                    HStack {
                                        CheckBoxView(checked: .constant(true))
                                        Text("\(option.getPriceOption(strings: option).name)") + Text(option.getPriceOption(strings: option).price.isEmpty ? "" : " (\(option.getPriceOption(strings: option).price)$)")
                                        Spacer()
                                    }
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
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true).alert(isPresented: $showDialog, content: {
                Alert(title: Text("Size or Color Empty"), message: Text("Select Size and Color please"), dismissButton: .default(Text("OK")))
            })
    }
}

struct ItemDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailsView(product: Product.default, show: .constant(false))
    }
}
