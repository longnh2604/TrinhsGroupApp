//
//  OrderProgressCard.swift
//  TrinhsGroup
//
//  The order status hero and progress rail. All copy, colour and stage logic comes from
//  OrderStatusPresentation / OrderProgressBuilder — this file only draws.
//

import SwiftUI

struct OrderProgressCard: View {

    var order: Order
    /// Timestamped stages from the server. Empty is normal — see `timeline`.
    var events: [OrderTimelineEvent]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulse = false
    @State private var railFilled = false
    @State private var heroAppeared = false

    private var presentation: OrderStatusPresentation {
        OrderStatusPresentation(status: order.status)
    }

    /// Falls back to the order's own dates when the server gave us no history — because it
    /// predates the endpoint, the request failed, or the order is too old to have notes.
    private var timeline: [OrderTimelineEvent] {
        events.isEmpty ? OrderProgressBuilder.fallbackEvents(for: order) : events
    }

    private var steps: [OrderStep] {
        OrderProgressBuilder.steps(status: order.status, events: timeline)
    }

    /// Governs the *pulse* — the expanding ring behind the hero symbol and the halo on the
    /// current rail node. A pulse says "we are working on it", which is wrong once an order
    /// is cancelled, refunded or failed.
    ///
    /// It deliberately does not gate the Lottie animations: `Order_refunded` and
    /// `Order_failed` were authored for those very states, so they play. Only Reduce Motion
    /// stops them.
    private var animates: Bool {
        !presentation.isTerminal && !reduceMotion
    }

    private var placedAt: String? {
        timeline.first(where: { $0.status == "placed" })?.displayTime
    }

    var body: some View {
        VStack(spacing: 0) {
            hero
            separator
            rail
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .onAppear {
            // Reduce Motion still needs the end state, just without the journey.
            guard !reduceMotion else {
                railFilled = true
                heroAppeared = true
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                heroAppeared = true
            }
            withAnimation(.easeOut(duration: 0.45)) {
                railFilled = true
            }
            if animates { pulse = true }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            heroBadge

            Text(presentation.title)
                .font(.custom(Constants.AppFont.boldFont, size: 21))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .multilineTextAlignment(.center)

            Text(presentation.subtitle)
                .font(.custom(Constants.AppFont.regularFont, size: 13))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Order number and placement time used to live in their own card above this
            // one; the hero absorbs them so the screen opens on the status, not on admin.
            Text(metaLine)
                .font(.custom(Constants.AppFont.regularFont, size: 11))
                .foregroundColor(Color(hex: "98A2B3"))
        }
        .frame(maxWidth: .infinity)
    }

    private var metaLine: String {
        guard let placedAt else { return "Order #\(order.number)" }
        return "Order #\(order.number)  ·  Placed \(placedAt)"
    }

    @ViewBuilder
    private var heroBadge: some View {
        if let lottieName = presentation.lottieName {
            // Illustration-style animations carry their own composition, and some ship an
            // opaque background solid, so they get no tinted circle behind them — it would
            // be covered — and no pulse ring competing with their own motion.
            //
            // The box is wider than it is tall on purpose: Order_processing is 375×216, and
            // a square frame would letterbox that kitchen scene down to nothing.
            LottieView(filename: lottieName, isStop: reduceMotion)
                .frame(width: 168, height: 104)
        } else {
            symbolBadge
        }
    }

    /// The tinted-circle treatment, for the statuses with no animation of their own.
    private var symbolBadge: some View {
        ZStack {
            Circle()
                .fill(presentation.tint.opacity(0.10))
                .frame(width: 96, height: 96)

            // The expanding ring. Drawn only when it will animate, so a terminal status
            // does not show a stray static outline.
            if animates {
                Circle()
                    .stroke(presentation.tint.opacity(0.45), lineWidth: 2)
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulse ? 1.22 : 1.0)
                    .opacity(pulse ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                        value: pulse
                    )
            }

            Circle()
                .fill(presentation.tint.opacity(0.18))
                .frame(width: 74, height: 74)

            Image(systemName: presentation.icon)
                .font(.system(size: 31, weight: .semibold))
                .foregroundColor(presentation.tint)
                .scaleEffect(heroAppeared ? 1 : 0.6)
                .opacity(heroAppeared ? 1 : 0)
        }
        .frame(height: 104)
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(hex: "EDEFF2"))
            .frame(height: 1)
            .padding(.top, 20)
            .padding(.bottom, 18)
    }

    // MARK: - Rail

    private var rail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ORDER PROGRESS")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 11))
                .foregroundColor(Color(hex: "98A2B3"))
                .tracking(0.8)
                .padding(.bottom, 14)

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        node(step)
                        if index < steps.count - 1 {
                            connector(after: step, into: steps[index + 1], index: index)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(.custom(
                                step.state == .upcoming
                                    ? Constants.AppFont.regularFont
                                    : Constants.AppFont.semiBoldFont,
                                size: 14
                            ))
                            .foregroundColor(
                                step.state == .upcoming
                                    ? Color(hex: "98A2B3")
                                    : Constants.AppColor.primaryBlack
                            )

                        if let timestamp = step.timestamp {
                            Text(timestamp)
                                .font(.custom(Constants.AppFont.regularFont, size: 11))
                                .foregroundColor(Constants.AppColor.secondaryBlack)
                        }
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Node diameter is fixed at the halo's size so every row's rail column lines up
    /// whether or not that row is the current one.
    @ViewBuilder
    private func node(_ step: OrderStep) -> some View {
        let tint = step.tint

        ZStack {
            switch step.state {
            case .done:
                Circle()
                    .fill(tint)
                    .frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

            case .current:
                // Reduce Motion keeps the halo, just still — it is what marks "you are
                // here". The terminal node drops it: a ring around "Cancelled" reads as
                // work still in progress.
                if !step.isTerminal {
                    Circle()
                        .fill(tint.opacity(0.22))
                        .frame(width: 38, height: 38)
                        .scaleEffect(pulse && animates ? 1.12 : 0.86)
                        .opacity(pulse && animates ? 0.15 : 0.85)
                        .animation(
                            animates
                                ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
                                : .none,
                            value: pulse
                        )
                }
                Circle()
                    .fill(tint)
                    .frame(width: 26, height: 26)
                Image(systemName: step.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)

            case .upcoming:
                Circle()
                    .strokeBorder(Color(hex: "D8DCE2"), lineWidth: 2)
                    .frame(width: 26, height: 26)
            }
        }
        .frame(width: 38, height: 38)
    }

    /// Solid and tinted once the order is past this point, dashed grey while it is ahead.
    @ViewBuilder
    private func connector(after step: OrderStep, into next: OrderStep, index: Int) -> some View {
        let height: CGFloat = 26
        let reached = step.state == .done
        // Coloured by the node it flows into, so the rail warms as the order progresses and
        // only the final segment of a cancelled order turns red.
        let tint = next.tint

        ZStack(alignment: .top) {
            if reached {
                Capsule()
                    .fill(Color(hex: "EDEFF2"))
                    .frame(width: 3, height: height)
                Capsule()
                    .fill(tint)
                    .frame(width: 3, height: railFilled ? height : 0)
                    .animation(
                        reduceMotion
                            ? .none
                            : .easeOut(duration: 0.32).delay(Double(index) * 0.11),
                        value: railFilled
                    )
            } else {
                // A vertical dashed line — Capsule cannot be dashed, so stroke a path.
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                .stroke(
                    Color(hex: "D8DCE2"),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [3, 5])
                )
                .frame(width: 3, height: height)
            }
        }
    }
}

struct OrderProgressCard_Previews: PreviewProvider {
    private static func order(_ status: String) -> Order {
        var order = Order.default
        order.status = status
        return order
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(["pending", "on-hold", "processing", "completed", "cancelled"], id: \.self) { status in
                    OrderProgressCard(
                        order: order(status),
                        events: [
                            OrderTimelineEvent(status: "placed", displayTime: "28 Jul, 6:12 PM"),
                            OrderTimelineEvent(status: status, displayTime: "28 Jul, 6:35 PM")
                        ]
                    )
                }
            }
            .padding()
        }
        .background(Constants.AppColor.lightGrayColor)
    }
}
