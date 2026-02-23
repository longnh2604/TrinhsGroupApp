//
//  ProfileDesignSystem.swift
//  TrinhsGroup
//
//  Modern iOS 17 Design System for Profile screens
//

import SwiftUI

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
    
    // MARK: - Spacing
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
    
    // MARK: - Corner Radius
    struct Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 18
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 100
    }
    
    // MARK: - Shadow
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
    
    // MARK: - Colors
    struct Colors {
        // Primary
        static let primary = Color.accentColor
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Backgrounds
        static let screenBackground = Color(uiColor: .systemGroupedBackground)
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        static let cardBackgroundElevated = Color(uiColor: .tertiarySystemBackground)
        
        // Text
        static let textPrimary = Color(uiColor: .label)
        static let textSecondary = Color(uiColor: .secondaryLabel)
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        
        // Semantic
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Accent gradients
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
    
    // MARK: - Typography
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
        
        // Special
        static let pointsLarge = Font.system(size: 42, weight: .bold, design: .rounded)
        static let pointsMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let pointsSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let monospace = Font.system(.caption, design: .monospaced)
    }
    
    // MARK: - Icons
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

// MARK: - Section Header
struct ProfileSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See all"
    
    var body: some View {
        HStack {
            Text(title)
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                            .font(ProfileDesign.Typography.subheadline)
                        Image(systemName: ProfileDesign.Icons.chevronRight)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(ProfileDesign.Colors.primary)
                }
            }
        }
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
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Text
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

// MARK: - Badge
struct ProfileBadge: View {
    enum BadgeType {
        case active, used, expired, gold, silver, basic
        
        var color: Color {
            switch self {
            case .active: return .green
            case .used: return .gray
            case .expired: return .red
            case .gold: return Color(hex: "FFD700")
            case .silver: return Color(hex: "C0C0C0")
            case .basic: return .blue
            }
        }
        
        var text: String {
            switch self {
            case .active: return "Active"
            case .used: return "Used"
            case .expired: return "Expired"
            case .gold: return "Gold"
            case .silver: return "Silver"
            case .basic: return "Basic"
            }
        }
    }
    
    let type: BadgeType
    var customText: String? = nil
    
    var body: some View {
        Text(customText ?? type.text)
            .font(ProfileDesign.Typography.caption2.weight(.semibold))
            .foregroundColor(type.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(type.color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Member Tier Badge
struct MemberTierBadge: View {
    enum Tier {
        case basic, silver, gold
        
        var gradient: LinearGradient {
            switch self {
            case .basic:
                return LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .silver:
                return ProfileDesign.Colors.silverGradient
            case .gold:
                return ProfileDesign.Colors.goldGradient
            }
        }
        
        var text: String {
            switch self {
            case .basic: return "Basic"
            case .silver: return "Silver"
            case .gold: return "Gold"
            }
        }
        
        var icon: String {
            switch self {
            case .basic: return "star"
            case .silver: return "star.fill"
            case .gold: return "crown.fill"
            }
        }
    }
    
    let tier: Tier
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tier.icon)
                .font(.system(size: 10, weight: .bold))
            Text(tier.text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tier.gradient)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Points Pill
struct PointsPill: View {
    let points: Int
    var isLoading: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.white)
            } else {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                
                Text("\(points.formatted()) Points")
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
}

// MARK: - Loading Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
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
            .shimmer()
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
