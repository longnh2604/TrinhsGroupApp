package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Tests for the points and vouchers models.
 * Tests WCCouponResponse validity and VoucherResponse mapping.
 */
class PointsVouchersTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }

    @Test
    fun testWCCouponResponseIsValid() {
        // A valid coupon: not expired, not fully used
        val jsonStr = """
        {
            "id": 1,
            "code": "SAVE10",
            "amount": "10.00",
            "discount_type": "fixed_cart",
            "description": "Save $10",
            "date_expires": "2030-12-31T23:59:59",
            "date_expires_gmt": "2030-12-31T23:59:59",
            "usage_count": 0,
            "usage_limit": 100,
            "usage_limit_per_user": 1,
            "individual_use": false,
            "minimum_amount": "0",
            "maximum_amount": "0",
            "email_restrictions": [],
            "used_by": []
        }
        """
        
        val coupon = json.decodeFromString<WCCouponResponse>(jsonStr)
        
        assertTrue(coupon.isValid)
        assertFalse(coupon.isExpired)
        assertEquals(10.0, coupon.amountValue, 0.01)
    }

    @Test
    fun testWCCouponResponseIsExpired() {
        // An expired coupon
        val jsonStr = """
        {
            "id": 2,
            "code": "EXPIRED",
            "amount": "5.00",
            "discount_type": "percent",
            "description": "Expired coupon",
            "date_expires": "2020-01-01T00:00:00Z",
            "date_expires_gmt": "2020-01-01T00:00:00Z",
            "usage_count": 0,
            "usage_limit": null,
            "usage_limit_per_user": null,
            "individual_use": false,
            "minimum_amount": "0",
            "maximum_amount": "0",
            "email_restrictions": [],
            "used_by": []
        }
        """
        
        val coupon = json.decodeFromString<WCCouponResponse>(jsonStr)
        
        assertTrue(coupon.isExpired)
        assertFalse(coupon.isValid)
    }

    @Test
    fun testWCCouponResponseUsageLimitReached() {
        // Coupon with usage limit reached
        val jsonStr = """
        {
            "id": 3,
            "code": "LIMITED",
            "amount": "15.00",
            "discount_type": "fixed_cart",
            "description": "",
            "date_expires": "2030-12-31T23:59:59",
            "date_expires_gmt": null,
            "usage_count": 5,
            "usage_limit": 5,
            "usage_limit_per_user": null,
            "individual_use": false,
            "minimum_amount": "0",
            "maximum_amount": "0",
            "email_restrictions": [],
            "used_by": []
        }
        """
        
        val coupon = json.decodeFromString<WCCouponResponse>(jsonStr)
        
        assertFalse(coupon.isExpired)
        assertFalse(coupon.isValid, "Coupon should be invalid when usage limit is reached")
    }

    @Test
    fun testWCCouponResponseNoExpiry() {
        // Coupon with no expiration
        val jsonStr = """
        {
            "id": 4,
            "code": "FOREVER",
            "amount": "20.00",
            "discount_type": "percent",
            "description": "",
            "date_expires": null,
            "date_expires_gmt": null,
            "usage_count": 0,
            "usage_limit": null,
            "usage_limit_per_user": null,
            "individual_use": false,
            "minimum_amount": "0",
            "maximum_amount": "0",
            "email_restrictions": [],
            "used_by": []
        }
        """
        
        val coupon = json.decodeFromString<WCCouponResponse>(jsonStr)
        
        assertFalse(coupon.isExpired)
        assertTrue(coupon.isValid)
        assertNull(coupon.expirationDate)
        assertEquals("No expiry", coupon.formattedExpiryDate)
    }

    @Test
    fun testWCCouponResponseToVoucherResponse() {
        val jsonStr = """
        {
            "id": 5,
            "code": "rw123-VOUCHER",
            "amount": "25.00",
            "discount_type": "fixed_cart",
            "description": "Points voucher",
            "date_expires": "2030-06-15T12:00:00Z",
            "date_expires_gmt": "2030-06-15T12:00:00Z",
            "usage_count": 1,
            "usage_limit": 10,
            "usage_limit_per_user": 1,
            "individual_use": true,
            "minimum_amount": "0",
            "maximum_amount": "0",
            "email_restrictions": [],
            "used_by": [1, "user@example.com"]
        }
        """
        
        val coupon = json.decodeFromString<WCCouponResponse>(jsonStr)
        val voucher = coupon.toVoucherResponse()
        
        assertEquals(5, voucher.id)
        assertEquals("rw123-VOUCHER", voucher.code)
        assertEquals(25.0, voucher.amount, 0.01)
        assertEquals("AUD", voucher.currency)
        assertEquals(1, voucher.usageCount)
        assertEquals(10, voucher.usageLimit)
        assertEquals("active", voucher.status)
    }

    @Test
    fun testWCCouponResponseMixedUsedBy() {
        // Test that usedBy handles mixed Int/String values
        val jsonStr = """
        {
            "id": 6,
            "code": "MIXED",
            "amount": "5.00",
            "discount_type": "percent",
            "description": "",
            "date_expires": null,
            "date_expires_gmt": null,
            "usage_count": 3,
            "usage_limit": null,
            "usage_limit_per_user": null,
            "individual_use": false,
            "minimum_amount": "0",
            "maximum_amount": "0",
            "email_restrictions": [],
            "used_by": [123, "user@test.com", 456]
        }
        """
        
        val coupon = json.decodeFromString<WCCouponResponse>(jsonStr)
        
        assertEquals(3, coupon.usedBy.size)
        assertEquals("123", coupon.usedBy[0])
        assertEquals("user@test.com", coupon.usedBy[1])
        assertEquals("456", coupon.usedBy[2])
    }

    @Test
    fun testVoucherResponseIsExpired() {
        val voucher = VoucherResponse(
            id = 1,
            code = "TEST",
            amount = 10.0,
            currency = "AUD",
            expiresAt = "2020-01-01T00:00:00Z",
            usageCount = 0,
            usageLimit = 1,
            status = "active"
        )
        
        assertTrue(voucher.isExpired)
    }

    @Test
    fun testVoucherResponseNotExpired() {
        val voucher = VoucherResponse(
            id = 1,
            code = "TEST",
            amount = 10.0,
            currency = "AUD",
            expiresAt = "2030-12-31T23:59:59Z",
            usageCount = 0,
            usageLimit = 1,
            status = "active"
        )
        
        assertFalse(voucher.isExpired)
    }

    @Test
    fun testRedeemResponseDecoding() {
        val jsonStr = """
        {
            "coupon_code": "rw123-ABC",
            "amount": 50.0,
            "currency": "AUD",
            "expires_at": "2030-06-15T12:00:00Z",
            "points_used": 100,
            "balance": 400.0
        }
        """
        
        val response = json.decodeFromString<RedeemResponse>(jsonStr)
        
        assertEquals("rw123-ABC", response.couponCode)
        assertEquals(50.0, response.amount, 0.01)
        assertEquals("AUD", response.currency)
        assertEquals(100, response.pointsUsed)
        assertEquals(400.0, response.balance, 0.01)
        assertNotNull(response.expirationDate)
    }

    @Test
    fun testRedeemErrorResponseDecoding() {
        val jsonStr = """
        {
            "error": "Insufficient points",
            "balance": 50.0
        }
        """
        
        val response = json.decodeFromString<RedeemErrorResponse>(jsonStr)
        
        assertEquals("Insufficient points", response.error)
        assertEquals(50.0, response.balance)
    }

    @Test
    fun testRedeemErrorResponseWithoutBalance() {
        val jsonStr = """
        {
            "error": "Invalid request"
        }
        """
        
        val response = json.decodeFromString<RedeemErrorResponse>(jsonStr)
        
        assertEquals("Invalid request", response.error)
        assertNull(response.balance)
    }

    @Test
    fun testPointsResponseDecoding() {
        val jsonStr = """
        {
            "user_id": 123,
            "type": "mycred_default",
            "balance": 500.0
        }
        """
        
        val response = json.decodeFromString<PointsResponse>(jsonStr)
        
        assertEquals(123, response.userId)
        assertEquals("mycred_default", response.type)
        assertEquals(500.0, response.balance, 0.01)
    }
}
