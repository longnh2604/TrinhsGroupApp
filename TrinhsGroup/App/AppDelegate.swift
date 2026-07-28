//
//  AppDelegate.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI
import SwiftyJSON
import CoreData
import Firebase
import Stripe
import netfox
import Kingfisher

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @AppStorage("notifications") var notifications: Int = 0
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Kingfisher cache for better performance
        configureKingfisherCache()
        
        // Debug
        #if DEBUG
        NFX.sharedInstance().start()
        #endif
        // STPTestingPublishableKey
//        STPAPIClient.shared.publishableKey = "pk_live_51KY9yTFxroI2z58cos6LBBuBu2jCrYNbLvaRx0C4JF3yjxFnPAYIWu8PEpFH9td9r7kM4ul41fy84PY1zLS3vpbX00dqy98QcG"
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                print("🔔 Notification authorization granted=\(granted) error=\(error?.localizedDescription ?? "none")")
                Self.logNotificationSettings()
            }
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenStr = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📡 APNs token received (\(deviceToken.count) bytes): \(tokenStr.prefix(20))…")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("📡 ❌ APNs registration failed: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)
    }

    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content
        // Reaching this method means the push arrived while the app was in the FOREGROUND.
        // An empty title AND body would mean the payload carried no aps.alert — the store
        // would drop it, and nothing would appear in the bell either.
        print("🔔 foreground push: title=\"\(content.title)\" body=\"\(content.body)\" "
              + "→ presenting banner+sound+badge")
        NotificationStore.shared.add(id: notification.request.identifier,
                                     title: content.title,
                                     content: content.body,
                                     date: notification.date)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let tappedContent = response.notification.request.content
        NotificationStore.shared.add(id: response.notification.request.identifier,
                                     title: tappedContent.title,
                                     content: tappedContent.body,
                                     date: response.notification.date,
                                     isRead: true)
        let userInfo = response.notification.request.content.userInfo
        if let orderIDString = userInfo["order_id"] as? String, let orderID = Int(orderIDString) {
            // Store for cold-launch support; HistoryViewModel also reads this on orders load
            UserDefaults.standard.set(orderID, forKey: "pending_order_id")
            NotificationCenter.default.post(
                name: .didTapOrderNotification,
                object: nil,
                userInfo: ["order_id": orderID]
            )
        }
        completionHandler()
    }
    
    /// Configure Kingfisher image cache for optimal performance
    fileprivate func configureKingfisherCache() {
        // Set cache expiration to 7 days
        let cache = ImageCache.default
    /// Dump every setting that decides whether a delivered notification is actually *shown*.
    ///
    /// A notification can be delivered — landing in Notification Center, where
    /// `NotificationStore.syncDeliveredNotifications()` picks it up for the in-app bell —
    /// while iOS shows no banner at all. That happens when banners are switched off, when
    /// the app is set to "Deliver Quietly", or when its notifications are being batched
    /// into a Scheduled Summary. `authorizationStatus` alone does not distinguish those,
    /// so log the individual switches.
    static func logNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            func name(_ setting: UNNotificationSetting) -> String {
                switch setting {
                case .enabled:       return "enabled"
                case .disabled:      return "DISABLED"
                case .notSupported:  return "notSupported"
                @unknown default:    return "unknown"
                }
            }
            var style = "unknown"
            switch s.alertStyle {
            case .none:   style = "NONE (no banner or alert)"
            case .banner: style = "banner"
            case .alert:  style = "alert"
            @unknown default: break
            }
            var auth = "unknown"
            switch s.authorizationStatus {
            case .notDetermined:    auth = "notDetermined"
            case .denied:           auth = "DENIED"
            case .authorized:       auth = "authorized"
            case .provisional:      auth = "PROVISIONAL (quiet delivery)"
            case .ephemeral:        auth = "ephemeral"
            @unknown default:       break
            }

            print("""
            🔔 ── notification settings ──────────────────────────
            🔔 authorization : \(auth)
            🔔 alert style   : \(style)
            🔔 banners       : \(name(s.alertSetting))          ← off ⇒ no pop-up, but still in Notification Center
            🔔 lock screen   : \(name(s.lockScreenSetting))
            🔔 notif. center : \(name(s.notificationCenterSetting))
            🔔 sound         : \(name(s.soundSetting))
            🔔 badge         : \(name(s.badgeSetting))
            🔔 ─────────────────────────────────────────────────
            """)
            if s.alertSetting == .disabled && s.notificationCenterSetting == .enabled {
                print("🔔 ⚠️ Banners are OFF but Notification Center is ON — this is exactly the "
                      + "\"appears in the app's bell, never pops up\" symptom. "
                      + "Settings → Notifications → TrinhsGroup → enable Banners.")
            }
        }
    }

        cache.diskStorage.config.expiration = .days(7)
        cache.memoryStorage.config.expiration = .seconds(300) // 5 minutes in memory
        
        // Set maximum cache size (100 MB disk, 50 MB memory)
        cache.diskStorage.config.sizeLimit = 100 * 1024 * 1024 // 100 MB
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        // Enable automatic cache cleanup
        cache.cleanExpiredCache()
    }
    
}

extension Notification.Name {
    static let didTapOrderNotification = Notification.Name("didTapOrderNotification")
    static let sessionExpired = Notification.Name("sessionExpired")
}


extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("🔥 FCM token callback fired with nil token")
            return
        }
        print("🔥 FCM token received: \(token.prefix(24))… (length=\(token.count))")
        UserDefaults.standard.set(token, forKey: "fcm_token")
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": token]
        )
    }
}
