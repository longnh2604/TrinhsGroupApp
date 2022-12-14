//
//  StatusItemsView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct StatusItemsView: View {
    
    var order: Order
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Order Status")
                .fontWeight(.semibold)
                .foregroundColor(Color("ColorPrimary"))
            
            VStack(alignment: .leading, spacing: 0) {
                StatusItemView(current: order.status, status: "pending payment", date: order.date_modified)
                StatusItemView(current: order.status, status: "on-hold", date: order.date_modified)
                StatusItemView(current: order.status, status: "processing", date: order.date_modified)
                StatusItemView(current: order.status, status: "completed", date: order.date_modified)
            }
        }
    }
}

struct StatusItemsView_Previews: PreviewProvider {
    static var previews: some View {
        StatusItemsView(order: Order.default)
            .previewLayout(.sizeThatFits)
    }
}
