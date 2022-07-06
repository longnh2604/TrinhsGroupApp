//
//  HistoryViewModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

class HistoryViewModel: ObservableObject {
    
    @Published var orders = [Order]()
    @Published var showHistory = false
    @Published var showHistoryOrderDetail = false
    
    func fetchOrders(customerId: Int) {
        
        orders.removeAll()
        
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/orders?customer=\(customerId)&page=1&per_page=100&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {
                
                if let decodedResponse = try? JSONDecoder().decode([Order].self, from: data) {
                    DispatchQueue.main.async {
                        self.orders.append(contentsOf: decodedResponse)
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            
        }.resume()
    }
}
