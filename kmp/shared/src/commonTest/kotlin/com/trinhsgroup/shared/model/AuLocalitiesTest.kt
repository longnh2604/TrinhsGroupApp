package com.trinhsgroup.shared.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AuLocalitiesTest {

    private val localities = AuLocalities.parse(
        """{"NSW":[["Bankstown","2200"],["Cabramatta","2166"],["Cabramatta West","2166"],["Canley Vale","2166"],["North Cabramatta","2166"]],"VIC":[["Melbourne","3000"]]}"""
    )

    @Test
    fun `empty query lists the whole state`() {
        assertEquals(5, localities.search("NSW", "").size)
        assertEquals(listOf(Locality("Melbourne", "3000")), localities.search("VIC", " "))
    }

    @Test
    fun `names starting with the query come before names containing it`() {
        assertEquals(
            listOf("Cabramatta", "Cabramatta West", "North Cabramatta"),
            localities.search("NSW", "cabra").map { it.name }
        )
    }

    @Test
    fun `postcode prefix matches`() {
        assertEquals(4, localities.search("NSW", "216").size)
    }

    @Test
    fun `other states and unknown states are not searched`() {
        assertTrue(localities.search("NSW", "Melbourne").isEmpty())
        assertTrue(localities.search("XX", "").isEmpty())
    }

    @Test
    fun `state names come from the code`() {
        assertEquals("New South Wales", AuAddress.stateName("NSW"))
        assertEquals("Somewhere", AuAddress.stateName("Somewhere"))
    }

    @Test
    fun `states typed by hand map to their code`() {
        assertEquals("NSW", AuAddress.stateCode("New South Wales"))
        assertEquals("NSW", AuAddress.stateCode(" nsw "))
        assertEquals("", AuAddress.stateCode(""))
    }
}
