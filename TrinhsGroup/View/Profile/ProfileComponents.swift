//
//  ProfileComponents.swift
//  TrinhsGroup
//
//  Modern Profile UI Components
//

import SwiftUI

// MARK: - User Identity Card
struct UserIdentityCard: View {
    let username: String
    let email: String
    let avatarURL: String?
    let points: Int
    let memberTier: MemberTierBadge.Tier
    var isLoadingPoints: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ProfileDesign.Spacing.md) {
                // Avatar with gradient border
                AvatarView(url: avatarURL, size: 72)
                
                // User info
                VStack(alignment: .leading, spacing: ProfileDesign.Spacing.xs) {
                    // Username
                    Text(username.isEmpty ? "Guest User" : username)
                        .font(ProfileDesign.Typography.headline)
                        .foregroundColor(ProfileDesign.Colors.textPrimary)
                        .lineLimit(1)
                    
                    // Email
                    Text(email.isEmpty ? "Not logged in" : email)
                        .font(ProfileDesign.Typography.subheadline)
                        .foregroundColor(ProfileDesign.Colors.textSecondary)
                        .lineLimit(1)
                    
                    // Points pill and member badge
                    HStack(spacing: ProfileDesign.Spacing.xs) {
                        PointsPill(points: points, isLoading: isLoadingPoints)
                        MemberTierBadge(tier: memberTier)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: ProfileDesign.Icons.chevronRight)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ProfileDesign.Colors.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(CardPressStyle())
        .profileCard(padding: ProfileDesign.Spacing.md, cornerRadius: ProfileDesign.Radius.xl)
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    let url: String?
    var size: CGFloat = 72
    
    var body: some View {
        ZStack {
            // Gradient border ring
            Circle()
                .stroke(ProfileDesign.Colors.avatarBorderGradient, lineWidth: 3)
                .frame(width: size + 6, height: size + 6)
            
            // Avatar image
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: size, height: size)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_):
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Navigation Tiles
struct NavigationTilesView: View {
    let ordersCount: Int
    var onAccountTap: () -> Void
    var onOrdersTap: () -> Void
    var onRewardsTap: () -> Void
    
    var body: some View {
        HStack(spacing: ProfileDesign.Spacing.sm) {
            NavigationTile(
                icon: ProfileDesign.Icons.accountFill,
                iconColor: .blue,
                title: "Account",
                subtitle: "Password, avatar",
                action: onAccountTap
            )
            
            NavigationTile(
                icon: ProfileDesign.Icons.ordersFill,
                iconColor: .orange,
                title: "My Orders",
                subtitle: "\(ordersCount) orders",
                action: onOrdersTap
            )
            
            NavigationTile(
                icon: ProfileDesign.Icons.rewardsFill,
                iconColor: .purple,
                title: "Rewards",
                subtitle: "Redeem vouchers",
                action: onRewardsTap
            )
        }
    }
}

struct NavigationTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ProfileDesign.Spacing.xs) {
                // Icon background
                ZStack {
                    RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Title
                Text(title)
                    .font(ProfileDesign.Typography.footnote.weight(.semibold))
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                    .lineLimit(1)
                
                // Subtitle
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

// MARK: - Rewards Quick Card
struct RewardsQuickCard: View {
    let points: Int
    var isLoading: Bool = false
    var onSeeAllTap: () -> Void
    var onRedeemTap: (Int, Int) -> Void // (amount, pointsCost)
    
    // 1 point = $1, so 10 points = $10 voucher
    private let redeemOptions: [(amount: Int, points: Int)] = [
        (10, 10),
        (20, 20),
        (50, 50),
        (100, 100)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            // Header
            ProfileSectionHeader(title: "Rewards", action: onSeeAllTap)
            
            // Points display
            if isLoading {
                HStack(spacing: ProfileDesign.Spacing.xs) {
                    SkeletonView(width: 80, height: 42, cornerRadius: 8)
                    SkeletonView(width: 50, height: 20, cornerRadius: 4)
                }
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
                        RedeemChip(
                            amount: option.amount,
                            pointsCost: option.points,
                            isEnabled: points >= option.points,
                            isLoading: isLoading,
                            onTap: { onRedeemTap(option.amount, option.points) }
                        )
                    }
                }
            }
        }
        .profileCard()
    }
}

struct RedeemChip: View {
    let amount: Int
    let pointsCost: Int
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                Group {
                    if isLoading {
                        RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                            .fill(Color.gray.opacity(0.2))
                            .shimmer()
                    } else if isEnabled {
                        RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                            .fill(ProfileDesign.Colors.rewardChipGradient)
                    } else {
                        RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                            .fill(Color.gray.opacity(0.15))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                    .strokeBorder(isEnabled ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(CardPressStyle())
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Voucher History Card
struct VoucherHistoryCard: View {
    let vouchers: [VoucherItem]
    var onSeeAllTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            ProfileSectionHeader(title: "Voucher History", action: onSeeAllTap)
            
            if vouchers.isEmpty {
                EmptyVoucherView()
            } else {
                VStack(spacing: ProfileDesign.Spacing.sm) {
                    ForEach(vouchers.prefix(2)) { voucher in
                        VoucherRow(voucher: voucher)
                        
                        if voucher.id != vouchers.prefix(2).last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
        }
        .profileCard()
    }
}

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

struct VoucherRow: View {
    let voucher: VoucherItem
    
    var body: some View {
        HStack(spacing: ProfileDesign.Spacing.sm) {
            // Voucher icon
            ZStack {
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: ProfileDesign.Icons.voucher)
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
            
            // Voucher info
            VStack(alignment: .leading, spacing: 2) {
                Text("$\(voucher.amount) Voucher")
                    .font(ProfileDesign.Typography.subheadline.weight(.medium))
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                
                Text(voucher.code)
                    .font(ProfileDesign.Typography.monospace)
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
                
                if let expiresAt = voucher.expiresAt {
                    Text("Expires: \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(ProfileDesign.Typography.caption2)
                        .foregroundColor(ProfileDesign.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Status badge
            VoucherStatusBadge(status: voucher.status)
        }
    }
}

struct VoucherStatusBadge: View {
    let status: VoucherItem.VoucherStatus
    
    var color: Color {
        switch status {
        case .active: return .green
        case .used: return .gray
        case .expired: return .red
        }
    }
    
    var text: String {
        switch status {
        case .active: return "Active"
        case .used: return "Used"
        case .expired: return "Expired"
        }
    }
    
    var icon: String {
        switch status {
        case .active: return ProfileDesign.Icons.checkmark
        case .used: return ProfileDesign.Icons.checkmark
        case .expired: return ProfileDesign.Icons.clock
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(ProfileDesign.Typography.caption2.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct EmptyVoucherView: View {
    var body: some View {
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
}

// MARK: - Preferences Card
struct PreferencesCard: View {
    @Binding var pushNotificationsEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            Text("Preferences")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
            
            HStack(spacing: ProfileDesign.Spacing.sm) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: ProfileDesign.Icons.bellFill)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                // Text
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
}

// MARK: - Help & Support Card
struct HelpSupportCard: View {
    var onContactTap: () -> Void
    var onFAQTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text("Help & Support")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.supportFill,
                iconColor: .teal,
                title: "Contact Support",
                action: onContactTap
            )
            
            Divider()
                .padding(.leading, 48)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.faqFill,
                iconColor: .indigo,
                title: "FAQ",
                action: onFAQTap
            )
        }
        .profileCard()
    }
}

// MARK: - Legal Card
struct LegalCard: View {
    var onTermsTap: () -> Void
    var onPrivacyTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text("Legal")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.termsFill,
                iconColor: .gray,
                title: "Terms of Service",
                action: onTermsTap
            )
            
            Divider()
                .padding(.leading, 48)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.privacyFill,
                iconColor: .gray,
                title: "Privacy Policy",
                action: onPrivacyTap
            )
        }
        .profileCard()
    }
}

// MARK: - Logout Button
struct LogoutButtonView: View {
    var onLogout: () -> Void
    
    var body: some View {
        Button(action: onLogout) {
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
    }
}

// MARK: - App Version Footer
struct AppVersionFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("App Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                .font(ProfileDesign.Typography.caption)
                .foregroundColor(ProfileDesign.Colors.textTertiary)
            
            Text("Made with ❤️ by TrinhsGroup")
                .font(ProfileDesign.Typography.caption2)
                .foregroundColor(ProfileDesign.Colors.textTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ProfileDesign.Spacing.lg)
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
