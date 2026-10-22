package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json

/**
 * The address form's State and City pickers. The store only serves Australia, so the country
 * isn't asked: it is always [COUNTRY].
 */
object AuAddress {
    const val COUNTRY = "AU"

    /** WooCommerce's AU state codes, which is what billing.state holds, with the names shown. */
    val states = listOf(
        "ACT" to "Australian Capital Territory",
        "NSW" to "New South Wales",
        "NT" to "Northern Territory",
        "QLD" to "Queensland",
        "SA" to "South Australia",
        "TAS" to "Tasmania",
        "VIC" to "Victoria",
        "WA" to "Western Australia"
    )

    fun stateName(code: String): String = states.firstOrNull { it.first == code }?.second ?: code

    /** The code for a state typed before the picker existed, e.g. "New South Wales" or "nsw". */
    fun stateCode(input: String): String = states.firstOrNull {
        it.first.equals(input.trim(), ignoreCase = true) || it.second.equals(input.trim(), ignoreCase = true)
    }?.first ?: input
}

data class Locality(val name: String, val postcode: String)

/**
 * Every suburb by state, from the bundled au_localities.json that
 * scripts/build-au-localities.py writes. A suburb with two postcodes is listed once per postcode.
 */
class AuLocalities(private val byState: Map<String, List<Locality>>) {

    /** Suburbs of [state] whose name contains [query], or whose postcode starts with it. Names that start with it come first. */
    fun search(state: String, query: String): List<Locality> {
        val all = byState[state].orEmpty()
        val q = query.trim()
        if (q.isEmpty()) return all
        val matches = all.filter { it.name.contains(q, ignoreCase = true) || it.postcode.startsWith(q) }
        return matches.sortedBy { if (it.name.startsWith(q, ignoreCase = true)) 0 else 1 }
    }

    companion object {
        fun parse(json: String): AuLocalities {
            val raw = Json.decodeFromString<Map<String, List<List<String>>>>(json)
            return AuLocalities(raw.mapValues { (_, rows) -> rows.map { Locality(it[0], it[1]) } })
        }
    }
}
