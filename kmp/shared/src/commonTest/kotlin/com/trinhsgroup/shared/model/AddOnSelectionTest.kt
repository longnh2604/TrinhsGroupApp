package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The rules for a valid add-on selection, and the map that actually buys the add-ons.
 *
 * Worth pinning directly: a selection that submits nothing looks perfectly fine on screen —
 * the customer ticks "Add Meat", and only the receipt disagrees.
 */
class AddOnSelectionTest {

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    private fun option(id: String, label: String, price: Double = 0.0, method: String = "increase") =
        AddOnOption(
            optionId = id,
            label = label,
            price = price,
            priceMethod = method,
            submitKey = "2-$id",
            submitValue = "1"
        )

    private val addition = AddOnGroup(
        addonId = 2,
        type = "checkbox",
        title = "Addition",
        selectionType = "multiple",
        options = listOf(
            option("0", "Add Meat", 3.0),
            option("1", "Add Tofu", 2.0),
            option("2", "No Chili")
        )
    )

    private val firstPho = AddOnGroup(
        addonId = 5,
        type = "radio",
        title = "1st Pho",
        required = true,
        selectionType = "single",
        options = listOf(option("0", "Beef"), option("1", "Chicken"))
    )

    @Test
    fun `decodes the live payload shape`() {
        // Trimmed from the real GET /trinh-app/v1/products/4486/addons response.
        val body = """
        {"product_id":4486,"addons":[{"addon_id":2,"type":"checkbox","title":"Addition",
        "description":"","required":false,"selection_type":"multiple","conditional":false,
        "min":null,"max":null,"options":[
          {"option_id":"0","label":"Add Meat","price":"3.00","price_type":"fixed",
           "price_method":"increase","submit_key":"2-0","submit_value":"1"}]}]}
        """.trimIndent()

        val response = json.decodeFromString<AddOnGroupsResponse>(body)
        val group = response.addons.single()
        val option = group.options.single()

        assertEquals(4486, response.productId)
        assertEquals("Addition", group.title)
        assertTrue(group.allowsMultiple)
        assertEquals("Add Meat", option.label)
        assertEquals(3.0, option.price)          // arrives as the string "3.00"
        assertEquals(3.0, option.displayPrice)
        assertEquals("2-0" to "1", option.submitKey to option.submitValue)
    }

    /** The map is what the server hands YITH; without it the line is priced bare. */
    @Test
    fun `submit pairs carry every chosen option`() {
        val selection = AddOnSelection()
            .toggle(addition, addition.options[0])
            .toggle(addition, addition.options[1])

        val pairs = selection.choices(listOf(addition)).submitPairs
        assertEquals(mapOf("2-0" to "1", "2-1" to "1"), pairs)
    }

    @Test
    fun `a multi-select group keeps every tick`() {
        val selection = AddOnSelection()
            .toggle(addition, addition.options[0])
            .toggle(addition, addition.options[2])

        assertEquals(2, selection.chosenCount(addition))
        assertTrue(selection.isChosen(addition, addition.options[0]))
        assertTrue(selection.isChosen(addition, addition.options[2]))
    }

    @Test
    fun `a single-answer group replaces rather than accumulates`() {
        val selection = AddOnSelection()
            .toggle(firstPho, firstPho.options[0])
            .toggle(firstPho, firstPho.options[1])

        assertEquals(1, selection.chosenCount(firstPho))
        assertFalse(selection.isChosen(firstPho, firstPho.options[0]))
        assertEquals("Chicken", selection.chosenLabel(firstPho))
    }

    /** A customer who changes their mind about an optional choice needs a way back out. */
    @Test
    fun `tapping a chosen option clears it`() {
        val selection = AddOnSelection()
            .toggle(firstPho, firstPho.options[0])
            .toggle(firstPho, firstPho.options[0])

        assertEquals(0, selection.chosenCount(firstPho))
        assertNull(selection.chosenLabel(firstPho))
    }

    @Test
    fun `a required group must be answered`() {
        val groups = listOf(addition, firstPho)
        assertEquals(firstPho, AddOnSelection().missingRequired(groups))

        val answered = AddOnSelection().toggle(firstPho, firstPho.options[0])
        assertNull(answered.missingRequired(groups))
    }

    /** Visibility is decided by browser rules the app doesn't evaluate, so the server skips these. */
    @Test
    fun `a conditional group is never demanded`() {
        val conditional = firstPho.copy(conditional = true)
        assertNull(AddOnSelection().missingRequired(listOf(conditional)))
    }

    @Test
    fun `max is enforced and min only once the group is touched`() {
        val pickTwo = addition.copy(min = 2, max = 2)

        // Untouched is "not wanted", not "too few".
        assertNull(AddOnSelection().outOfRange(listOf(pickTwo)))

        val one = AddOnSelection().toggle(pickTwo, pickTwo.options[0])
        assertEquals(pickTwo, one.outOfRange(listOf(pickTwo)))

        val two = one.toggle(pickTwo, pickTwo.options[1])
        assertNull(two.outOfRange(listOf(pickTwo)))

        val three = two.toggle(pickTwo, pickTwo.options[2])
        assertEquals(pickTwo, three.outOfRange(listOf(pickTwo)))
    }

    @Test
    fun `limit hint reads the same as the rule it describes`() {
        assertEquals("Choose 2", addition.copy(min = 2, max = 2).limitHint())
        assertEquals("Choose between 1 and 3", addition.copy(min = 1, max = 3).limitHint())
        assertEquals("Choose up to 2", addition.copy(max = 2).limitHint())
        assertEquals("Choose at least 1", addition.copy(min = 1).limitHint())
        assertNull(addition.limitHint())
    }

    /** Display only — a free option and a percent option have no honest dollar figure. */
    @Test
    fun `display price withholds what it cannot state in dollars`() {
        assertNull(option("0", "No Chili", 0.0, method = "free").displayPrice)
        assertNull(option("0", "Half price", 50.0, method = "increase").copy(priceType = "percent").displayPrice)
        assertEquals(-1.5, option("0", "No egg", 1.5, method = "decrease").displayPrice)
    }

    @Test
    fun `choices total what they add to one unit`() {
        val selection = AddOnSelection()
            .toggle(addition, addition.options[0])
            .toggle(addition, addition.options[1])

        assertEquals(5.0, selection.choices(listOf(addition)).displayTotal)
    }
}
