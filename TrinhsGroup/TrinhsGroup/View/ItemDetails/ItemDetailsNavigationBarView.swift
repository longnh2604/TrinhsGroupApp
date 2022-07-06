//
//  ItemDetailsNavigationBarView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct ItemDetailsNavigationBarView: View {
    
    @Binding var show : Bool
    var product: Product
    @State var isFavorite: Bool = false
    
    fileprivate func FavoriteButton() -> some View {
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
//            Image(systemName: self.cloth.isFavorite == true ? "heart.fill" : "heart")
//                .foregroundColor(self.cloth.isFavorite == true ? .red : Constants.AppColor.secondaryBlack)
//                .frame(width: 35, height: 35)
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red :.gray)
                .frame(width: 35, height: 35)
            //.background(Color.white)
        }
        .cornerRadius(20)
        .onAppear(){
            isFavorite = UserDefaultsManager.isFavorite(product.id)
        }
        //                .shadow(color: Constants.AppColor.shadowColor, radius: 2, x: 0.8, y: 0.8)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Button(action: {
//                self.presentationMode.wrappedValue.dismiss()
                self.show.toggle()
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
            FavoriteButton()
                .padding(.trailing, 10)
        }
        .frame(width: UIScreen.main.bounds.width, height: 35)
        .overlay(
            Text(self.product.name)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
            , alignment: .center)
    }
}

struct ItemDetailsNavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailsNavigationBarView(show: .constant(false), product: Product.default)
    }
}
