//
//  UserDefaultsManager.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import Foundation

class UserDefaultsManager {
    static let favorites = "favorites"
    static let allNotifications = "allNotifications"
    static let newNotifications = "newNotifications"
    
    // MARK: - Favorites
    
    static func saveFavorite(_ favorite: Product) {
        var favorites = loadFavorites()
        favorites.append(favorite)
        saveFavorites(favorites)
    }
    
    static func removeFavorite(_ product: Product) {
        var favorites = loadFavorites()
        if let index = favorites.firstIndex(where: { $0.id == product.id }) {
            favorites.remove(at: index)
        }
        saveFavorites(favorites)
    }
    
    static func toggleFavorite(_ product: Product) {
        if isFavorite(product.id) {
            removeFavorite(product)
        } else {
            saveFavorite(product)
        }
    }
    
    static func isFavorite(_ id: Int) -> Bool {
        let favorites = loadFavorites()
        return favorites.firstIndex(where: { $0.id == id }) != nil
    }
    
    static func saveFavorites(_ products: [Product]) {
        let data = products.compactMap { try? JSONEncoder().encode($0) }
        UserDefaults.standard.set(data, forKey: favorites)
    }
    
    static func loadFavorites() -> [Product] {
        guard let encodedData = UserDefaults.standard.array(forKey: favorites) as? [Data] else {
            return []
        }
        return encodedData.compactMap { try? JSONDecoder().decode(Product.self, from: $0) }
    }
    
    // MARK: - Notifications (unchanged below)
    static func save(_ notification: AppNotification) {
        var notifications = load()
        notifications.append(notification)
        save(notifications)
    }
    
    static func saveNew(_ notification: AppNotification) {
        var notifications = loadNew()
        notifications.append(notification)
        saveNew(notifications)
    }
    
    static func remove(_ notification: AppNotification) {
        var news = load()
        if let index = news.firstIndex(where: {$0.id == notification.id}){
            news.remove(at: index)
        }
        save(news)
    }
    
    static func removeAll() {
        save([])
    }
    
    static func removeNewAll() {
        saveNew([])
    }
    
    static func isInclude(_ id: Int) -> Bool{
        let news = load()
        return news.firstIndex(where: {$0.id == id}) != nil
    }

    static func save(_ news: [AppNotification]) {
        let data = news.map { try? JSONEncoder().encode($0) }
        UserDefaults.standard.set(data, forKey: allNotifications)
    }
    
    static func saveNew(_ news: [AppNotification]) {
        let data = news.map { try? JSONEncoder().encode($0) }
        UserDefaults.standard.set(data, forKey: newNotifications)
    }
    
    static func load() -> [AppNotification] {
        guard let encodedData = UserDefaults.standard.array(forKey: allNotifications) as? [Data] else {
            return []
        }
        return encodedData.compactMap { try? JSONDecoder().decode(AppNotification.self, from: $0) }
    }
    
    static func loadNew() -> [AppNotification] {
        guard let encodedData = UserDefaults.standard.array(forKey: newNotifications) as? [Data] else {
            return []
        }
        return encodedData.compactMap { try? JSONDecoder().decode(AppNotification.self, from: $0) }
    }
}
