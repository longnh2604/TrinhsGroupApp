//
//  AddOnModel.swift
//  TrinhsGroup
//
//  Wire types for GET /wp-json/trinh-app/v1/products/{id}/addons, and the rules for what the
//  customer has chosen from them.
//
//  YITH Product Add-ons is the single source of truth for what is on offer, what it costs and
//  how a choice is submitted. Nothing here totals an order: `price` is shown so the customer
//  can see what an option adds, and every figure that is charged comes back from the server.
//

import Foundation

struct AddOnGroupsResponse: Codable {
    var productId: Int
    var addons: [AddOnGroup]

    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case addons
    }

    static var `default`: AddOnGroupsResponse {
        AddOnGroupsResponse(productId: 0, addons: [])
    }
}

/// One group of options — "1st Pho", "Addition".
///
/// Decoding is deliberately forgiving. This endpoint is deployed by hand, so the first real
/// payload reaches customers' devices with nothing between it and the screen; losing every
/// group because one field is missing would leave a Family Trio impossible to order at all.
struct AddOnGroup: Codable, Identifiable, Equatable {
    var addonId: Int
    var type: String
    var title: String
    var description: String
    var required: Bool
    var selectionType: String
    /// The website decides in the browser whether this group is shown. The server never
    /// demands an answer for one, and neither does `missingRequired(in:)`.
    var conditional: Bool
    var min: Int?
    var max: Int?
    var options: [AddOnOption]

    var id: Int { addonId }

    /// `select` and `radio` take one answer; `checkbox` takes several unless YITH's own
    /// `selection_type` setting says otherwise.
    var allowsMultiple: Bool {
        type == "checkbox" && selectionType != "single"
    }

    private enum CodingKeys: String, CodingKey {
        case addonId = "addon_id"
        case type, title, description, required, conditional, min, max, options
        case selectionType = "selection_type"
    }

    init(
        addonId: Int,
        type: String,
        title: String,
        description: String = "",
        required: Bool = false,
        selectionType: String = "single",
        conditional: Bool = false,
        min: Int? = nil,
        max: Int? = nil,
        options: [AddOnOption]
    ) {
        self.addonId = addonId
        self.type = type
        self.title = title
        self.description = description
        self.required = required
        self.selectionType = selectionType
        self.conditional = conditional
        self.min = min
        self.max = max
        self.options = options
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        addonId = try container.decode(Int.self, forKey: .addonId)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
        selectionType = try container.decodeIfPresent(String.self, forKey: .selectionType) ?? "single"
        conditional = try container.decodeIfPresent(Bool.self, forKey: .conditional) ?? false
        min = try container.decodeIfPresent(Int.self, forKey: .min)
        max = try container.decodeIfPresent(Int.self, forKey: .max)
        options = try container.decodeIfPresent([AddOnOption].self, forKey: .options) ?? []
    }
}

struct AddOnOption: Codable, Identifiable, Equatable {
    var optionId: String
    var label: String
    var price: Double
    /// `fixed` means `price` is money, `percent` means it is a share of the product price.
    /// Only `fixed` is in use at Trinh's; a percent option is shown without a price rather
    /// than as a wrong dollar amount.
    var priceType: String
    /// `free`, `increase` or `decrease`.
    var priceMethod: String
    /// The pair to post back. Its shape depends on the group's type, so the server hands it
    /// over ready-made rather than leaving the app to rebuild the rule.
    var submitKey: String
    var submitValue: String

    var id: String { submitKey + "=" + submitValue }

    /// What this option adds to the line, or nil when there is nothing honest to show.
    var displayPrice: Double? {
        guard priceMethod != "free", priceType == "fixed", price != 0 else { return nil }
        return priceMethod == "decrease" ? -price : price
    }

    private enum CodingKeys: String, CodingKey {
        case optionId = "option_id"
        case label, price
        case priceType = "price_type"
        case priceMethod = "price_method"
        case submitKey = "submit_key"
        case submitValue = "submit_value"
    }

    init(
        optionId: String,
        label: String,
        price: Double = 0,
        priceType: String = "fixed",
        priceMethod: String = "free",
        submitKey: String,
        submitValue: String
    ) {
        self.optionId = optionId
        self.label = label
        self.price = price
        self.priceType = priceType
        self.priceMethod = priceMethod
        self.submitKey = submitKey
        self.submitValue = submitValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        optionId = try container.decodeIfPresent(String.self, forKey: .optionId) ?? ""
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        priceType = try container.decodeIfPresent(String.self, forKey: .priceType) ?? "fixed"
        priceMethod = try container.decodeIfPresent(String.self, forKey: .priceMethod) ?? "free"
        submitKey = try container.decode(String.self, forKey: .submitKey)
        submitValue = try container.decode(String.self, forKey: .submitValue)

        // Money arrives as a formatted string ("3.00"), the same way it does everywhere else
        // in the WooCommerce REST surface.
        if let numeric = try? container.decode(Double.self, forKey: .price) {
            price = numeric
        } else {
            price = Double(try container.decodeIfPresent(String.self, forKey: .price) ?? "") ?? 0
        }
    }
}

/// One option the customer actually picked, carried on the cart line.
///
/// `submitKey`/`submitValue` are what the order goes out with; the rest is so the cart can
/// name the choice without asking the server again.
struct AddOnChoice: Codable, Equatable {
    var submitKey: String
    var submitValue: String
    var groupTitle: String
    var label: String
    var price: Double
}

/// Which options are ticked while the customer is configuring one product.
///
/// Lives with the screen, not in a shared store: the old Firestore add-ons kept `checked` on
/// a singleton keyed by category, so two products in the same category shared one set of
/// ticks. The rules for what a valid selection looks like live here rather than in the view
/// so they can be asserted on.
struct AddOnSelection: Equatable {
    /// addon_id → chosen option_ids, in the order they were picked.
    private var chosen: [Int: [String]] = [:]

    init() {}

    func isChosen(group: AddOnGroup, option: AddOnOption) -> Bool {
        chosen[group.addonId]?.contains(option.optionId) ?? false
    }

    func chosenCount(group: AddOnGroup) -> Int {
        chosen[group.addonId]?.count ?? 0
    }

    func chosenLabel(group: AddOnGroup) -> String? {
        guard let first = chosen[group.addonId]?.first else { return nil }
        return group.options.first { $0.optionId == first }?.label
    }

    /// Tapping a chosen option clears it, including in a single-answer group — a customer who
    /// changes their mind about an optional choice needs a way back out, and a required group
    /// is caught by `missingRequired(in:)` rather than by making the control sticky.
    mutating func toggle(group: AddOnGroup, option: AddOnOption) {
        var current = chosen[group.addonId] ?? []

        if let existing = current.firstIndex(of: option.optionId) {
            current.remove(at: existing)
        } else if group.allowsMultiple {
            current.append(option.optionId)
        } else {
            current = [option.optionId]
        }

        if current.isEmpty {
            chosen.removeValue(forKey: group.addonId)
        } else {
            chosen[group.addonId] = current
        }
    }

    /// The first group that has to be answered and is not, or nil.
    ///
    /// Conditional groups are skipped: their visibility is decided by browser-side rules the
    /// app does not evaluate, and the server skips them for the same reason.
    func missingRequired(in groups: [AddOnGroup]) -> AddOnGroup? {
        groups.first { group in
            group.required && !group.conditional && chosenCount(group: group) == 0
        }
    }

    /// The first group whose min/max is not met, or nil. Only groups with something chosen are
    /// checked against `min`: an untouched optional group is not "too few", it is simply not
    /// wanted, and an untouched required one is `missingRequired`'s business.
    func outOfRange(in groups: [AddOnGroup]) -> AddOnGroup? {
        groups.first { group in
            let count = chosenCount(group: group)
            if let max = group.max, count > max { return true }
            if let min = group.min, count > 0, count < min { return true }
            return false
        }
    }

    /// What the customer picked, flattened in the order the groups are shown.
    func choices(in groups: [AddOnGroup]) -> [AddOnChoice] {
        groups.flatMap { group in
            group.options
                .filter { isChosen(group: group, option: $0) }
                .map { option in
                    AddOnChoice(
                        submitKey: option.submitKey,
                        submitValue: option.submitValue,
                        groupTitle: group.title,
                        label: option.label,
                        price: option.displayPrice ?? 0
                    )
                }
        }
    }
}

extension Array where Element == AddOnChoice {
    /// The `yith_wapo` map the order endpoint expects: one entry per chosen option, keyed the
    /// way YITH keys its own form fields.
    var submitPairs: [String: String] {
        reduce(into: [:]) { pairs, choice in
            pairs[choice.submitKey] = choice.submitValue
        }
    }

    /// What the choices add to one unit of the line. Display only — the server prices the
    /// order, and `POST /me/orders/preview` is what the checkout total comes from.
    var displayTotal: Double {
        reduce(0) { $0 + $1.price }
    }
}
