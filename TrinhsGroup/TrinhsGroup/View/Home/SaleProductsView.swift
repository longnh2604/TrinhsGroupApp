//
//  SaleProductsView.swift
//  TrinhsGroup
//
//  Created by long on 08/07/2022.
//

import SwiftUI

struct SaleProductsView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                withAnimation(.spring()){
                    mainViewModel.showNewSeason.toggle()
                }
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .padding(.horizontal, 15)
        .frame(width: UIScreen.main.bounds.width, height: 35)
        .overlay(
            Text("New Season")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
            , alignment: .center)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationBarView()
                ZStack {
                    Constants.AppColor.lightGrayColor
                        .edgesIgnoringSafeArea(.all)
                    ScrollView(.vertical, showsIndicators: false, content: {
                        VStack(alignment: .leading, spacing: 10) {
                            
                            LazyVGrid(columns: gridLayout, spacing:15,  content: {
                                ForEach(mainViewModel.products){ product in
                                    ItemCellView(product: product)
                                        .onTapGesture {
                                            withAnimation(.easeOut){
//                                                selectedProduct = product
//                                                mainViewModel.showDetail.toggle()
                                            }
                                        }
                                        .environmentObject(mainViewModel)
                                }
                            })
                            .padding(15)
                            .padding(.bottom, 130)
                            
                        }
                    })
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct SaleProductsView_Previews: PreviewProvider {
    static var previews: some View {
        SaleProductsView()
    }
}
