//
//  ProfileView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//  Redesigned with modern iOS 17 style
//

import SwiftUI
import PhotosUI
import Photos
import AVFoundation
import UIKit

// MARK: - Voucher Item Model
struct VoucherItem: Identifiable {
    let id: String
    let amount: Int
    let code: String
    let status: VoucherStatus
    let expiresAt: Date?
    
    enum VoucherStatus {
        case active, used, expired
    }
}

// MARK: - Design Tokens
struct ProfileDesign {
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }
    
    struct Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 18
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 100
    }
    
    struct Shadow {
        static let soft = ShadowStyle(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        static let elevated = ShadowStyle(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    struct Colors {
        static let primary = Color.accentColor
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let screenBackground = Color(uiColor: .systemGroupedBackground)
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        static let cardBackgroundElevated = Color(uiColor: .tertiarySystemBackground)
        static let textPrimary = Color(uiColor: .label)
        static let textSecondary = Color(uiColor: .secondaryLabel)
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        static let goldGradient = LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let silverGradient = LinearGradient(
            colors: [Color(hex: "C0C0C0"), Color(hex: "A8A8A8")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let avatarBorderGradient = LinearGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53"), Color(hex: "FF6B6B")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let pointsPillGradient = LinearGradient(
            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let rewardChipGradient = LinearGradient(
            colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        static let pointsLarge = Font.system(size: 42, weight: .bold, design: .rounded)
        static let pointsMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let pointsSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let monospace = Font.system(.caption, design: .monospaced)
    }
    
    struct Icons {
        static let account = "person.crop.circle"
        static let accountFill = "person.crop.circle.fill"
        static let orders = "bag"
        static let ordersFill = "bag.fill"
        static let rewards = "gift"
        static let rewardsFill = "gift.fill"
        static let points = "star.circle.fill"
        static let chevronRight = "chevron.right"
        static let bell = "bell"
        static let bellFill = "bell.fill"
        static let support = "questionmark.circle"
        static let supportFill = "questionmark.circle.fill"
        static let faq = "book"
        static let faqFill = "book.fill"
        static let terms = "doc.text"
        static let termsFill = "doc.text.fill"
        static let privacy = "lock.shield"
        static let privacyFill = "lock.shield.fill"
        static let logout = "rectangle.portrait.and.arrow.right"
        static let camera = "camera.fill"
        static let password = "key.fill"
        static let address = "location.fill"
        static let voucher = "ticket.fill"
        static let checkmark = "checkmark.circle.fill"
        static let clock = "clock.fill"
        static let xmark = "xmark.circle.fill"
    }
}

// MARK: - Card View Modifier
struct ProfileCardStyle: ViewModifier {
    var padding: CGFloat = ProfileDesign.Spacing.md
    var cornerRadius: CGFloat = ProfileDesign.Radius.lg
    var shadow: ProfileDesign.ShadowStyle = ProfileDesign.Shadow.soft
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(ProfileDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension View {
    func profileCard(
        padding: CGFloat = ProfileDesign.Spacing.md,
        cornerRadius: CGFloat = ProfileDesign.Radius.lg,
        shadow: ProfileDesign.ShadowStyle = ProfileDesign.Shadow.soft
    ) -> some View {
        modifier(ProfileCardStyle(padding: padding, cornerRadius: cornerRadius, shadow: shadow))
    }
}

// MARK: - Row Item
struct ProfileRowItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ProfileDesign.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ProfileDesign.Typography.body)
                        .foregroundColor(ProfileDesign.Colors.textPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(ProfileDesign.Typography.caption)
                            .foregroundColor(ProfileDesign.Colors.textSecondary)
                    }
                }
                Spacer()
                if showChevron {
                    Image(systemName: ProfileDesign.Icons.chevronRight)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ProfileDesign.Colors.textTertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
    }
}

// MARK: - Navigation Tile
struct NavigationTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ProfileDesign.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                Text(title)
                    .font(ProfileDesign.Typography.footnote.weight(.semibold))
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(ProfileDesign.Typography.caption2)
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ProfileDesign.Spacing.sm)
            .background(ProfileDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ProfileDesign.Radius.lg, style: .continuous))
            .shadow(color: ProfileDesign.Shadow.soft.color, radius: ProfileDesign.Shadow.soft.radius)
        }
        .buttonStyle(CardPressStyle())
    }
}

// MARK: - Card Press Style
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @StateObject private var pointsViewModel = PointsViewModel()
    
    @State private var showLogoutAlert = false
    @State private var showAccountCenter = false
    @State private var showRewardsCenter = false
    @State private var pushNotificationsEnabled = true
    @State private var showAvatarActionSheet = false
    @State private var showCameraPicker = false
    @State private var showDeleteAvatarConfirmation = false
    @State private var showAvatarErrorAlert = false
    @State private var avatarErrorMessage = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var localAvatarPreview: UIImage?
    @State private var isAvatarUpdating = false
    @State private var avatarRefreshToken = UUID()
    
    // Redeem confirmation state
    @State private var showRedeemConfirmation = false
    @State private var pendingRedeemAmount: Int = 0
    @State private var pendingRedeemPoints: Int = 0
    
    // Sample vouchers - replace with real data from API
    @State private var vouchers: [VoucherItem] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ProfileDesign.Colors.screenBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: ProfileDesign.Spacing.md) {
                        // Header Section - User Identity Card
                        userIdentityCard
                        
                        // Navigation Tiles
                        navigationTiles
                        
                        // Rewards Quick Card
                        rewardsQuickCard
                        
                        // Voucher History
                        voucherHistoryCard
                        
                        // Preferences
                        preferencesCard
                        
                        // Help & Support
                        helpSupportCard
                        
                        // Legal
                        legalCard
                        
                        // Logout Button
                        logoutButton
                        
                        // App Version Footer
                        appVersionFooter
                    }
                    .padding(.horizontal, ProfileDesign.Spacing.md)
                    .padding(.top, ProfileDesign.Spacing.sm)
                    .padding(.bottom, ProfileDesign.Spacing.xxl)
                }
                
                // Navigation Links (hidden)
                navigationLinks
                
                // Loading overlay
                if historyViewModel.showLoading || pointsViewModel.isLoading {
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
            .confirmationDialog("Cập nhật ảnh đại diện", isPresented: $showAvatarActionSheet, titleVisibility: .visible) {
                Button("Chọn từ thư viện") {
                    presentPhotoLibrary()
                }
                Button("Chụp ảnh mới") {
                    presentCamera()
                }
                if localAvatarPreview != nil || !authViewModel.localAvatarURL.isEmpty || !(authViewModel.user.avatar_url ?? "").isEmpty {
                    Button("Xóa ảnh đại diện", role: .destructive) {
                        showDeleteAvatarConfirmation = true
                    }
                }
                Button("Hủy", role: .cancel) { }
            } message: {
                Text("Chọn cách cập nhật avatar của bạn")
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: photoPickerItem) { item in
                guard let item else { return }
                Task {
                    await handlePickedPhoto(item)
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                AvatarCameraPicker { image in
                    Task {
                        await MainActor.run {
                            showCameraPicker = false
                        }
                        await uploadAvatarImage(image)
                    }
                }
                .ignoresSafeArea()
            }
            .alert("Xóa ảnh đại diện", isPresented: $showDeleteAvatarConfirmation) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    deleteAvatar()
                }
            } message: {
                Text("Avatar sẽ được đưa về ảnh mặc định.")
            }
            .alert("Avatar", isPresented: $showAvatarErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(avatarErrorMessage)
            }
        }
    }
    
    // MARK: - User Identity Card
    private var userIdentityCard: some View {
        HStack(spacing: ProfileDesign.Spacing.md) {
            avatarView
            
            Button(action: { authViewModel.showEditProfile = true }) {
                HStack(spacing: ProfileDesign.Spacing.md) {
                    VStack(alignment: .leading, spacing: ProfileDesign.Spacing.xs) {
                        Text(authViewModel.user.username.isEmpty ? "Guest User" : authViewModel.user.username)
                            .font(ProfileDesign.Typography.headline)
                            .foregroundColor(ProfileDesign.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Text(authViewModel.user.email.isEmpty ? "Not logged in" : authViewModel.user.email)
                            .font(ProfileDesign.Typography.subheadline)
                            .foregroundColor(ProfileDesign.Colors.textSecondary)
                            .lineLimit(1)
                        
                        pointsPill
                    }
                    
                    Spacer()
                    
                    Image(systemName: ProfileDesign.Icons.chevronRight)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ProfileDesign.Colors.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .profileCard(padding: ProfileDesign.Spacing.md, cornerRadius: ProfileDesign.Radius.xl)
    }
    
    private var avatarView: some View {
        ZStack {
            Circle()
                .strokeBorder(ProfileDesign.Colors.avatarBorderGradient, lineWidth: 3)
                .frame(width: 78, height: 78)
            
            if let localAvatarPreview {
                Image(uiImage: localAvatarPreview)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
            } else if let url = avatarDisplayURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    default:
                        defaultAvatarImage
                    }
                }
            } else {
                defaultAvatarImage
            }
        }
        .frame(width: 78, height: 78)
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showAvatarActionSheet = true }) {
                ZStack {
                    Circle()
                        .fill(ProfileDesign.Colors.primary)
                        .frame(width: 28, height: 28)
                    if isAvatarUpdating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: ProfileDesign.Icons.camera)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .disabled(isAvatarUpdating)
            .offset(x: 2, y: 2)
        }
    }
    
    private var defaultAvatarImage: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 72, height: 72)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
            )
    }
    
    private var pointsPill: some View {
        HStack(spacing: 6) {
            if pointsViewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.white)
            } else {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                
                Text("\(Int(pointsViewModel.balance ?? 0).formatted()) Points")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(ProfileDesign.Colors.pointsPillGradient)
        .clipShape(Capsule())
        .shadow(color: Color(hex: "667eea").opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Navigation Tiles
    private var navigationTiles: some View {
        HStack(spacing: ProfileDesign.Spacing.sm) {
            NavigationTile(
                icon: ProfileDesign.Icons.accountFill,
                iconColor: .blue,
                title: "Account",
                subtitle: "Password, avatar",
                action: { authViewModel.showEditProfile = true }
            )
            
            NavigationTile(
                icon: ProfileDesign.Icons.ordersFill,
                iconColor: .orange,
                title: "My Orders",
                subtitle: "\(historyViewModel.orders.count) orders",
                action: { mainViewModel.showOrderReceived = true }
            )
            
            NavigationTile(
                icon: ProfileDesign.Icons.rewardsFill,
                iconColor: .purple,
                title: "Rewards",
                subtitle: "Redeem vouchers",
                action: { showRewardsCenter = true }
            )
        }
    }
    
    // MARK: - Rewards Quick Card
    private var rewardsQuickCard: some View {
        let points = Int(pointsViewModel.balance ?? 0)
        // 1 point = $1, so 10 points = $10 voucher
        let redeemOptions: [(amount: Int, points: Int)] = [
            (10, 10), (20, 20), (50, 50), (100, 100)
        ]
        
        return VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            // Header
            HStack {
                Text("Rewards")
                    .font(ProfileDesign.Typography.headline)
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                
                Spacer()
                
                Button(action: { showRewardsCenter = true }) {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(ProfileDesign.Typography.subheadline)
                        Image(systemName: ProfileDesign.Icons.chevronRight)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(ProfileDesign.Colors.primary)
                }
            }
            
            // Points display
            if pointsViewModel.isLoading {
                SkeletonView(width: 80, height: 42, cornerRadius: 8)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: ProfileDesign.Spacing.xs) {
                    Text("\(points.formatted())")
                        .font(ProfileDesign.Typography.pointsLarge)
                        .foregroundStyle(ProfileDesign.Colors.primaryGradient)
                    
                    Text("points")
                        .font(ProfileDesign.Typography.subheadline)
                        .foregroundColor(ProfileDesign.Colors.textSecondary)
                }
            }
            
            // Redeem chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ProfileDesign.Spacing.sm) {
                    ForEach(redeemOptions, id: \.amount) { option in
                        redeemChip(amount: option.amount, pointsCost: option.points, currentPoints: points)
                    }
                }
            }
        }
        .profileCard()
    }
    
    private func redeemChip(amount: Int, pointsCost: Int, currentPoints: Int) -> some View {
        let isEnabled = currentPoints >= pointsCost
        
        return Button(action: { handleRedeem(amount: amount, points: pointsCost) }) {
            VStack(spacing: 4) {
                Text("$\(amount)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isEnabled ? .white : ProfileDesign.Colors.textTertiary)
                
                Text("\(pointsCost) pts")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isEnabled ? .white.opacity(0.8) : ProfileDesign.Colors.textTertiary.opacity(0.7))
            }
            .frame(width: 72, height: 56)
            .background(
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                    .fill(isEnabled ? ProfileDesign.Colors.rewardChipGradient : LinearGradient(colors: [Color.gray.opacity(0.15)], startPoint: .top, endPoint: .bottom))
            )
        }
        .buttonStyle(CardPressStyle())
        .disabled(!isEnabled)
    }
    
    // MARK: - Voucher History Card
    private var voucherHistoryCard: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            HStack {
                Text("Voucher History")
                    .font(ProfileDesign.Typography.headline)
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                
                Spacer()
            }
            
            if vouchers.isEmpty {
                emptyVoucherView
            } else {
                ForEach(vouchers.prefix(2)) { voucher in
                    voucherRow(voucher)
                }
            }
        }
        .profileCard()
    }
    
    private var emptyVoucherView: some View {
        VStack(spacing: ProfileDesign.Spacing.xs) {
            Image(systemName: ProfileDesign.Icons.voucher)
                .font(.system(size: 32))
                .foregroundColor(ProfileDesign.Colors.textTertiary)
            
            Text("No vouchers yet")
                .font(ProfileDesign.Typography.subheadline)
                .foregroundColor(ProfileDesign.Colors.textSecondary)
            
            Text("Redeem your points to get vouchers")
                .font(ProfileDesign.Typography.caption)
                .foregroundColor(ProfileDesign.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ProfileDesign.Spacing.lg)
    }
    
    private func voucherRow(_ voucher: VoucherItem) -> some View {
        HStack(spacing: ProfileDesign.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: ProfileDesign.Icons.voucher)
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("$\(voucher.amount) Voucher")
                    .font(ProfileDesign.Typography.subheadline.weight(.medium))
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                
                Text(voucher.code)
                    .font(ProfileDesign.Typography.monospace)
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            voucherStatusBadge(voucher.status)
        }
    }
    
    private func voucherStatusBadge(_ status: VoucherItem.VoucherStatus) -> some View {
        let (color, text): (Color, String) = {
            switch status {
            case .active: return (.green, "Active")
            case .used: return (.gray, "Used")
            case .expired: return (.red, "Expired")
            }
        }()
        
        return Text(text)
            .font(ProfileDesign.Typography.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
    
    // MARK: - Preferences Card
    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            Text("Preferences")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
            
            HStack(spacing: ProfileDesign.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: ProfileDesign.Icons.bellFill)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push Notifications")
                        .font(ProfileDesign.Typography.body)
                        .foregroundColor(ProfileDesign.Colors.textPrimary)
                    
                    Text("Receive order updates and offers")
                        .font(ProfileDesign.Typography.caption)
                        .foregroundColor(ProfileDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $pushNotificationsEnabled)
                    .labelsHidden()
                    .tint(ProfileDesign.Colors.primary)
            }
        }
        .profileCard()
    }
    
    // MARK: - Help & Support Card
    private var helpSupportCard: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text("Help & Support")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.supportFill,
                iconColor: .teal,
                title: "Contact Support",
                action: { openContactSupport() }
            )
            
            Divider().padding(.leading, 48)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.faqFill,
                iconColor: .indigo,
                title: "FAQ",
                action: { openFAQ() }
            )
        }
        .profileCard()
    }
    
    // MARK: - Legal Card
    private var legalCard: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text("Legal")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.termsFill,
                iconColor: .gray,
                title: "Terms of Service",
                action: { openTerms() }
            )
            
            Divider().padding(.leading, 48)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.privacyFill,
                iconColor: .gray,
                title: "Privacy Policy",
                action: { openPrivacy() }
            )
        }
        .profileCard()
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            HStack(spacing: ProfileDesign.Spacing.sm) {
                Image(systemName: ProfileDesign.Icons.logout)
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Logout")
                    .font(ProfileDesign.Typography.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: ProfileDesign.Radius.md, style: .continuous))
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(CardPressStyle())
        .padding(.top, ProfileDesign.Spacing.sm)
    }
    
    // MARK: - App Version Footer
    private var appVersionFooter: some View {
        VStack(spacing: 4) {
            Text("App Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                .font(ProfileDesign.Typography.caption)
                .foregroundColor(ProfileDesign.Colors.textTertiary)
            
            Text("Made with love by TrinhsGroup")
                .font(ProfileDesign.Typography.caption2)
                .foregroundColor(ProfileDesign.Colors.textTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ProfileDesign.Spacing.lg)
    }
    
    // MARK: - Navigation Links
    private var navigationLinks: some View {
        Group {
            NavigationLink(
                destination: EditProfileView()
                    .environmentObject(authViewModel),
                isActive: $authViewModel.showEditProfile
            ) { EmptyView() }
            .hidden()
            
            NavigationLink(
                destination: EditAddressView()
                    .environmentObject(authViewModel)
                    .environmentObject(mainViewModel),
                isActive: $authViewModel.showEditAddress
            ) { EmptyView() }
            .hidden()
            
            NavigationLink(
                destination: MyOrdersView(filter: .pastOnly)
                    .environmentObject(mainViewModel)
                    .environmentObject(historyViewModel)
                    .environmentObject(authViewModel),
                isActive: $mainViewModel.showOrderReceived
            ) { EmptyView() }
            .hidden()
        }
    }
    
    // MARK: - Helper Methods

    private var avatarDisplayURL: URL? {
        // Firebase Storage URL takes priority; falls back to WooCommerce avatar_url
        let urlString = authViewModel.localAvatarURL.isEmpty
            ? (authViewModel.user.avatar_url ?? "")
            : authViewModel.localAvatarURL
        guard !urlString.isEmpty else { return nil }
        let separator = urlString.contains("?") ? "&" : "?"
        return URL(string: "\(urlString)\(separator)app_avatar_refresh=\(avatarRefreshToken.uuidString)")
    }

    @MainActor
    private func handlePickedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                showAvatarError("Không thể đọc ảnh từ thư viện.")
                photoPickerItem = nil
                return
            }

            guard let image = UIImage(data: data) else {
                showAvatarError("Ảnh không hợp lệ hoặc không được hỗ trợ.")
                photoPickerItem = nil
                return
            }

            photoPickerItem = nil
            await uploadAvatarImage(image)
        } catch {
            photoPickerItem = nil
            showAvatarError(error.localizedDescription)
        }
    }

    @MainActor
    private func uploadAvatarImage(_ image: UIImage) async {
        guard !isAvatarUpdating else { return }
        isAvatarUpdating = true

        authViewModel.onUpdateAvatar(image: image) { result in
            switch result {
            case .success:
                localAvatarPreview = image
                avatarRefreshToken = UUID()
                authViewModel.onGetUser()
            case .failure(let error):
                showAvatarError(error.localizedDescription)
            }
            isAvatarUpdating = false
        }
    }

    private func deleteAvatar() {
        guard !isAvatarUpdating else { return }
        isAvatarUpdating = true

        authViewModel.onRemoveAvatar { result in
            switch result {
            case .success:
                localAvatarPreview = nil
                avatarRefreshToken = UUID()
                authViewModel.onGetUser()
            case .failure(let error):
                showAvatarError(error.localizedDescription)
            }
            isAvatarUpdating = false
        }
    }

    private func presentPhotoLibrary() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            showPhotoPicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showPhotoPicker = true
                    } else {
                        showAvatarError("Ứng dụng chưa được cấp quyền Thư viện ảnh. Vui lòng bật quyền trong Settings.")
                    }
                }
            }
        case .denied, .restricted:
            showAvatarError("Ứng dụng chưa được cấp quyền Thư viện ảnh. Vui lòng bật quyền trong Settings.")
        @unknown default:
            showAvatarError("Không thể truy cập Thư viện ảnh trên thiết bị này.")
        }
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAvatarError("Thiết bị này không hỗ trợ camera.")
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCameraPicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCameraPicker = true
                    } else {
                        showAvatarError("Ứng dụng chưa được cấp quyền Camera. Vui lòng bật quyền trong Settings.")
                    }
                }
            }
        case .denied, .restricted:
            showAvatarError("Ứng dụng chưa được cấp quyền Camera. Vui lòng bật quyền trong Settings.")
        @unknown default:
            showAvatarError("Không thể truy cập camera trên thiết bị này.")
        }
    }

    private func showAvatarError(_ message: String) {
        avatarErrorMessage = message
        showAvatarErrorAlert = true
    }

    private func loadData() {
        // Clear cache to ensure fresh data
        APIClient.clearCache()
        
        historyViewModel.fetchOrders(customerId: authViewModel.user.id)
        pointsViewModel.fetchPoints(userId: authViewModel.user.id)
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

private struct AvatarCameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            picker.dismiss(animated: true)

            if let image {
                onImagePicked(image)
            }
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(MainViewModel())
            .environmentObject(HistoryViewModel())
    }
}
