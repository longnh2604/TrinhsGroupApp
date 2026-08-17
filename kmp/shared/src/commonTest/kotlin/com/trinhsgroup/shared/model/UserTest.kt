package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

/**
 * Tests for User and UserAuth models.
 */
class UserTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    @Test
    fun testUserAuthDecoding() {
        val jsonString = """
            {
                "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
                "user_email": "test@example.com",
                "user_nicename": "testuser",
                "user_display_name": "Test User"
            }
        """.trimIndent()

        val userAuth = json.decodeFromString<UserAuth>(jsonString)

        assertEquals("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9", userAuth.token)
        assertEquals("test@example.com", userAuth.email)
        assertEquals("testuser", userAuth.username)
        assertEquals("Test User", userAuth.displayName)
    }

    @Test
    fun testUserDecoding() {
        val jsonString = """
            {
                "id": 123,
                "email": "customer@example.com",
                "username": "customer1",
                "first_name": "John",
                "last_name": "Doe",
                "billing": {
                    "first_name": "John",
                    "last_name": "Doe",
                    "country": "AU",
                    "address_1": "123 Test St",
                    "city": "Sydney",
                    "postcode": "2000",
                    "state": "NSW",
                    "email": "customer@example.com",
                    "phone": "+61400000000"
                },
                "shipping": {
                    "first_name": "John",
                    "last_name": "Doe",
                    "country": "AU",
                    "address_1": "123 Test St",
                    "city": "Sydney",
                    "postcode": "2000",
                    "state": "NSW"
                },
                "avatar_url": "https://example.com/avatar.jpg",
                "is_paying_customer": true
            }
        """.trimIndent()

        val user = json.decodeFromString<User>(jsonString)

        assertEquals(123, user.id)
        assertEquals("customer@example.com", user.email)
        assertEquals("customer1", user.username)
        assertEquals("John", user.firstName)
        assertEquals("Doe", user.lastName)
        assertEquals("AU", user.billing.country)
        assertEquals("Sydney", user.billing.city)
        assertEquals("https://example.com/avatar.jpg", user.avatarUrl)
        assertEquals(true, user.isPayingCustomer)
    }

    @Test
    fun testUserEmptyDefaults() {
        val user = User.Empty

        assertEquals(0, user.id)
        assertEquals("", user.email)
        assertEquals("", user.username)
        assertEquals("", user.firstName)
        assertEquals("", user.lastName)
        assertNotNull(user.billing)
        assertNotNull(user.shipping)
        assertEquals(null, user.avatarUrl)
        assertEquals(false, user.isPayingCustomer)
    }

    @Test
    fun testUserDecodingWithMissingOptionalFields() {
        val jsonString = """
            {
                "id": 456,
                "email": "minimal@example.com",
                "username": "minimaluser",
                "first_name": "",
                "last_name": "",
                "billing": {},
                "shipping": {},
                "is_paying_customer": false
            }
        """.trimIndent()

        val user = json.decodeFromString<User>(jsonString)

        assertEquals(456, user.id)
        assertEquals("minimal@example.com", user.email)
        assertEquals("minimaluser", user.username)
        assertEquals(null, user.avatarUrl) // Not provided
    }
}
