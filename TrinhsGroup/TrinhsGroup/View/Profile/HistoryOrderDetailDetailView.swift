//
//  HistoryOrderDetailDetailView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderDetailDetailView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    var order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order No")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ColorPrimary"))
                    Text("#\(order.number)")
                }
                .foregroundColor(.black)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ColorPrimary"))
                    Text(order.date_created.toDate())
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("ColorPrimary"))
                    
                    Text(order.total)
                        +
                        Text("\("$")")
                        .font(.footnote)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .fontWeight(.semibold)
                    .foregroundColor(Color("ColorPrimary"))
                Text(order.billing.email)
                    .foregroundColor(.black)
            }
        }
    }
}

struct HistoryOrderDetailDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderDetailDetailView(order: Order.default)
    }
}
