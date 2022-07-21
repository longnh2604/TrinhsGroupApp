//
//  HistoryOrderNoteView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderNoteView: View {
    
    var order: Order
    
    var body: some View {
        HStack(spacing: 20){
            Text("Note")
                .fontWeight(.semibold)
                .foregroundColor(Color("ColorPrimary"))
            
            Text(order.customer_note)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
        }
    }
}

struct HistoryOrderNoteView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderNoteView(order: Order.default)
            .previewLayout(.sizeThatFits)
    }
}
