//
//  FavoriteView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct FavoriteView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var favorites = [Product]()
    
    var body: some View {
        NavigationView {
            VStack {
                HomeNavigationBarView(title: "Favorite", showNotificationIcon: false)
                    .environmentObject(mainViewModel)
                
                ZStack {
                    Constants.AppColor.lightGrayColor
                        .edgesIgnoringSafeArea(.all)
                    
                    ScrollView(.vertical, showsIndicators: false, content: {
                        VStack(alignment: .leading, spacing: 10) {
                            
                            LazyVGrid(columns: gridLayout, spacing:15,  content: {
                                ForEach(favorites){ product in
                                    ItemCellView(product: product)
                                        .onTapGesture {
                                            withAnimation(.easeOut){
                                                
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
        .onAppear(){
            favorites = UserDefaultsManager.loadFavorites()
        }
    }
}

struct FavoriteView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteView()
    }
}
