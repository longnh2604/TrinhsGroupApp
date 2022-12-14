//
//  ItemCellView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI
import Kingfisher

struct ItemCellView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    
    var product: Product
    @State var show = false
    @State var isFavorite: Bool = false
    
    fileprivate func TopLabel() -> some View {
        return Text("-20%")
            .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
            .padding([.trailing, .leading], 8)
            .frame(height: 25)
            .background(Color("ColorPrimary"))
            .cornerRadius(12.5)
            .foregroundColor(.white)
    }
    
    fileprivate func FevoriteButton() -> some View {
        return Button(action: {
            if UserDefaultsManager.isFavorite(product.id) {
                UserDefaultsManager.removeFavorite(product)
                print("Remove: \(self.product.name)")
            }else{
                UserDefaultsManager.saveFavorite(product)
                print("Save: \(self.product.name)")
            }
            isFavorite.toggle()
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red :.gray)
                .frame(width: 30, height: 30)
                .background(Color.white)
        }
        .cornerRadius(20)
        .opacity(0.9)
        .shadow(color: Color.init(hex: "dddddd"), radius: 0.5, x: 0.3, y: 0.3)
    }
    
    var body: some View {
        ZStack {
            NavigationLink(destination: ItemDetailsView(product: product, show: self.$show).environmentObject(mainViewModel).environmentObject(firestoreManager), isActive: self.$show) {
                Text("")
            }
            VStack(alignment: .leading) {
                Group{
                    if product.images.count > 0 {
                        KFImage(URL(string:product.images[0].src))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }else{
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color("ColorGray"))
                    }
                }
                .frame(width: UIScreen.main.bounds.width / 2 - 40, height: 190)
                .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .cornerRadius(1)
                .overlay(
                    FevoriteButton()
                        .padding(5), alignment: .topTrailing)
                
                Text(product.short_description.decodingHTMLEntities())
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .padding([.horizontal], 10)
                    .padding(.top, 0)
                
                Text(product.name)
                    .font(.custom(Constants.AppFont.regularFont, size: 11))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .padding([.horizontal], 10)
                    .padding(.top, 2)
                HStack {
                    
                    if product.sale_price != "" {
                        Text(getPriceAndCurrencySymbol(price: product.sale_price, currency: "$", currencyPosition: "right"))
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                            .foregroundColor(Constants.AppColor.primaryBlack)
                        Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                            .font(.custom(Constants.AppFont.regularFont, size: 11))
                            .foregroundColor(.gray) .strikethrough()
                        Text(getDiscountPercentage(regularPrice: product.regular_price, salePrice: product.sale_price))
                            .font(.custom(Constants.AppFont.regularFont, size: 11))
                            .foregroundColor(Constants.AppColor.secondaryRed)
                    }else{
                        Text(getPriceAndCurrencySymbol(price: product.regular_price, currency: "$", currencyPosition: "right"))
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                            .foregroundColor(Constants.AppColor.primaryBlack)
                    }
                    
                }
                .padding(.top, 5)
                .padding([.leading], 10)
                .padding([.trailing], 5)
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width / 2 - 40, height: 268)
            .background(Color.white)
            .cornerRadius(2)
            .clipped()
            .onTapGesture {
                self.show.toggle()
            }
        }
        .onAppear(){
            isFavorite = UserDefaultsManager.isFavorite(product.id)
        }
    }
}

struct ItemCellView_Previews: PreviewProvider {
    static var previews: some View {
        ItemCellView(product: Product.default)
    }
}
