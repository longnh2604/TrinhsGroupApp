//
//  TrinhsGroupApp.swift
//  TrinhsGroup
//
//  Created by long on 27/06/2022.
//

import SwiftUI

@main
struct TrinhsGroupApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var mainViewModel = MainViewModel()
    @StateObject var historyViewModel = HistoryViewModel()
    @StateObject var firestoreManager = FirestoreManager()
    @State private var isActive = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isActive {
                    if !authViewModel.isLogin {
                        LogInView()
                            .environmentObject(authViewModel)
                            .preferredColorScheme(.light)
                    } else {
                        MainView()
                            .environmentObject(authViewModel)
                            .environmentObject(mainViewModel)
                            .environmentObject(historyViewModel)
                            .environmentObject(firestoreManager)
                    }
                } else {
                    SplashView()
                }
            }
            .onAppear {
                // Auto transition after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
