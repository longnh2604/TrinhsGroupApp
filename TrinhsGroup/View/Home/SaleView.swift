//
//  SaleView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct SaleView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Sale")
                        .font(.custom(Constants.AppFont.boldFont, size: 22))
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                        .padding(.bottom, -1)
                    Text("New Season Sale")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 11))
                        .foregroundColor(.gray)
                }.padding(.leading, 15)
                Spacer()
                Button(action: {
                    withAnimation(.spring()){
                        mainViewModel.showNewSeason.toggle()
                    }
                }) {
                    Text("VIEW ALL")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 12))
                        .foregroundColor(Constants.AppColor.secondaryRed)
                        .padding(.trailing, 15)
                }
            }
            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack(spacing: 5) {
                    ForEach(mainViewModel.products) { product in
                        ItemCellView(product: product)
                            .environmentObject(mainViewModel)
                    }
                }
                .padding(.leading, 10)
            })
        }.padding(.top, 10)
    }
}

struct SaleView_Previews: PreviewProvider {
    static var previews: some View {
        SaleView()
    }
}
