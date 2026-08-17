//
//  MyVouchersView.swift
//  TrinhsGroup
//
//  Wallet screen: available vouchers with copyable codes + redemption history.
//

import SwiftUI

struct MyVouchersView: View {
    @ObservedObject var pointsViewModel: PointsViewModel
    let userId: Int

    @Environment(\.dismiss) private var dismiss

    private enum Segment: Int, CaseIterable {
        case available, history
        var title: String {
            switch self {
            case .available: return "Available"
            case .history: return "History"
            }
        }
    }

    @State private var segment: Segment = .available
    @State private var copiedCode: String?

    private var activeVouchers: [VoucherResponse] {
        pointsViewModel.allVouchers.filter { $0.status == "active" }
    }

    private var historyVouchers: [VoucherResponse] {
        pointsViewModel.allVouchers.filter { $0.status != "active" }
    }

    private var totalAvailableValue: Int {
        Int(activeVouchers.reduce(0) { $0 + $1.amount })
    }

    var body: some View {
        ZStack {
            ProfileDesign.Colors.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBarView(title: "My Vouchers")

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: ProfileDesign.Spacing.lg) {
                        summaryHero
                        segmentPicker

                        if pointsViewModel.isLoadingAllVouchers && pointsViewModel.allVouchers.isEmpty {
                            loadingState
                        } else {
                            switch segment {
                            case .available: availableList
                            case .history: historyList
                            }
                        }
                    }
                    .padding(.horizontal, ProfileDesign.Spacing.md)
                    .padding(.top, ProfileDesign.Spacing.md)
                    .padding(.bottom, ProfileDesign.Spacing.xxl)
                }
                .refreshable { pointsViewModel.fetchAllVouchers(userId: userId) }
            }

            if let code = copiedCode {
                copyToast(code: code)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear { pointsViewModel.fetchAllVouchers(userId: userId) }
    }

    // MARK: - Summary Hero
    private var summaryHero: some View {
        VStack(spacing: ProfileDesign.Spacing.xs) {
            Text("AVAILABLE BALANCE")
                .font(ProfileDesign.Typography.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.85))

            Text("$\(totalAvailableValue)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(activeVouchers.count == 1
                 ? "1 voucher ready to use"
                 : "\(activeVouchers.count) vouchers ready to use")
                .font(ProfileDesign.Typography.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ProfileDesign.Spacing.xl)
        .background(
            ZStack {
                ProfileDesign.Colors.primaryGradient
                Image(systemName: "ticket.fill")
                    .font(.system(size: 140))
                    .foregroundColor(.white.opacity(0.08))
                    .rotationEffect(.degrees(-15))
                    .offset(x: 110, y: 10)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: ProfileDesign.Radius.xl, style: .continuous))
        .shadow(color: Color(hex: "EE5A5A").opacity(0.35), radius: 16, x: 0, y: 8)
    }

    // MARK: - Segment Picker
    private var segmentPicker: some View {
        Picker("", selection: $segment) {
            ForEach(Segment.allCases, id: \.self) { seg in
                Text(seg.title).tag(seg)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Available List
    @ViewBuilder
    private var availableList: some View {
        if activeVouchers.isEmpty {
            emptyState(
                icon: "ticket",
                title: "No vouchers yet",
                message: "Redeem your points to get vouchers. They'll appear here ready to use at checkout."
            )
        } else {
            VStack(spacing: ProfileDesign.Spacing.md) {
                ForEach(activeVouchers) { voucher in
                    VoucherTicket(voucher: voucher) { copy(voucher.code) }
                }
            }
        }
    }

    // MARK: - History List
    @ViewBuilder
    private var historyList: some View {
        if historyVouchers.isEmpty {
            emptyState(
                icon: "clock.arrow.circlepath",
                title: "No history yet",
                message: "Vouchers you've used or that have expired will show up here."
            )
        } else {
            VStack(spacing: ProfileDesign.Spacing.sm) {
                ForEach(historyVouchers) { voucher in
                    VoucherHistoryRowView(voucher: voucher)
                }
            }
        }
    }

    // MARK: - States
    private var loadingState: some View {
        VStack(spacing: ProfileDesign.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonView(height: 96, cornerRadius: ProfileDesign.Radius.lg)
            }
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: ProfileDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ProfileDesign.Colors.textTertiary)

            Text(title)
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)

            Text(message)
                .font(ProfileDesign.Typography.subheadline)
                .foregroundColor(ProfileDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ProfileDesign.Spacing.xxl)
        .padding(.horizontal, ProfileDesign.Spacing.lg)
    }

    // MARK: - Copy Toast
    private func copyToast(code: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: ProfileDesign.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Copied \(code)")
                    .font(ProfileDesign.Typography.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, ProfileDesign.Spacing.md)
            .padding(.vertical, ProfileDesign.Spacing.sm)
            .background(Color.black.opacity(0.85))
            .clipShape(Capsule())
            .padding(.bottom, ProfileDesign.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func copy(_ code: String) {
        UIPasteboard.general.string = code
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            copiedCode = code
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.25)) {
                if copiedCode == code { copiedCode = nil }
            }
        }
    }
}

// MARK: - Voucher Ticket (active)
private struct VoucherTicket: View {
    let voucher: VoucherResponse
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Left stub — amount
            VStack(spacing: 2) {
                Text("$\(Int(voucher.amount))")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("OFF")
                    .font(ProfileDesign.Typography.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 104)
            .frame(maxHeight: .infinity)
            .background(ProfileDesign.Colors.primaryGradient)

            // Perforation
            PerforationLine()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .foregroundColor(ProfileDesign.Colors.textTertiary.opacity(0.4))
                .frame(width: 1)
                .padding(.vertical, ProfileDesign.Spacing.sm)

            // Right — code + details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text("Active")
                        .font(ProfileDesign.Typography.caption.weight(.semibold))
                        .foregroundColor(.green)
                }

                Text(voucher.code)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Valid until \(voucher.formattedExpiryDate)")
                    .font(ProfileDesign.Typography.caption)
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
            }
            .padding(.leading, ProfileDesign.Spacing.md)
            .padding(.vertical, ProfileDesign.Spacing.md)

            Spacer(minLength: ProfileDesign.Spacing.xs)

            Button(action: onCopy) {
                VStack(spacing: 4) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Copy")
                        .font(ProfileDesign.Typography.caption2.weight(.semibold))
                }
                .foregroundColor(ProfileDesign.Colors.primary)
                .frame(width: 56)
            }
            .padding(.trailing, ProfileDesign.Spacing.sm)
        }
        .frame(height: 96)
        .background(ProfileDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ProfileDesign.Radius.lg, style: .continuous))
        .shadow(color: ProfileDesign.Shadow.soft.color, radius: ProfileDesign.Shadow.soft.radius, y: ProfileDesign.Shadow.soft.y)
        .overlay(notches)
    }

    /// Two background-coloured half-circles punched into the top and bottom edges at
    /// the perforation, giving the ticket its torn-stub silhouette (iOS 16 safe — no
    /// Path.subtracting, which is iOS 17+).
    private var notches: some View {
        GeometryReader { geo in
            let notchX: CGFloat = 104
            Group {
                Circle()
                    .fill(ProfileDesign.Colors.screenBackground)
                    .frame(width: 16, height: 16)
                    .position(x: notchX, y: 0)
                Circle()
                    .fill(ProfileDesign.Colors.screenBackground)
                    .frame(width: 16, height: 16)
                    .position(x: notchX, y: geo.size.height)
            }
        }
    }
}

// MARK: - History Row (used / expired)
private struct VoucherHistoryRowView: View {
    let voucher: VoucherResponse

    private var isUsed: Bool { voucher.status == "used" }
    private var statusColor: Color { isUsed ? ProfileDesign.Colors.textSecondary : ProfileDesign.Colors.error }
    private var statusText: String { isUsed ? "Used" : "Expired" }

    var body: some View {
        HStack(spacing: ProfileDesign.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.sm, style: .continuous)
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: isUsed ? "checkmark" : "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("$\(Int(voucher.amount)) Voucher")
                    .font(ProfileDesign.Typography.body.weight(.medium))
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
                Text(voucher.code)
                    .font(ProfileDesign.Typography.monospace)
                    .foregroundColor(ProfileDesign.Colors.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            Text(statusText)
                .font(ProfileDesign.Typography.caption2.weight(.semibold))
                .foregroundColor(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(ProfileDesign.Spacing.sm)
        .background(ProfileDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ProfileDesign.Radius.md, style: .continuous))
    }
}

// MARK: - Shapes
private struct PerforationLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Preview
struct MyVouchersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyVouchersView(pointsViewModel: PointsViewModel(), userId: 1)
        }
    }
}
