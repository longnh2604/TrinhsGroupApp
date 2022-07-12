//
//  OrderReceivedItemsView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedItemsView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Items")
                .fontWeight(.semibold)
                .foregroundColor(Color("ColorPrimary"))
            
            ForEach(mainViewModel.receivedOrder.line_items) { item in
                OrderReceivedProductItemView(productOrder: item)
            }
        }
    }
}

struct OrderReceivedItemsView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedItemsView()
            .previewLayout(.sizeThatFits)
    }
}
