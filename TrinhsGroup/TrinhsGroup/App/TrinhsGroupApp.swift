//
//  TrinhsGroupApp.swift
//  TrinhsGroup
//
//  Created by long on 27/06/2022.
//

import SwiftUI
import SwiftyJSON
import CoreData
import Firebase

@main
struct TrinhsGroupApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    @ObservedObject var authViewModel = AuthViewModel()
//    @ObservedObject var mainViewModel = MainViewModel()
//    @ObservedObject var historyViewModel = HistoryViewModel()
    
    var body: some Scene {
        WindowGroup {
            if isOnboarding && ONBOARD_ENABLED {
                OnboardingView()
                    .preferredColorScheme(.light)
            }else{
                if !authViewModel.isLogin {
                    SignupView()
                        .environmentObject(authViewModel)
                        .preferredColorScheme(.light)
                } else {
//                    MainView()
//                        .environmentObject(authViewModel)
//                        .environmentObject(mainViewModel)
//                        .environmentObject(historyViewModel)
                }
            }
        }
                
    }
}
