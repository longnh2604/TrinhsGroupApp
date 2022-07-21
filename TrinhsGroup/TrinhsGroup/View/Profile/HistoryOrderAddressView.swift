//
//  HistoryOrderAddressView.swift
//  TrinhsGroup
//
//  Created by long on 15/07/2022.
//

import SwiftUI

struct HistoryOrderAddressView: View {
    
    var order: Order
    
    var body: some View {
        HStack {
            VStack(alignment: .leading){
                Text("Status")
                    .fontWeight(.semibold)
                    .foregroundColor(Color("ColorPrimary"))
                
                VStack(alignment: .leading) {
                    Text("\(order.billing.first_name)")
                    Text("\(order.billing.last_name)")
                    Text("\(order.billing.address_1)")
                    Text("\(order.billing.city), \(order.billing.state)")
                    Text("\(order.billing.postcode), \(order.billing.phone)")
                    Text("\(order.billing.email)")
                }
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)
                .padding(.top, 5)
                
                Text("Status")
                    .fontWeight(.semibold)
                    .foregroundColor(Color("ColorPrimary"))
                    .padding(.top, 10)
                
                VStack(alignment: .leading) {
                    Text("\(order.shipping.first_name)")
                    Text("\(order.shipping.last_name)")
                    Text("\(order.shipping.address_1)")
                    Text("\(order.shipping.city), \(order.shipping.state)")
                    Text("\(order.shipping.postcode)")
                }
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)
                .padding(.top, 5)
                
            }
            Spacer()
        }
    }
}

struct HistoryOrderAddressView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryOrderAddressView(order: Order.default)
    }
}
