//
//  RewardsCenterView.swift
//  TrinhsGroup
//
//  Rewards Center - Points dashboard with redeem grid and voucher history
//

import SwiftUI

struct RewardsCenterView: View {
    @Environment(\.dismiss) private var dismiss
    
    let points: Int
    let vouchers: [VoucherItem]
    var isLoading: Bool = false
    
    @State private var selectedTab = 0
    
    private let redeemOptions: [(amount: Int, points: Int)] = [
        (5, 50),
        (10, 100),
        (20, 200),
        (30, 300),
        (50, 500),
        (100, 1000)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                ProfileDesign.Colors.screenBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: ProfileDesign.Spacing.lg) {
                        // Points Dashboard Card
                        PointsDashboardCard(points: points, isLoading: isLoading)
                        
                        // Tab Selector
                        TabSelectorView(selectedTab: $selectedTab)
                        
                        // Content based on tab
                        if selectedTab == 0 {
                            // Redeem Vouchers Grid
                            RedeemGridView(
                                points: points,
                                options: redeemOptions,
                                isLoading: isLoading
                            )
                        } else {
                            // Voucher History
                            VoucherHistoryListView(vouchers: vouchers)
                        }
                    }
                    .padding(.horizontal, ProfileDesign.Spacing.md)
                    .padding(.top, ProfileDesign.Spacing.sm)
                    .padding(.bottom, ProfileDesign.Spacing.xxl)
                }
            }
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Points Dashboard Card
struct PointsDashboardCard: View {
    let points: Int
    var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: ProfileDesign.Spacing.md) {
            // Points circle
            ZStack {
                // Background circles
                Circle()
                    .stroke(
                        ProfileDesign.Colors.pointsPillGradient,
                        lineWidth: 8
                    )
                    .frame(width: 140, height: 140)
                    .opacity(0.2)
                
                Circle()
                    .stroke(
                        ProfileDesign.Colors.pointsPillGradient,
                        lineWidth: 8
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .opacity(0.8)
                
                // Points value
                VStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        Text("\(points.formatted())")
                            .font(ProfileDesign.Typography.pointsLarge)
                            .foregroundStyle(ProfileDesign.Colors.pointsPillGradient)
                        
                        Text("points")
                            .font(ProfileDesign.Typography.caption)
                            .foregroundColor(ProfileDesign.Colors.textSecondary)
                    }
                }
            }
            
            // Member tier
            HStack(spacing: ProfileDesign.Spacing.sm) {
                MemberTierBadge(tier: calculateTier(points: points))
                
                Text("Member")
                    .font(ProfileDesign.Typography.subheadline)
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
            }
            
            // Info text
            Text("Earn 1 point for every $20 spent")
                .font(ProfileDesign.Typography.caption)
                .foregroundColor(ProfileDesign.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ProfileDesign.Spacing.xl)
        .profileCard(cornerRadius: ProfileDesign.Radius.xxl)
    }
    
    private func calculateTier(points: Int) -> MemberTierBadge.Tier {
        if points >= 1000 { return .gold }
        else if points >= 500 { return .silver }
        else { return .basic }
    }
}

// MARK: - Tab Selector
struct TabSelectorView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Redeem", isSelected: selectedTab == 0) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }
            
            TabButton(title: "History", isSelected: selectedTab == 1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }
        }
        .padding(4)
        .background(ProfileDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous))
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ProfileDesign.Typography.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : ProfileDesign.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ProfileDesign.Spacing.sm)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                                .fill(ProfileDesign.Colors.primary)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Redeem Grid View
struct RedeemGridView: View {
    let points: Int
    let options: [(amount: Int, points: Int)]
    var isLoading: Bool = false
    
    let columns = [
        GridItem(.flexible(), spacing: ProfileDesign.Spacing.sm),
        GridItem(.flexible(), spacing: ProfileDesign.Spacing.sm),
        GridItem(.flexible(), spacing: ProfileDesign.Spacing.sm)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            Text("Redeem Vouchers")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
            
            LazyVGrid(columns: columns, spacing: ProfileDesign.Spacing.sm) {
                ForEach(options, id: \.amount) { option in
                    RedeemGridItem(
                        amount: option.amount,
                        pointsCost: option.points,
                        isEnabled: points >= option.points,
                        isLoading: isLoading
                    ) {
                        // Handle redeem
                        print("Redeem $\(option.amount)")
                    }
                }
            }
            
            // Info text
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("Vouchers are valid for 30 days after redemption")
                    .font(ProfileDesign.Typography.caption)
            }
            .foregroundColor(ProfileDesign.Colors.textTertiary)
            .padding(.top, ProfileDesign.Spacing.xs)
        }
        .profileCard()
    }
}

struct RedeemGridItem: View {
    let amount: Int
    let pointsCost: Int
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: ProfileDesign.Spacing.xs) {
                // Amount
                Text("$\(amount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isEnabled ? ProfileDesign.Colors.textPrimary : ProfileDesign.Colors.textTertiary)
                
                // Points cost
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("\(pointsCost)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(isEnabled ? .orange : ProfileDesign.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.md, style: .continuous)
                    .fill(isEnabled ? ProfileDesign.Colors.cardBackgroundElevated : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.md, style: .continuous)
                    .strokeBorder(
                        isEnabled ? ProfileDesign.Colors.primary.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(CardPressStyle())
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Voucher History List
struct VoucherHistoryListView: View {
    let vouchers: [VoucherItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.md) {
            Text("Voucher History")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
            
            if vouchers.isEmpty {
                EmptyVoucherView()
            } else {
                VStack(spacing: ProfileDesign.Spacing.sm) {
                    ForEach(vouchers) { voucher in
                        VoucherHistoryRow(voucher: voucher)
                    }
                }
            }
        }
        .profileCard()
    }
}

struct VoucherHistoryRow: View {
    let voucher: VoucherItem
    
    var body: some View {
        HStack(spacing: ProfileDesign.Spacing.sm) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: ProfileDesign.Icons.voucher)
                    .font(.system(size: 20))
                    .foregroundColor(statusColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(voucher.amount) Voucher")
                    .font(ProfileDesign.Typography.body.weight(.medium))
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
            
            // Status
            VoucherStatusBadge(status: voucher.status)
        }
        .padding(ProfileDesign.Spacing.sm)
        .background(ProfileDesign.Colors.cardBackgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous))
    }
    
    private var statusColor: Color {
        switch voucher.status {
        case .active: return .green
        case .used: return .gray
        case .expired: return .red
        }
    }
}

// MARK: - Preview
struct RewardsCenterView_Previews: PreviewProvider {
    static var previews: some View {
        RewardsCenterView(
            points: 450,
            vouchers: [
                VoucherItem(id: "1", amount: 20, code: "RW123-ABCD", status: .active, expiresAt: Date().addingTimeInterval(86400 * 30)),
                VoucherItem(id: "2", amount: 10, code: "RW123-WXYZ", status: .used, expiresAt: nil)
            ]
        )
    }
}
