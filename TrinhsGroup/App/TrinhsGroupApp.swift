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
    @State private var showTokenExpiredAlert = false
    
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
                        // Check if token expired after splash screen
                        if authViewModel.isTokenExpired {
                            showTokenExpiredAlert = true
                        }
                    }
                }
            }
            .alert("Session Expired", isPresented: $showTokenExpiredAlert) {
                Button("OK") {
                    authViewModel.dismissTokenExpiredMessage()
                }
            } message: {
                Text("Your session has expired. Please log in again to continue.")
            }
            .onChange(of: authViewModel.isTokenExpired) { expired in
                if expired && isActive {
                    showTokenExpiredAlert = true
                }
            }
            .onOpenURL { url in
                // Handle deep link at app level
                print("App received deep link: \(url.absoluteString)")
                handleDeepLink(url: url, mainViewModel: mainViewModel)
            }
        }
    }
    
    // Handle deep link for payment completion
    private func handleDeepLink(url: URL, mainViewModel: MainViewModel) {
        guard url.scheme == "trinhsgroup",
              url.host == "checkout" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let orderId = components?.queryItems?.first(where: {$0.name == "order_id"})?.value
        let status = components?.queryItems?.first(where: {$0.name == "status"})?.value
        
        print("Deep link handled at app level - Order ID: \(orderId ?? "nil"), Status: \(status ?? "nil")")
        
        // Navigate to order received if payment was successful
        if let status = status, (status.lowercased() == "completed" || status.lowercased() == "processing" || status.lowercased() == "success") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                mainViewModel.reset()
                mainViewModel.presentedType = .orderReceived
            }
        }
    }
}
