//
//  OrderStatusPresentation.swift
//  TrinhsGroup
//
//  Single source of truth for how a WooCommerce order status is shown to the customer.
//  Copy, icon, colour and stage all live here so the hero, the stepper and anything added
//  later cannot drift into describing the same order differently.
//

import SwiftUI

// MARK: - Stage

/// The four steps of a normal order, in order.
///
/// A stage is *reached* by any status at or past it: an order being cooked was obviously
/// confirmed first, so `processing` reaches `.received` as well as `.cooking`.
enum OrderStage: Int, CaseIterable, Comparable {
    case placed = 0
    case received
    case cooking
    case ready

    static func < (lhs: OrderStage, rhs: OrderStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .placed:   return "Order Placed"
        case .received: return "Order Received"
        case .cooking:  return "In the Kitchen"
        case .ready:    return "Ready for Pickup"
        }
    }

    var icon: String {
        switch self {
        case .placed:   return "bag.fill"
        case .received: return "bell.badge.fill"
        case .cooking:  return "flame.fill"
        case .ready:    return "checkmark.seal.fill"
        }
    }

    /// Colour of this stage's node once it has been completed.
    ///
    /// Fixed per stage rather than inherited from the order's *current* status. Inheriting
    /// meant a cancelled order painted the stages it genuinely completed in failure red,
    /// as if they had failed too. As a bonus the rail now warms from coral through orange
    /// to green as the food progresses.
    var tint: Color {
        switch self {
        case .placed, .received: return StatusPalette.brand
        case .cooking:           return StatusPalette.cooking
        case .ready:             return StatusPalette.ready
        }
    }

    /// The stage a status implies, or `nil` for statuses that end the order early.
    ///
    /// `placed` is the synthetic status the server uses to timestamp order creation;
    /// `pending` sits at the same stage because an unpaid order has been placed but not
    /// yet confirmed by anyone.
    init?(status: String) {
        switch status {
        case "placed", "pending": self = .placed
        case "on-hold":           self = .received
        case "processing":        self = .cooking
        case "completed":         self = .ready
        default:                  return nil
        }
    }
}

// MARK: - Palette

/// Warm ramp that tracks the food: amber while waiting, orange in the kitchen, green when
/// ready. Explicit hex rather than the asset catalogue because this screen is drawn on a
/// hardcoded `f9f9f9` background and `ColorPrimary`'s dark variant is grey.
private enum StatusPalette {
    static let waiting  = Color(hex: "E9A23B")
    static let brand    = Color(hex: "FE7058")   // matches ColorPrimary's light value
    static let cooking  = Color(hex: "F2682A")
    static let ready    = Color(hex: "57A733")
    static let failure  = Color(hex: "E5484D")
}

// MARK: - Presentation

/// Everything the UI needs to render one order status.
struct OrderStatusPresentation {

    let title: String
    /// One line telling the customer what is happening, in their words not WooCommerce's.
    let subtitle: String
    let icon: String
    /// Name of a bundled Lottie animation to use instead of `icon`, when one fits.
    let lottieName: String?
    let tint: Color
    /// `true` for statuses that end the order. Suppresses the pulse, not the Lottie —
    /// `Order_refunded` and `Order_failed` were authored for these states.
    let isTerminal: Bool

    init(status: String) {
        switch status {
        case "pending":
            title      = "Awaiting Payment"
            subtitle   = "Finish paying to send your order to the kitchen."
            icon       = "creditcard.fill"
            lottieName = nil
            tint       = StatusPalette.waiting
            isTerminal = false

        case "on-hold":
            title      = "Order Received"
            subtitle   = "We're confirming your order with the kitchen."
            icon       = "bell.badge.fill"
            lottieName = "Order_onHold"
            tint       = StatusPalette.brand
            isTerminal = false

        case "processing":
            title      = "In the Kitchen"
            subtitle   = "Our chefs are cooking your food right now."
            icon       = "flame.fill"
            // Note: `cookLoading.json`, despite its name, is a *text* animation — five text
            // layers spelling "Cooking...." with bouncing dots, built for the 200pt loading
            // overlay. Order_processing is the purpose-made one.
            lottieName = "Order_processing"
            tint       = StatusPalette.cooking
            isTerminal = false

        case "completed":
            title      = "Ready for Pickup"
            subtitle   = "Your order is ready — enjoy your meal!"
            icon       = "checkmark.seal.fill"
            lottieName = "Order_ready"
            tint       = StatusPalette.ready
            isTerminal = false

        case "cancelled":
            title      = "Order Cancelled"
            subtitle   = "This order was cancelled."
            icon       = "xmark.circle.fill"
            // No Order_cancelled.json was supplied, and Order_failed is not a stand-in:
            // a customer cancelling their own order is not a payment failure.
            lottieName = nil
            tint       = StatusPalette.failure
            isTerminal = true

        case "refunded":
            title      = "Order Refunded"
            subtitle   = "Your payment has been returned."
            icon       = "arrow.uturn.backward.circle.fill"
            lottieName = "Order_refunded"
            tint       = StatusPalette.waiting
            isTerminal = true

        case "failed":
            title      = "Payment Failed"
            subtitle   = "The payment didn't go through."
            icon       = "exclamationmark.triangle.fill"
            lottieName = "Order_failed"
            tint       = StatusPalette.failure
            isTerminal = true

        default:
            // A status WooCommerce has but the app doesn't model — a custom one added in
            // wp-admin, say. Show the slug rather than pretending to know what it means.
            title      = status.replacingOccurrences(of: "-", with: " ").capitalized
            subtitle   = "We'll update you as your order progresses."
            icon       = "clock.fill"
            lottieName = nil
            tint       = StatusPalette.brand
            isTerminal = false
        }
    }
}

// MARK: - Stepper node

/// How one node of the four-step rail is drawn.
enum OrderStepState {
    case done
    case current
    case upcoming
}

/// One rendered row of the progress rail.
struct OrderStep: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let state: OrderStepState
    /// Pre-formatted for display, or `nil` when this step has no known timestamp.
    let timestamp: String?
    /// Colour for this node and for the rail leading into it. Resolved here so the view
    /// never has to reason about which of several tints applies.
    let tint: Color
    /// `true` for the appended cancelled / refunded / failed node.
    let isTerminal: Bool
}

/// Reduces an order plus its status history into the rail's rows.
///
/// Pure and free of SwiftUI state so it can be tested directly.
enum OrderProgressBuilder {

    /// - Parameters:
    ///   - status: the order's current WooCommerce status.
    ///   - events: status history, oldest first. May be empty — see `fallbackEvents`.
    static func steps(status: String, events: [OrderTimelineEvent]) -> [OrderStep] {
        let presentation = OrderStatusPresentation(status: status)

        // The furthest stage the order actually got to. For a terminal status this is the
        // last happy-path stage seen in the history, which is why the history matters:
        // "cancelled" alone cannot say whether the food had started cooking.
        let reached = events.compactMap { OrderStage(status: $0.status) }.max()

        // Earliest timestamp recorded for each stage.
        var stamps: [OrderStage: String] = [:]
        for event in events {
            guard let stage = OrderStage(status: event.status) else { continue }
            if stamps[stage] == nil { stamps[stage] = event.displayTime }
        }

        let current = presentation.isTerminal ? nil : OrderStage(status: status)

        var steps: [OrderStep] = OrderStage.allCases.compactMap { stage in
            // A terminal order's rail stops at the stage it reached; the nodes it never
            // got to are replaced by the terminal node rather than shown as pending.
            if presentation.isTerminal, let reached, stage > reached { return nil }

            let state: OrderStepState
            if let current {
                if stage < current      { state = .done }
                else if stage == current { state = .current }
                else                     { state = .upcoming }
            } else {
                state = .done   // terminal: everything it reached is behind it
            }

            return OrderStep(
                id: stage.rawValue,
                title: stage.title,
                icon: stage.icon,
                state: state,
                timestamp: stamps[stage],
                // The node the order is sitting on takes the hero's colour so the two
                // agree; completed nodes keep their own stage colour.
                tint: state == .current ? presentation.tint : stage.tint,
                isTerminal: false
            )
        }

        if presentation.isTerminal {
            steps.append(OrderStep(
                id: OrderStage.allCases.count,
                title: presentation.title,
                icon: presentation.icon,
                state: .current,
                timestamp: events.last(where: { $0.status == status })?.displayTime,
                tint: presentation.tint,
                isTerminal: true
            ))
        }

        return steps
    }

    /// Timeline to use when the history endpoint gave us nothing — it isn't deployed yet,
    /// the request failed, or the order predates it.
    ///
    /// Reproduces what the screen showed before this endpoint existed: creation time on
    /// the first step, last-modified on the current one.
    ///
    /// See `orderTimelineStamp` for the timezone caveat these two dates inherit.
    static func fallbackEvents(for order: Order) -> [OrderTimelineEvent] {
        var events: [OrderTimelineEvent] = []

        if !order.dateCreated.isEmpty {
            events.append(OrderTimelineEvent(
                status: "placed",
                displayTime: order.dateCreated.orderTimelineStamp
            ))
        }

        if order.status != "placed", !order.dateModified.isEmpty {
            events.append(OrderTimelineEvent(
                status: order.status,
                displayTime: order.dateModified.orderTimelineStamp
            ))
        }

        return events
    }
}
