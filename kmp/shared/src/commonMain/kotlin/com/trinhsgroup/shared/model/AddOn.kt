package com.trinhsgroup.shared.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Wire types for GET /wp-json/trinh-app/v1/products/{id}/addons, and the rules for what a
 * customer may choose from them.
 * Mirrors Swift's AddOnModel.swift.
 *
 * YITH Product Add-ons is the single source of truth for what is on offer, what it costs, and
 * how a choice is submitted. Nothing here totals an order: `price` is shown so the customer
 * sees what an option adds, but the figure charged comes back from the server.
 */
@Serializable
data class AddOnGroupsResponse(
    @SerialName("product_id") val productId: Int = 0,
    val addons: List<AddOnGroup> = emptyList()
) {
    companion object {
        val Empty = AddOnGroupsResponse()
    }
}

/**
 * One group of options — "1st Pho", "Addition".
 *
 * Decoding is deliberately forgiving: losing a whole group because one field is missing would
 * leave something like the Family Trio impossible to order at all.
 */
@Serializable
data class AddOnGroup(
    @SerialName("addon_id") val addonId: Int,
    val type: String = "",
    val title: String = "",
    val description: String = "",
    val required: Boolean = false,
    @SerialName("selection_type") val selectionType: String = "single",
    /**
     * The website decides in the browser whether a group is shown. The server never demands an
     * answer for one, and neither does [AddOnSelection.missingRequired].
     */
    val conditional: Boolean = false,
    val min: Int? = null,
    val max: Int? = null,
    val options: List<AddOnOption> = emptyList()
) {
    /**
     * `select` and `radio` take one answer; `checkbox` takes many unless YITH's own
     * `selection_type` setting says otherwise.
     */
    val allowsMultiple: Boolean
        get() = type == "checkbox" && selectionType != "single"

    /**
     * The group's own min/max in words, or null when it has none worth saying. Lives here so
     * the hint shown next to the group and the message shown when it is broken cannot drift.
     */
    fun limitHint(): String? {
        val min = min
        val max = max
        return when {
            min != null && max != null && min == max -> "Choose $min"
            min != null && max != null -> "Choose between $min and $max"
            max != null -> "Choose up to $max"
            min != null -> "Choose at least $min"
            else -> null
        }
    }
}

/** One selectable option within a group. */
@Serializable(with = AddOnOptionSerializer::class)
data class AddOnOption(
    val optionId: String = "",
    val label: String = "",
    val price: Double = 0.0,
    /**
     * `fixed` means [price] is money, `percent` means a share of the product price. Only
     * `fixed` is in use at Trinh's; showing a percent option's price would name the wrong
     * dollar amount, so [displayPrice] withholds it.
     */
    val priceType: String = "fixed",
    /** `free`, `increase` or `decrease`. */
    val priceMethod: String = "free",
    val submitKey: String,
    val submitValue: String
) {
    /** What to show next to the label, or null when there is no honest figure to show. */
    val displayPrice: Double?
        get() {
            if (priceMethod == "free" || priceType != "fixed" || price == 0.0) return null
            return if (priceMethod == "decrease") -price else price
        }
}

/**
 * Money arrives as a formatted string ("3.00") on some fields and a number on others, the same
 * way it does everywhere else on the WooCommerce REST surface.
 */
object AddOnOptionSerializer : KSerializer<AddOnOption> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("AddOnOption")

    override fun deserialize(decoder: Decoder): AddOnOption {
        val json = (decoder as JsonDecoder).decodeJsonElement().jsonObject
        fun str(key: String, default: String = "") =
            json[key]?.jsonPrimitive?.contentOrNull() ?: default

        val priceElement = json["price"]?.jsonPrimitive
        val price = priceElement?.doubleOrNull
            ?: priceElement?.contentOrNull()?.toDoubleOrNull()
            ?: 0.0

        return AddOnOption(
            optionId = str("option_id"),
            label = str("label"),
            price = price,
            priceType = str("price_type", "fixed"),
            priceMethod = str("price_method", "free"),
            submitKey = str("submit_key"),
            submitValue = str("submit_value")
        )
    }

    override fun serialize(encoder: Encoder, value: AddOnOption) {
        throw UnsupportedOperationException("AddOnOption is read-only")
    }

    private fun kotlinx.serialization.json.JsonPrimitive.contentOrNull(): String? =
        if (isString || content.isNotEmpty()) content else null
}

/**
 * One option the customer actually picked, carried on the cart line.
 *
 * [submitKey]/[submitValue] are what the order endpoint needs; the rest is for display.
 */
@Serializable
data class AddOnChoice(
    val submitKey: String,
    val submitValue: String,
    val groupTitle: String = "",
    val label: String = "",
    val price: Double = 0.0
)

/**
 * What the customer has picked, and the rules for whether that is a valid selection.
 *
 * Held per screen rather than on a shared client: the Firestore add-ons this replaces kept
 * `checked` on a singleton keyed by category, so two products in the same category shared one
 * set of ticks.
 */
data class AddOnSelection(
    /** addon_id → chosen option_ids, in the order picked. */
    private val chosen: Map<Int, List<String>> = emptyMap()
) {
    fun isChosen(group: AddOnGroup, option: AddOnOption): Boolean =
        chosen[group.addonId]?.contains(option.optionId) ?: false

    fun chosenCount(group: AddOnGroup): Int = chosen[group.addonId]?.size ?: 0

    fun chosenLabel(group: AddOnGroup): String? {
        val first = chosen[group.addonId]?.firstOrNull() ?: return null
        return group.options.firstOrNull { it.optionId == first }?.label
    }

    /**
     * Tapping a chosen option clears it, including in a single-answer group — a customer who
     * changes their mind about an optional choice needs a way back out. An untouched required
     * group is caught by [missingRequired] rather than by making the choice sticky.
     */
    fun toggle(group: AddOnGroup, option: AddOnOption): AddOnSelection {
        val current = chosen[group.addonId] ?: emptyList()
        val next = when {
            current.contains(option.optionId) -> current - option.optionId
            group.allowsMultiple -> current + option.optionId
            else -> listOf(option.optionId)
        }
        return AddOnSelection(
            if (next.isEmpty()) chosen - group.addonId else chosen + (group.addonId to next)
        )
    }

    /**
     * The first required group with no answer, or null.
     *
     * Conditional groups are skipped: their visibility is decided by browser-side rules the app
     * does not evaluate, and the server skips them for the same reason.
     */
    fun missingRequired(groups: List<AddOnGroup>): AddOnGroup? =
        groups.firstOrNull { it.required && !it.conditional && chosenCount(it) == 0 }

    /**
     * The first group whose count breaks its own min/max, or null.
     *
     * An untouched group is not "too few", it is simply not wanted — an untouched required one
     * is [missingRequired]'s business.
     */
    fun outOfRange(groups: List<AddOnGroup>): AddOnGroup? =
        groups.firstOrNull { group ->
            val count = chosenCount(group)
            val max = group.max
            val min = group.min
            when {
                max != null && count > max -> true
                min != null && count > 0 && count < min -> true
                else -> false
            }
        }

    /** What the customer picked, flattened in the order the groups are shown. */
    fun choices(groups: List<AddOnGroup>): List<AddOnChoice> =
        groups.flatMap { group ->
            group.options
                .filter { isChosen(group, it) }
                .map { option ->
                    AddOnChoice(
                        submitKey = option.submitKey,
                        submitValue = option.submitValue,
                        groupTitle = group.title,
                        label = option.label,
                        price = option.displayPrice ?: 0.0
                    )
                }
        }
}

/**
 * The `yith_wapo` map the order endpoint expects: one entry per chosen option, keyed the way
 * YITH keys its own form fields.
 */
val List<AddOnChoice>.submitPairs: Map<String, String>
    get() = associate { it.submitKey to it.submitValue }

/**
 * What the choices add to one unit. Display only — the server prices the order, and the
 * checkout total comes from POST /me/orders/preview.
 */
val List<AddOnChoice>.displayTotal: Double
    get() = sumOf { it.price }
