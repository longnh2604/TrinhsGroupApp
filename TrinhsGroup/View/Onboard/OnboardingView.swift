//
//  OnboardingView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//  Rewritten 2026-09-03: the 2022 carousel advertised discount codes and bank
//  transfer / PayID, both retired by the trinh-app/v1 migration.
//

import SwiftUI

/// First-launch welcome carousel. Shown once before `MainView`, gated on
/// `hasSeenOnboarding`; skipping and finishing both set the flag.
///
/// Each slide previews the real screen it describes — category art from the menu,
/// an add-on group, the pickup time slots, a voucher — rather than a generic icon,
/// so the app looks familiar by the time the carousel ends.
struct OnboardingView: View {

    @AppStorage(OnboardingView.seenKey) private var hasSeenOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    static let seenKey = "hasSeenOnboarding"

    private enum Slide: Int, CaseIterable {
        case menu, addOns, pickup, rewards

        var title: String {
            switch self {
            case .menu: return L10n.Onboarding.menuTitle
            case .addOns: return L10n.Onboarding.addOnsTitle
            case .pickup: return L10n.Onboarding.pickupTitle
            case .rewards: return L10n.Onboarding.rewardsTitle
            }
        }

        var body: String {
            switch self {
            case .menu: return L10n.Onboarding.menuBody
            case .addOns: return L10n.Onboarding.addOnsBody
            case .pickup: return L10n.Onboarding.pickupBody
            case .rewards: return L10n.Onboarding.rewardsBody
            }
        }

        /// Each slide gets its own wash so four screens in a row do not read as one.
        var tint: Color {
            switch self {
            case .menu: return Constants.AppColor.lightRose
            case .addOns: return Constants.AppColor.lightGreen
            case .pickup: return Constants.AppColor.lightGrayColor
            case .rewards: return Constants.AppColor.lightRose
            }
        }
    }

    private var isLastPage: Bool { page == Slide.allCases.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            skipButton

            TabView(selection: $page) {
                ForEach(Slide.allCases, id: \.rawValue) { slide in
                    slideBody(slide)
                        .tag(slide.rawValue)
                }
            }
            // The built-in dots render pale grey on this white background, so they are
            // hidden and drawn below in the brand red instead.
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageDots
            primaryButton
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button(action: finish) {
                Text(L10n.Onboarding.skip.localizedKey)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func slideBody(_ slide: Slide) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            art(for: slide)
                .padding(24)
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(slide.tint)
                )
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(slide.title.localizedKey)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                    .multilineTextAlignment(.center)

                Text(slide.body.localizedKey)
                    .font(.system(size: 16))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // One VoiceOver element per slide, so a swipe reads the whole thing.
        .accessibilityElement(children: .combine)
    }

    // MARK: - Slide art
    //
    // Sample dish names, prices and times below are illustrative content for the
    // preview cards, not live data, so they are deliberately not localized.

    @ViewBuilder
    private func art(for slide: Slide) -> some View {
        switch slide {
        case .menu: menuArt
        case .addOns: addOnsArt
        case .pickup: pickupArt
        case .rewards: rewardsArt
        }
    }

    /// The real category illustrations already shipped in the asset catalog.
    private var menuArt: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                categoryTile(AppAssets.pho_cate, "Phở")
                categoryTile(AppAssets.banhmi_cate, "Bánh Mì")
            }
            HStack(spacing: 14) {
                categoryTile(AppAssets.ricedishes_cate, "Rice")
                categoryTile(AppAssets.drink_cate, "Drinks")
            }
        }
    }

    private func categoryTile(_ asset: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Constants.AppColor.primaryBlack)
        }
        .frame(width: 108, height: 96)
        .background(card)
    }

    /// Mirrors an add-on group on the product screen: a required group with priced options.
    private var addOnsArt: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Choose your size")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                Spacer()
                Text("Required")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Constants.AppColor.primaryRed))
            }
            optionRow("Regular", price: nil, selected: false)
            optionRow("Large", price: "+$3.00", selected: true)
            optionRow("Extra beef", price: "+$4.50", selected: false)
        }
        .padding(16)
        .background(card)
    }

    private func optionRow(_ label: String, price: String?, selected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 17))
                .foregroundColor(selected ? Constants.AppColor.primaryRed : Constants.AppColor.shadowColor)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Constants.AppColor.primaryBlack)
            Spacer()
            if let price = price {
                Text(price)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
        }
    }

    /// Mirrors `PickupDateTimeView`, which offers same-day slots only.
    private var pickupArt: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundColor(Constants.AppColor.primaryRed)
                Text("Pickup today")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Constants.AppColor.primaryBlack)
            }
            HStack(spacing: 8) {
                timeChip("11:30 AM", selected: false)
                timeChip("12:00 PM", selected: true)
                timeChip("12:30 PM", selected: false)
            }
        }
        .padding(16)
        .background(card)
    }

    private func timeChip(_ label: String, selected: Bool) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(selected ? .white : Constants.AppColor.secondaryBlack)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? Constants.AppColor.primaryRed : Color.white)
            )
            .overlay(
                Capsule().stroke(Constants.AppColor.shadowColor, lineWidth: selected ? 0 : 1)
            )
    }

    /// Mirrors the points balance and the voucher rows on the checkout sheet.
    private var rewardsArt: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Constants.AppColor.primaryRed)
                Text("320 points")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                Spacer()
                Text("Redeem")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Constants.AppColor.primaryRed)
            }
            .padding(14)
            .background(card)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("$5 voucher")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Constants.AppColor.primaryRed)
                    Text("Applied at checkout")
                        .font(.system(size: 11))
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                }
                Spacer()
                Image(systemName: "gift.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Constants.AppColor.primaryRed)
            }
            .padding(14)
            .background(card)
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: Constants.AppColor.shadowColor, radius: 6, x: 0, y: 3)
    }

    // MARK: - Controls

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(Slide.allCases, id: \.rawValue) { slide in
                Capsule()
                    .fill(slide.rawValue == page ? Constants.AppColor.primaryRed : Constants.AppColor.shadowColor)
                    .frame(width: slide.rawValue == page ? 22 : 8, height: 8)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: page)
        .padding(.bottom, 24)
        .accessibilityHidden(true)
    }

    private var primaryButton: some View {
        Button(action: advance) {
            Text((isLastPage ? L10n.Onboarding.getStarted : L10n.Onboarding.next).localizedKey)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Constants.AppColor.gradientRedHorizontal)
                .cornerRadius(27)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    private func advance() {
        guard !isLastPage else {
            finish()
            return
        }
        if reduceMotion {
            page += 1
        } else {
            withAnimation { page += 1 }
        }
    }

    private func finish() {
        hasSeenOnboarding = true
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
