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

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @AppStorage("notifications") var notifications: Int = 0
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // STPTestingPublishableKey
        STPAPIClient.shared.publishableKey = "pk_live_51KY9yTFxroI2z58cos6LBBuBu2jCrYNbLvaRx0C4JF3yjxFnPAYIWu8PEpFH9td9r7kM4ul41fy84PY1zLS3vpbX00dqy98QcG"
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
          return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)          {
        print(deviceToken)
        Messaging.messaging().apnsToken = deviceToken
        updateFCMToken()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
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
    
//    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.badge, .sound])
//
//        let userInfo:NSDictionary = notification.request.content.userInfo as NSDictionary
//        print(userInfo)
//        let dict:NSDictionary = userInfo["aps"] as! NSDictionary
//        let data:NSDictionary = dict["alert"] as! NSDictionary
//
//        UserDefaultsManager.save(AppNotification(title: (data["title"] as? String) ?? "", content: (data["body"] as? String) ?? ""))
//        UserDefaultsManager.saveNew(AppNotification(title: (data["title"] as? String) ?? "", content: (data["body"] as? String) ?? ""))
//        notifications = UserDefaultsManager.loadNew().count
//    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        let userInfo:NSDictionary = response.notification.request.content.userInfo as NSDictionary
//        print(userInfo)
//        let dict:NSDictionary = userInfo["aps"] as! NSDictionary
//        let data:NSDictionary = dict["alert"] as! NSDictionary
//
//        UserDefaultsManager.save(AppNotification(title: (data["title"] as? String) ?? "", content: (data["body"] as? String) ?? ""))
//        UserDefaultsManager.saveNew(AppNotification(title: (data["title"] as? String) ?? "", content: (data["body"] as? String) ?? ""))
//        notifications = UserDefaultsManager.loadNew().count
    }
    
    fileprivate func updateFCMToken() {
//        Messaging.messaging().token { token, error in
//            if let refreshedToken = token {
//                let systemVersion = UIDevice.current.systemVersion
//                print("iOS\(systemVersion)")
//
//                //iPhone or iPad
//                let model = UIDevice.current.model
//
//                print("device type=\(model)")
//                let deviceID = UIDevice.current.identifierForVendor!.uuidString
//                print(deviceID)
//                print("InstanceID token: \(refreshedToken)")
//
//                
//                // Prepare URL"
//                let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/woo-tools-app/fcm/register")
//                guard let requestUrl = url else { fatalError() }
//                // Prepare URL Request Object
//                var request = URLRequest(url: requestUrl)
//                request.httpMethod = "POST"
//                request.setValue(SECURITY_CODE, forHTTPHeaderField:"Security")
//
//                // HTTP Request Parameters which will be sent in HTTP Request Body
//                let postString = "device_id=\(deviceID)&device_name=\(model)&os_version=\(systemVersion)&regid=\(refreshedToken)";
//                // Set HTTP Request Body
//                request.httpBody = postString.data(using: String.Encoding.utf8);
//                // Perform HTTP Request
//                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//
//                    // Check for Error
//                    if let error = error {
//                        print("Error took place \(error)")
//                        return
//                    }
//                    let json = JSON(data!)
//                    print(json)
//
//                }
//                task.resume()
//            }
//        }
    }
}


extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        let dataDict:[String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        updateFCMToken()
    }
}
