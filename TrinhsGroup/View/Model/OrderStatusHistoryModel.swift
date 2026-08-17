//
//  OrderStatusHistoryModel.swift
//  TrinhsGroup
//
//  Wire type for GET /wp-json/trinh-app/v1/me/orders/{id}/history.
//

import Foundation

/// Status timeline for one order, oldest entry first.
struct OrderStatusHistory: Decodable {

    let orderID: Int
    /// The order's current status, as the server sees it.
    let status: String
    let history: [Entry]

    struct Entry: Decodable {
        let status: String
        /// Site-local time, matching the WooCommerce REST order payload's `date_created`.
        let at: String
        /// The same moment in UTC. Optional so an older server that only sends `at` still
        /// decodes rather than failing the whole response.
        let atGMT: String?

        enum CodingKeys: String, CodingKey {
            case status
            case at
            case atGMT = "at_gmt"
        }
    }

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case status
        case history
    }

    /// Formatted for the progress rail.
    ///
    /// Prefers `at_gmt` because `orderTimelineStamp` parses its input as UTC. Falling back
    /// to `at` keeps a short-of-date server rendering *something*, at the cost of the
    /// timezone offset.
    var timelineEvents: [OrderTimelineEvent] {
        history.map { entry in
            OrderTimelineEvent(
                status: entry.status,
                displayTime: (entry.atGMT ?? entry.at).orderTimelineStamp
            )
        }
    }
}

/// A status change with its time already formatted for display.
///
/// Deliberately not the wire type: the fallback path has no `at_gmt` to offer, so the view
/// layer works in terms of "status plus a string to print".
struct OrderTimelineEvent {
    let status: String
    let displayTime: String?
}

extension String {

    /// A WordPress `Y-m-d\TH:i:s` timestamp rendered for the progress rail —
    /// `"2026-07-28T08:35:10"` becomes `"28 Jul, 6:35 PM"`.
    ///
    /// Not `toAustraliaDateTime()`: that one's output locale is `en_AU_POSIX`, which is not
    /// a valid identifier, and it resolves to a locale that renders the am/pm marker
    /// lowercase (`6:35 pm`). `en_US_POSIX` is the locale to use with a fixed format
    /// string — it is guaranteed stable across OS versions and gives `PM`.
    ///
    /// The input is parsed as UTC. That is correct for the endpoint's `at_gmt`; for the
    /// fallback's `date_created` it reproduces the app's existing (and questionable)
    /// assumption rather than making this one screen disagree with every other.
    var orderTimelineStamp: String? {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        input.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = input.date(from: self) else { return nil }

        let output = DateFormatter()
        output.locale = Locale(identifier: "en_US_POSIX")
        output.dateFormat = "d MMM, h:mm a"
        output.timeZone = TimeZone(identifier: "Australia/Sydney")
        return output.string(from: date)
    }
}
