//
//  HistoryOrderItemsView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderItemsView: View {
    
    var order: Order
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Items")
                .fontWeight(.semibold)
                .foregroundColor(Color("ColorPrimary"))
            
            ForEach(order.line_items) { item in
                HistoryOrderProductItemView(productOrder: item)
            }
        }
    }
}

struct HistoryOrderItemsView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderItemsView(order: Order.default)
            .previewLayout(.sizeThatFits)
    }
}

