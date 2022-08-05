//
//  MainViewModel.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation
import SwiftyJSON
import Combine

enum PresentedType {
    case checkOut, productDetail, orderReceived, cart, none, editUserInfo, orderHistory
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

class MainViewModel: ObservableObject {
    
    @Published var appSetting: AppSetting?
    @Published var showLoading: Bool = false
    @Published var showNewSeason = false
    @Published var showCart = false
    @Published var sliders = [Slider]()
    @Published var items = [Product]()
    @Published var products = [Product]()
    @Published var showDiscount = false
    @Published var showCategoryProducts = true
    @Published var selectedSubCategory: Category = Category.default
    @Published var selectedCategory: Category = Category.default
    @Published var categories = [Category]()
    @Published var subcategories = [Category]()
    @Published var categoryProducts = [Product]()
    @Published var showDetail = false
    @Published var showCheckout = false
    @Published var selectedShip = ShipMethod.default
    @Published var shipMethods = [ShipMethod]()
    @Published var coupon: Coupon = Coupon.default
    @Published var selectedPayment : Payment = Payment.default
    @Published var showOrderReceived = false
    @Published var receivedOrder: Order = Order.default
    @Published var payments = [Payment]()
    @Published var zones = [Zone]()
    @Published var presentedType: PresentedType = .none
    @Published var message: String = ""
    
    var numberOfItems: Int {
        if items.count > 0 {
            return items.reduce(0) { $0 + $1.quantity }
        } else {
            return 0
        }
    }
    
    var discounts: Double {
        if items.count > 0 {
            return items.reduce(0) { $0 + ((Double($1.regular_price)! - (Double($1.price) ?? 0)) * Double($1.quantity)) }
        } else {
            return 0
        }
    }
    
    var subtotal: Double {
        if items.count > 0 {
            return items.reduce(0) { $0 + (Double($1.price)! * Double($1.quantity)) }
        } else {
            return 0
        }
    }
    
    var regularPriceTotal: Double {
        if items.count > 0 {
            return items.reduce(0) { $0 + (Double($1.regular_price)! * Double($1.quantity)) }
        } else {
            return 0
        }
    }
    
    var total: Double {
        if items.count > 0 {
            return subtotal + Double(selectedShip.settings.cost.value)!
        } else {
            return 0 + Double(selectedShip.settings.cost.value)!
        }
    }
    
    var fixedDiscount: Double {
        if coupon.id != Coupon.default.id {
            return Double(coupon.amount!)!
        } else {
            return 0
        }
    }
    
    var percentDiscount: Double {
        if coupon.id != Coupon.default.id {
            return (total * ( Double(coupon.amount!)! / 100))
        } else {
            return 0
        }
    }
    
    func getNumberOfInCart(item: Product) -> Int {
        var numberOfInCart = 0
        if let p = items.filter({ $0.id == item.id}).first  {
            numberOfInCart = p.quantity
        }
        return numberOfInCart
    }
    
    func add(item: Product) {
        var fl = false
        for index in 0..<items.count {
            if items[index].name == item.name && items[index].meta_data == item.meta_data {
                items[index].quantity += 1
                fl = true
                break
            }
        }
        
        if !fl {
            items.append(item)
            for index in 0..<items.count {
                if items[index].name == item.name && items[index].meta_data == item.meta_data {
                    items[index].quantity += 1
                    break
                }
            }
        }
        
    }
    
    func remove(item: Product) {
        var em = true
        for index in 0..<items.count {
            if items[index].name == item.name && items[index].meta_data == item.meta_data {
                if items[index].quantity == 1 {
                    items.remove(at: index)
                    em = false
                    break
                } else {
                    if items[index].quantity == 0 {
                        items.remove(at: index)
                        em = false
                        break
                    } else {
                        items[index].quantity -= 1
                        em = false
                        break
                    }
                    
                }
            }
        }
        
        if em {
            print("empty")
        }
    }
    
    func removeAll(item: Product) {
        let index = items.firstIndex{$0.id == item.id}
        items.remove(at: index!)
    }
    
    func reset() {
        for i in 0..<items.count {
            items[i].quantity = 0
        }
        items.removeAll()
    }
    
    private var service: MainServices = MainServices()
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(service: MainServices = MainServices()) {
        self.service = service
        self.bindingData()
    }
    
    func bindingData() {
        service.loadingPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .assign(to: &$showLoading)
        
        service.errorPublisher
            .receive(on: RunLoop.main)
            .sink { error in
                self.message = error
            }
            .store(in: &cancellableSet)
        
        service.categoryPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$categories)
        
        service.selectedCategoryProductPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$categoryProducts)
        
        service.orderReceivedPublisher
            .receive(on: RunLoop.main)
            .sink { order in
                if order.id != Order.default.id {
                    self.receivedOrder = order
                    self.presentedType = .orderReceived
                    self.reset()
                }
            }
            .store(in: &cancellableSet)
        
        $presentedType
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { value in
                self.presentedType = value
            }
            .store(in: &cancellableSet)
    }
    
    func onFetchCategories() {
        service.onFetchCategories()
    }
    
    func onFetchSelectedCategoryProducts(id: Int) {
        service.fetchSelectedCategoryProducts(id: id)
    }
    
    func onCreateOrder(user: User, productOrders: [ProductOrder]) {
        service.onCreateOrder(user: user, paymentMethod: selectedPayment.id, paymentMethodTitle: selectedPayment.title, customerNote: "", status: "on-hold", productOrders: productOrders)
    }
    
    func fetchProducts() {
        self.products.removeAll()
        
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/products?page=1&per_page=100&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {
                
                if let decodedResponse = try? JSONDecoder().decode([Product].self, from: data) {
                    DispatchQueue.main.async {
                        self.products.append(contentsOf: decodedResponse)
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            
        }.resume()
    }
    
    func fetchPayments() {
        self.payments.removeAll()
        
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/payment_gateways?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {
                
                if let decodedResponse = try? JSONDecoder().decode([Payment].self, from: data) {
                    DispatchQueue.main.async {
                        self.payments.append(contentsOf: decodedResponse)
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            
        }.resume()
    }
    
    func fetchZones() {
        self.zones.removeAll()

        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/shipping/zones?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {

                if let decodedResponse = try? JSONDecoder().decode([Zone].self, from: data) {
                    DispatchQueue.main.async {
                        self.zones.append(contentsOf: decodedResponse)
                        self.fetchShipMethods(id: self.zones[0].id)
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")

        }.resume()
    }
    
    func fetchShipMethods(id: Int) {
        self.shipMethods.removeAll()
        
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/shipping/zones/1/methods?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {
                
                if let decodedResponse = try? JSONDecoder().decode([ShipMethod].self, from: data) {
                    DispatchQueue.main.async {
                        self.shipMethods.append(contentsOf: decodedResponse)
                    }
                    return
                } else {
                    self.shipMethods.append(ShipMethod.default)
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            
        }.resume()
    }
    
    func checkCouponCode(code: String) {
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/woo-tools-app/coupon?code=\(code)") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(SECURITY_CODE, forHTTPHeaderField:"Security")
        
        URLSession.shared.dataTask(with: request) {data, response, error in
         
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(Coupon.self, from: data)
                    DispatchQueue.main.async {
                        print(decodedResponse)
                        
                        if decodedResponse.code! != "not_found" {
                            let minimumAmount = Double(String(describing:decodedResponse.minimum_amount!))!
                            let maximumAmount = Double(String(describing:decodedResponse.maximum_amount!))!
                            print(minimumAmount)
                            
                            if self.total < minimumAmount {
//                                self.dialogMessage = "Not meet min amount : \(decodedResponse.minimum_amount!)"
//                                self.showDialog.toggle()
                            }else if self.total > maximumAmount {
//                                self.dialogMessage = "Reached max amount : \(decodedResponse.maximum_amount!)"
//                                self.showDialog.toggle()
                            }else{
                                self.coupon = decodedResponse
//                                self.dialogMessage = "Success use coupon"
//                                self.showDialog.toggle()
                            }
                        } else {
//                            self.dialogMessage = decodedResponse.message!
//                            self.showDialog.toggle()
                        }
                    }
                } catch DecodingError.keyNotFound(let key, let context) {
                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                } catch DecodingError.valueNotFound(let type, let context) {
                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.typeMismatch(let type, let context) {
                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.dataCorrupted(let context) {
                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                } catch let error as NSError {
                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                }
                return
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            
        }.resume()
    }
}
