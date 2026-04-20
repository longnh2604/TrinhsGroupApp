//
//  NewProfileView.swift
//  TrinhsGroup
//
//  Modern iOS 17 Profile Screen
//

import SwiftUI

struct NewProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @StateObject private var pointsViewModel = PointsViewModel()
    
    @State private var showLogoutAlert = false
    @State private var showAccountCenter = false
    @State private var showRewardsCenter = false
    @State private var pushNotificationsEnabled = true
    
    // Redeem confirmation state
    @State private var showRedeemConfirmation = false
    @State private var pendingRedeemAmount: Int = 0
    @State private var pendingRedeemPoints: Int = 0
    
    // Sample vouchers - replace with real data
    @State private var vouchers: [VoucherItem] = [
        VoucherItem(id: "1", amount: 20, code: "RW123-ABCD1234", status: .active, expiresAt: Date().addingTimeInterval(86400 * 30)),
        VoucherItem(id: "2", amount: 10, code: "RW123-WXYZ5678", status: .used, expiresAt: nil)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ProfileDesign.Colors.screenBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: ProfileDesign.Spacing.md) {
                        // Header Section - User Identity Card
                        UserIdentityCard(
                            username: authViewModel.user.username,
                            email: authViewModel.user.email,
                            avatarURL: authViewModel.user.avatar_url,
                            points: Int(pointsViewModel.balance ?? 0),
                            memberTier: calculateMemberTier(),
                            isLoadingPoints: pointsViewModel.isLoading,
                            onTap: { showAccountCenter = true }
                        )
                        
                        // Navigation Tiles
                        NavigationTilesView(
                            ordersCount: historyViewModel.orders.count,
                            onAccountTap: { showAccountCenter = true },
                            onOrdersTap: { mainViewModel.showOrderReceived = true },
                            onRewardsTap: { showRewardsCenter = true }
                        )
                        
                        // Rewards Quick Card
                        RewardsQuickCard(
                            points: Int(pointsViewModel.balance ?? 0),
                            isLoading: pointsViewModel.isLoading,
                            onSeeAllTap: { showRewardsCenter = true },
                            onRedeemTap: { amount, points in
                                handleRedeem(amount: amount, points: points)
                            }
                        )
                        
                        // Voucher History
                        VoucherHistoryCard(
                            vouchers: vouchers,
                            onSeeAllTap: { showRewardsCenter = true }
                        )
                        
                        // Preferences
                        PreferencesCard(pushNotificationsEnabled: $pushNotificationsEnabled)
                        
                        // Help & Support
                        HelpSupportCard(
                            onContactTap: { openContactSupport() },
                            onFAQTap: { openFAQ() }
                        )
                        
                        // Legal
                        LegalCard(
                            onTermsTap: { openTerms() },
                            onPrivacyTap: { openPrivacy() }
                        )
                        
                        // Logout Button
                        LogoutButtonView(onLogout: { showLogoutAlert = true })
                            .padding(.top, ProfileDesign.Spacing.sm)
                        
                        // App Version Footer
                        AppVersionFooter()
                    }
                    .padding(.horizontal, ProfileDesign.Spacing.md)
                    .padding(.top, ProfileDesign.Spacing.sm)
                    .padding(.bottom, ProfileDesign.Spacing.xxl)
                }
                
                // Loading overlay
                if historyViewModel.showLoading {
                    LoadingView()
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadData()
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            // Redeem confirmation alert
            .alert("Redeem Points", isPresented: $showRedeemConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingRedeemAmount = 0
                    pendingRedeemPoints = 0
                }
                Button("Redeem", role: .destructive) {
                    confirmRedeem()
                }
            } message: {
                Text("Are you sure you want to redeem \(pendingRedeemPoints) points for a $\(pendingRedeemAmount) voucher?\n\nThis action cannot be undone.")
            }
            // Redeem success alert
            .alert("Voucher Created!", isPresented: $pointsViewModel.showRedeemSuccess) {
                Button("OK", role: .cancel) {
                    // Add the new voucher to the list
                    if let response = pointsViewModel.lastRedeemResponse {
                        let newVoucher = VoucherItem(
                            id: response.couponCode,
                            amount: Int(response.amount),
                            code: response.couponCode,
                            status: .active,
                            expiresAt: response.expirationDate
                        )
                        vouchers.insert(newVoucher, at: 0)
                    }
                    pointsViewModel.clearSuccess()
                    // Refresh points from server to ensure UI is in sync
                    pointsViewModel.fetchPoints(userId: authViewModel.user.id)
                }
            } message: {
                if let response = pointsViewModel.lastRedeemResponse {
                    Text("Your voucher code is:\n\(response.couponCode)\n\nValue: $\(Int(response.amount))\nRemaining points: \(Int(response.balance))")
                } else {
                    Text("Your voucher has been created successfully!")
                }
            }
            // Redeem error alert
            .alert("Redemption Failed", isPresented: $pointsViewModel.showRedeemError) {
                Button("OK", role: .cancel) {
                    pointsViewModel.clearError()
                }
            } message: {
                Text(pointsViewModel.message)
            }
            .sheet(isPresented: $showAccountCenter) {
                AccountCenterView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showRewardsCenter) {
                RewardsCenterView(
                    points: Int(pointsViewModel.balance ?? 0),
                    vouchers: vouchers,
                    isLoading: pointsViewModel.isLoading
                )
            }
            .background(
                // Hidden navigation links
                Group {
                    NavigationLink(
                        destination: MyOrdersView(filter: .pastOnly)
                            .environmentObject(mainViewModel)
                            .environmentObject(historyViewModel)
                            .environmentObject(authViewModel),
                        isActive: $mainViewModel.showOrderReceived
                    ) { EmptyView() }
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadData() {
        // Clear cache to ensure fresh data
        APIClient.clearCache()
        
        historyViewModel.fetchOrders(customerId: authViewModel.user.id)
        pointsViewModel.fetchPoints(userId: authViewModel.user.id)
    }
    
    private func calculateMemberTier() -> MemberTierBadge.Tier {
        let points = Int(pointsViewModel.balance ?? 0)
        if points >= 1000 {
            return .gold
        } else if points >= 500 {
            return .silver
        } else {
            return .basic
        }
    }
    
    private func handleRedeem(amount: Int, points: Int) {
        // Check if user has enough points
        guard pointsViewModel.canRedeem(points: points) else {
            pointsViewModel.message = "You need \(points) points to redeem a $\(amount) voucher."
            pointsViewModel.showRedeemError = true
            return
        }
        
        // Set pending redeem info and show confirmation
        pendingRedeemAmount = amount
        pendingRedeemPoints = points
        showRedeemConfirmation = true
    }
    
    private func confirmRedeem() {
        // Call the redeem API
        pointsViewModel.redeemPoints(userId: authViewModel.user.id, points: pendingRedeemPoints)
        
        // Reset pending state
        pendingRedeemAmount = 0
        pendingRedeemPoints = 0
    }
    
    private func handleLogout() {
        authViewModel.logout()
    }
    
    private func openContactSupport() {
        // TODO: Implement contact support
    }
    
    private func openFAQ() {
        // TODO: Implement FAQ
    }
    
    private func openTerms() {
        // TODO: Implement terms
    }
    
    private func openPrivacy() {
        // TODO: Implement privacy
    }
}

// MARK: - Preview
struct NewProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NewProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(MainViewModel())
            .environmentObject(HistoryViewModel())
    }
}
