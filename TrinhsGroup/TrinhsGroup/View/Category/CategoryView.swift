//
//  CategoryView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI
import Kingfisher

struct CategoryView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            
        }
        .padding(.horizontal, 15)
        .frame(width: UIScreen.main.bounds.width, height: 35)
        .overlay(
            Text("Category")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
            , alignment: .center)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.AppColor.lightGrayColor
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    NavigationBarView()
                    
                    ScrollView(.horizontal, showsIndicators: false, content: {
                        HStack{
                            ForEach(mainViewModel.categories) { category in
                                Text(category.name)
                                    .font(.custom(Constants.AppFont.boldFont, size: 15))
                                    .fontWeight(.bold)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 25)
                                    .background(
                                        ZStack{
                                            if mainViewModel.selectedCategory.name == category.name {
                                                Color.white.cornerRadius(10)
                                            }
                                        }
                                    )
                                    .foregroundColor(mainViewModel.selectedCategory.name == category.name ? .black : .white)
                                    .onTapGesture {
                                        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.6)){
                                            mainViewModel.selectedCategory = category
                                            mainViewModel.fetchSelectedCategoryProducts()
                                        }
                                    }.frame(minWidth: 0,
                                            maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(Color("ColorPrimary"))
                    })
                    
                    CategoryProductsView()
                        .environmentObject(mainViewModel)
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct CategoryView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryView()
    }
}
