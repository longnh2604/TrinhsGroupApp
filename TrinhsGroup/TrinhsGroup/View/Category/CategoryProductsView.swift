//
//  CategoryProductsView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct CategoryProductsView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                withAnimation(.spring()){
                    mainViewModel.showCategoryProducts.toggle()
                }
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
            Text(mainViewModel.selectedCategory.name)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
                .background(Color.clear)
            , alignment: .center)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ScrollView(.vertical, showsIndicators: false, content: {
                        VStack(alignment: .leading, spacing: 10) {
                            
                            LazyVGrid(columns: gridLayout, spacing:15,  content: {
                                ForEach(mainViewModel.categoryProducts){ product in
                                    ItemCellView(product: product).environmentObject(mainViewModel)
                                }
                            })
                            .padding(15)
                            .padding(.bottom, 15)
                        }
                    })
                }
            }
            .onAppear {
                if mainViewModel.selectedCategory.id == Category.default.id {
                    guard let category = mainViewModel.categories.first else { return }
                    mainViewModel.selectedCategory = category
                    mainViewModel.onFetchSelectedCategoryProducts(id: category.id)
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct CategoryProductsView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryProductsView()
    }
}
