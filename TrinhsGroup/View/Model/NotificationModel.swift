//
//  NotificationModel.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import Foundation
import UserNotifications

struct AppNotification: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var content: String
    var date: Date = Date()
    var isRead: Bool = false

    init(id: String = UUID().uuidString, title: String, content: String, date: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.isRead = isRead
    }

    // Backward-compatible decoding: legacy entries had an Int id and no date/isRead
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let intID = try? container.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            id = UUID().uuidString
        }
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        isRead = (try? container.decode(Bool.self, forKey: .isRead)) ?? true
    }
}

// MARK: - Notification history store
// Persists every push the app sees so the bell screen can show read/unread history.
final class NotificationStore: ObservableObject {

    static let shared = NotificationStore()

    @Published private(set) var notifications: [AppNotification] = []

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private init() {
        // Merge legacy stores: "allNotifications" (read) + "newNotifications" (unread)
        var merged = UserDefaultsManager.load()
        for legacy in UserDefaultsManager.loadNew() where !merged.contains(where: { $0.id == legacy.id }) {
            var unread = legacy
            unread.isRead = false
            merged.append(unread)
        }
        UserDefaultsManager.removeNewAll()
        notifications = merged.sorted(by: { $0.date > $1.date })
        persist()
    }

    /// Add a notification if it isn't already stored. Safe to call from any thread.
    func add(id: String, title: String, content: String, date: Date = Date(), isRead: Bool = false) {
        guard !title.isEmpty || !content.isEmpty else { return }
        DispatchQueue.main.async {
            if let index = self.notifications.firstIndex(where: { $0.id == id }) {
                if isRead && !self.notifications[index].isRead {
                    self.notifications[index].isRead = true
                    self.persist()
                }
                return
            }
            self.notifications.insert(AppNotification(id: id, title: title, content: content, date: date, isRead: isRead), at: 0)
            self.notifications.sort(by: { $0.date > $1.date })
            self.persist()
        }
    }

    func markRead(_ notification: AppNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        guard !notifications[index].isRead else { return }
        notifications[index].isRead = true
        persist()
    }

    func markAllRead() {
        guard unreadCount > 0 else { return }
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        persist()
    }

    func remove(_ notification: AppNotification) {
        notifications.removeAll(where: { $0.id == notification.id })
        persist()
    }

    /// Pick up pushes that arrived while the app was closed and are still in
    /// the system Notification Center.
    func syncDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
            for item in delivered {
                let content = item.request.content
                self.add(id: item.request.identifier,
                         title: content.title,
                         content: content.body,
                         date: item.date)
            }
        }
    }

    private func persist() {
        UserDefaultsManager.save(notifications)
    }
}
