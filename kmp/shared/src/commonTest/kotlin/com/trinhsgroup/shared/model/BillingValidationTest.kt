package com.trinhsgroup.shared.model

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Tests for Billing validation matching iOS Billing.checkFilledData().
 */
class BillingValidationTest {
    
    @Test
    fun `valid billing passes validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            company = "",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertTrue(billing.checkFilledData())
    }
    
    @Test
    fun `empty first name fails validation`() {
        val billing = Billing(
            firstName = "",
            lastName = "User",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty last name fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty address fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            address1 = "",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty city fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            address1 = "123 Test Street",
            city = "",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty state fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty postcode fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty country fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty email fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "",
            phone = "0412345678"
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `empty phone fails validation`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = ""
        )
        
        assertFalse(billing.checkFilledData())
    }
    
    @Test
    fun `company can be empty and still pass`() {
        val billing = Billing(
            firstName = "Test",
            lastName = "User",
            company = "", // Company is optional
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            country = "AU",
            email = "test@example.com",
            phone = "0412345678"
        )
        
        assertTrue(billing.checkFilledData())
    }
    
    @Test
    fun `all empty fails validation`() {
        val billing = Billing()
        
        assertFalse(billing.checkFilledData())
    }

    @Test
    fun `phone and address are enough to order`() {
        val billing = Billing(
            address1 = "1 John St", city = "Cabramatta", postcode = "2166", state = "NSW",
            phone = "0412345678"
        )
        assertTrue(billing.isReadyToOrder())
    }

    @Test
    fun `missing phone or any address field cannot order`() {
        val ready = Billing(
            address1 = "1 John St", city = "Cabramatta", postcode = "2166", state = "NSW",
            phone = "0412345678"
        )
        assertFalse(ready.copy(phone = "   ").isReadyToOrder())
        assertFalse(ready.copy(address1 = "").isReadyToOrder())
        assertFalse(ready.copy(city = "").isReadyToOrder())
        assertFalse(ready.copy(postcode = "").isReadyToOrder())
        assertFalse(ready.copy(state = "").isReadyToOrder())
        assertFalse(Billing().isReadyToOrder())
    }
}
