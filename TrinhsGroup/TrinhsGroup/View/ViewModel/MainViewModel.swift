//
//  MainViewModel.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation
import SwiftyJSON

class MainViewModel: ObservableObject {
    
    @Published var appSetting: AppSetting?
    @Published var showLoading: Bool = false
    @Published var showNewSeason = false
    @Published var showCart = false
    @Published var sliders = [Slider]()
    @Published var items = [Product]()
    @Published var products = [Product]()
    
//    @Published var activeSheet: ActiveSheet?
//    @Published var payments = [Payment]()
//    @Published var zones = [Zone]()
//    @Published var shipMethods = [ShipMethod]()
//    @Published var categories = [Category]()
//    @Published var subcategories = [Category]()
//    @Published var selectedCategory: Category = Category.default
//    @Published var selectedSubCategory: Category = Category.default

//    @Published var categoryProducts = [Product]()
//    @Published var showDetail = false

//    @Published var showDiscount = false
//    @Published var showCheckout = false
//    @Published var showOrderReceived = false
//    @Published var showCategoryProducts = false
//    @Published var receivedOrder: Order = Order.default
//    @Published var coupon: Coupon = Coupon.default
//    @Published var showDialog: Bool = false
//    @Published var dialogMessage: String = ""
//    @Published var selectedShip = ShipMethod.default
//    @Published var selectedPayment : Payment = Payment.default
//    
    var numberOfItems: Int {
        if items.count > 0 {
            return items.reduce(0) { $0 + $1.quantity }
        } else {
            return 0
        }
    }
//    
//    var discounts: Double {
//        if items.count > 0 {
//            return items.reduce(0) { $0 + ((Double($1.regular_price)! - (Double($1.price) ?? 0)) * Double($1.quantity)) }
//        } else {
//            return 0
//        }
//    }
//    
//    var subtotal: Double {
//        if items.count > 0 {
//            return items.reduce(0) { $0 + (Double($1.price)! * Double($1.quantity)) }
//        } else {
//            return 0
//        }
//    }
//    
//    var regularPriceTotal: Double {
//        if items.count > 0 {
//            return items.reduce(0) { $0 + (Double($1.regular_price)! * Double($1.quantity)) }
//        } else {
//            return 0
//        }
//    }
//    
//    var total: Double {
//        if items.count > 0 {
//            return subtotal + Double(selectedShip.settings.cost.value)!
//        } else {
//            return 0 + Double(selectedShip.settings.cost.value)!
//        }
//    }
//    
//    var fixedDiscount: Double {
//        if coupon.id != Coupon.default.id {
//            return Double(coupon.amount!)!
//        } else {
//            return 0
//        }
//    }
//    
//    var percentDiscount: Double {
//        if coupon.id != Coupon.default.id {
//            return (total * ( Double(coupon.amount!)! / 100))
//        } else {
//            return 0
//        }
//    }
//    
//    func getNumberOfInCart(item: Product) -> Int {
//        var numberOfInCart = 0
//        if let p = items.filter({ $0.id == item.id}).first  {
//            numberOfInCart = p.quantity
//        }
//        return numberOfInCart
//    }
//    
//    func add(item: Product) {
//        var fl = false
//        for index in 0..<items.count {
//            if items[index].name == item.name {
//                items[index].quantity += 1
//                fl = true
//                break
//            }
//        }
//        
//        if !fl {
//            items.append(item)
//            for index in 0..<items.count {
//                if items[index].name == item.name {
//                    items[index].quantity += 1
//                    break
//                }
//            }
//        }
//        
//    }
//    
//    func remove(item: Product) {
//        var em = true
//        for index in 0..<items.count {
//            if items[index].name == item.name {
//                if items[index].quantity == 1 {
//                    items.remove(at: index)
//                    em = false
//                    break
//                } else {
//                    if items[index].quantity == 0 {
//                        items.remove(at: index)
//                        em = false
//                        break
//                    } else {
//                        items[index].quantity -= 1
//                        em = false
//                        break
//                    }
//                    
//                }
//            }
//        }
//        
//        if em {
//            print("empty")
//        }
//    }
//    
//    func removeAll(item: Product) {
//        let index = items.firstIndex{$0.id == item.id}
//        items.remove(at: index!)
//    }
//    
//    func reset() {
//        for i in 0..<items.count {
//            items[i].quantity = 0
//        }
//        items.removeAll()
//    }
//    
//    func version() {
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/woo-tools-app/version?code=\(UIApplication.build)") else {
//            print("Invalid URL")
//            return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue(SECURITY_CODE, forHTTPHeaderField:"Security")
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//         
//            if let data = data {
//                do {
//                    let decodedResponse = try JSONDecoder().decode(AppSetting.self, from: data)
//                    DispatchQueue.main.async {
//                        print(decodedResponse)
//                        self.appSetting = decodedResponse
//                    }
//                } catch DecodingError.keyNotFound(let key, let context) {
//                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//                } catch DecodingError.valueNotFound(let type, let context) {
//                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.typeMismatch(let type, let context) {
//                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.dataCorrupted(let context) {
//                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//                } catch let error as NSError {
//                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//                }
//                return
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    func fetchSliders() {
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/woo-tools-app/post/sticky") else {
//            print("Invalid URL")
//            return
//        }
//        var request = URLRequest(url: url)
//        
//        request.setValue(SECURITY_CODE, forHTTPHeaderField:"Security")
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//                
//                if let decodedResponse = try? JSONDecoder().decode([Slider].self, from: data) {
//                    DispatchQueue.main.async {
//                        self.sliders.append(contentsOf: decodedResponse)
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    func fetchCategories() {
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/products/categories?page=1&per_page=100&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)&parent=0&order=desc") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            
//            if let data = data {
//                do {
//                    let decodedResponse = try JSONDecoder().decode([Category].self, from: data)
//                    DispatchQueue.main.async {
//                        self.categories.append(contentsOf: decodedResponse)
//                        self.selectedCategory = self.categories.first!
//                        self.fetchSubCategories()
//                    }
//                } catch DecodingError.keyNotFound(let key, let context) {
//                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//                } catch DecodingError.valueNotFound(let type, let context) {
//                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.typeMismatch(let type, let context) {
//                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.dataCorrupted(let context) {
//                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//                } catch let error as NSError {
//                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//                }
//                return
//            }
//            
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    func fetchSubCategories() {
//        self.subcategories.removeAll()
//        
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/products/categories?page=1&per_page=100&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)&parent=\(selectedCategory.id)&order=asc") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//                
//                if let decodedResponse = try? JSONDecoder().decode([Category].self, from: data) {
//                    DispatchQueue.main.async {
//                        self.subcategories.append(contentsOf: decodedResponse)
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    func fetchSelectedSubCategoryProducts() {
//        self.categoryProducts.removeAll()
//
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/products?page=1&per_page=100&category=\(selectedSubCategory.id)&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//
//                if let decodedResponse = try? JSONDecoder().decode([Product].self, from: data) {
//                    DispatchQueue.main.async {
//                        self.categoryProducts.append(contentsOf: decodedResponse)
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//
//        }.resume()
//    }
//    
//    func fetchProducts() {
//        self.products.removeAll()
//        
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/products?page=1&per_page=100&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//                
//                if let decodedResponse = try? JSONDecoder().decode([Product].self, from: data) {
//                    DispatchQueue.main.async {
//                        self.products.append(contentsOf: decodedResponse)
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    
//    func fetchPayments() {
//        self.payments.removeAll()
//        
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/payment_gateways?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//                
//                if let decodedResponse = try? JSONDecoder().decode([Payment].self, from: data) {
//                    DispatchQueue.main.async {
//                        self.payments.append(contentsOf: decodedResponse)
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    func fetchZones() {
//        self.zones.removeAll()
//        
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/shipping/zones?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//                
//                if let decodedResponse = try? JSONDecoder().decode([Zone].self, from: data) {
//                    DispatchQueue.main.async {
//                        self.zones.append(contentsOf: decodedResponse)
//                        self.fetchShipMethods(id: self.zones[1].id)
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    func fetchShipMethods(id: Int) {
//        self.shipMethods.removeAll()
//        
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/shipping/zones/1/methods?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//                
//                if let decodedResponse = try? JSONDecoder().decode([ShipMethod].self, from: data) {
//                    DispatchQueue.main.async {
//                        self.shipMethods.append(contentsOf: decodedResponse)
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    func checkCouponCode(code: String) {
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/woo-tools-app/coupon?code=\(code)") else {
//            print("Invalid URL")
//            return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue(SECURITY_CODE, forHTTPHeaderField:"Security")
//        
//        URLSession.shared.dataTask(with: request) {data, response, error in
//         
//            if let data = data {
//                do {
//                    let decodedResponse = try JSONDecoder().decode(Coupon.self, from: data)
//                    DispatchQueue.main.async {
//                        print(decodedResponse)
//                        
//                        if decodedResponse.code! != "not_found" {
//                            let minimumAmount = Double(String(describing:decodedResponse.minimum_amount!))!
//                            let maximumAmount = Double(String(describing:decodedResponse.maximum_amount!))!
//                            print(minimumAmount)
//                            
//                            if self.total < minimumAmount {
//                                self.dialogMessage = "Not meet min amount : \(decodedResponse.minimum_amount!)"
//                                self.showDialog.toggle()
//                            }else if self.total > maximumAmount {
//                                self.dialogMessage = "Reached max amount : \(decodedResponse.maximum_amount!)"
//                                self.showDialog.toggle()
//                            }else{
//                                self.coupon = decodedResponse
//                                self.dialogMessage = "Success use coupon"
//                                self.showDialog.toggle()
//                            }
//                        }else{
//                            self.dialogMessage = decodedResponse.message!
//                            self.showDialog.toggle()
//                        }
//                        
//                        
//                    }
//                } catch DecodingError.keyNotFound(let key, let context) {
//                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//                } catch DecodingError.valueNotFound(let type, let context) {
//                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.typeMismatch(let type, let context) {
//                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.dataCorrupted(let context) {
//                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//                } catch let error as NSError {
//                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//                }
//                return
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//            
//        }.resume()
//    }
//    
//    
//    func createOrder(user: User, paymentMethod: String, paymentMethodTitle: String, customerNote: String, status: String, productOrders: [ProductOrder], shippingOrders: [ShippingOrder]){
//        
//        self.showLoading.toggle()
//        
//        var lineItems:Array = [Dictionary<String, Any>]()
//        
//        for productOrder in productOrders{
//            lineItems.append(["product_id" : productOrder.product_id, "quantity" : productOrder.quantity])
////            lineItems.append(["product_id" : productOrder.product_id, "quantity" : productOrder.quantity, "variations" : ["pa_color":"Green","pa_size":"S"]])
//        }
//        
//        print(lineItems)
//        
//        var shippingLines:Array = [Dictionary<String, Any>]()
//        
//        for shippingOrder in shippingOrders{
//            shippingLines.append(["method_id" : shippingOrder.method_id, "total" : shippingOrder.total])
//        }
//        
//        print(shippingLines)
//        
//        // prepare json data
//        var json: [String: Any] = [
//            "customer_id": user.id,
//            "payment_method": paymentMethod,
//            "payment_method_title": paymentMethodTitle,
//            "customer_note": customerNote,
//            "status": status,
//            "billing": [
//                "first_name":user.billing.first_name,
//                "last_name":user.billing.last_name,
//                "company":user.billing.company,
//                "country":user.billing.country,
//                "address_1":user.billing.address_1,
//                "address_2":user.billing.address_2,
//                "city":user.billing.city,
//                "postcode":user.billing.postcode,
//                "state":user.billing.state,
//                "email":user.billing.email,
//                "phone":user.billing.phone
//            ],
//            "shipping": [
//                "first_name":user.shipping.first_name,
//                "last_name":user.shipping.last_name,
//                "company":user.shipping.company,
//                "country":user.shipping.country,
//                "address_1":user.shipping.address_1,
//                "address_2":user.shipping.address_2,
//                "city":user.shipping.city,
//                "postcode":user.shipping.postcode,
//                "state":user.shipping.state
//            ],
//            "line_items": lineItems,
//            "shipping_lines": shippingLines
//        ]
//        
//        if coupon.id != Coupon.default.id {
//            json["coupon_lines"] = [["code": coupon.code]]
//        }
//        
//        let jsonData = try? JSONSerialization.data(withJSONObject: json)
//        
//        print(String(decoding: jsonData!, as: UTF8.self))
//        
//        // Prepare URL"
//        let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/orders?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)")
//        guard let requestUrl = url else { fatalError() }
//        // Prepare URL Request Object
//        var request = URLRequest(url: requestUrl)
//        request.httpMethod = "POST"
//        
//        //HTTP Headers
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
//        
//        // Set HTTP Request Body
//        request.httpBody = jsonData//postString.data(using: String.Encoding.utf8);
//        // Perform HTTP Request
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            
//            self.showLoading.toggle()
//            // Check for Error
//            if let error = error {
//                print("Error took place \(error)")
//                return
//            }
//            let json = JSON(data!)
//            print(json)
//            
//            if let data = data {
//                do {
//                    let decodedResponse = try JSONDecoder().decode(Order.self, from: data)
//                    DispatchQueue.main.async {
//                        print(decodedResponse)
//                        self.receivedOrder = decodedResponse
//                        self.showOrderReceived.toggle()
//                        self.showCheckout.toggle()
//                        self.showCart.toggle()
//                        self.reset()
//                    }
//                } catch DecodingError.keyNotFound(let key, let context) {
//                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
//                } catch DecodingError.valueNotFound(let type, let context) {
//                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.typeMismatch(let type, let context) {
//                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
//                } catch DecodingError.dataCorrupted(let context) {
//                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
//                } catch let error as NSError {
//                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
//                }
//                return
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//        }
//        task.resume()
//    }
}
