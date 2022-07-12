//
//  OrderReceivedView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                mainViewModel.showOrderReceived = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .overlay(
            Text("Checkout")
                .font(.headline)
                .padding(.horizontal, 10)
                .background(Color.init(hex: "f9f9f9"))
            , alignment: .center)
    }
    
    var body: some View {
        ZStack {
            
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 5, content: {
                // NAVBAR
                NavigationBarView()
                
                Spacer()
                
                // DEATIL BOTTOM PART
                VStack(alignment: .center, spacing: 0, content: {
                    
                    ScrollView(showsIndicators: false){
                        
                        HeaderOrderReceivedView()
                        
                        Divider()
                            .padding(.vertical)
                        
                        OrderReceivedDetailView()
                            .environmentObject(mainViewModel)
                        
                        Divider()
                            .padding(.vertical)
                        
                        OrderReceivedItemsView()
                            .environmentObject(mainViewModel)
                        
                        OrderReceivedPricesView()
                            .padding(.bottom)
                            .environmentObject(mainViewModel)
                        
                    }
                    .padding(.horizontal)
                    
                    
                })
                .padding(.top)
                
            }).zIndex(0)
        }
    }
}

struct OrderReceivedView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedView()
            .environmentObject(MainViewModel())
    }
}
