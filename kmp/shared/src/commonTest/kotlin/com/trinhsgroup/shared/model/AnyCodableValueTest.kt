package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Unit tests for AnyCodableValue.
 * Tests decoding from JSON and accessor methods.
 */
class AnyCodableValueTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    @Test
    fun testDecodeInteger() {
        val jsonStr = """42"""
        val value = json.decodeFromString<AnyCodableValue>(jsonStr)
        assertTrue(value is AnyCodableValue.IntegerValue)
        assertEquals(42, (value as AnyCodableValue.IntegerValue).value)
    }

    @Test
    fun testDecodeString() {
        val jsonStr = """"hello""""
        val value = json.decodeFromString<AnyCodableValue>(jsonStr)
        assertTrue(value is AnyCodableValue.StringValue)
        assertEquals("hello", (value as AnyCodableValue.StringValue).value)
    }

    @Test
    fun testDecodeBoolean() {
        val jsonStr = """true"""
        val value = json.decodeFromString<AnyCodableValue>(jsonStr)
        assertTrue(value is AnyCodableValue.BooleanValue)
        assertTrue((value as AnyCodableValue.BooleanValue).value)
    }

    @Test
    fun testDecodeDouble() {
        val jsonStr = """3.14159"""
        val value = json.decodeFromString<AnyCodableValue>(jsonStr)
        // Note: JSON doubles are parsed as Float or Double depending on precision
        assertTrue(value is AnyCodableValue.FloatValue || value is AnyCodableValue.DoubleValue)
    }

    @Test
    fun testDecodeNull() {
        val jsonStr = """null"""
        val value = json.decodeFromString<AnyCodableValue>(jsonStr)
        assertTrue(value is AnyCodableValue.NullValue)
    }

    @Test
    fun testStringValueAccessor() {
        assertEquals("hello", AnyCodableValue.StringValue("hello").stringValue)
        assertEquals("42", AnyCodableValue.IntegerValue(42).stringValue)
        assertEquals("3.14", AnyCodableValue.DoubleValue(3.14).stringValue)
        assertEquals("2.5", AnyCodableValue.FloatValue(2.5f).stringValue)
        assertEquals("", AnyCodableValue.BooleanValue(true).stringValue)
        assertEquals("", AnyCodableValue.NullValue.stringValue)
    }

    @Test
    fun testIntValueAccessor() {
        assertEquals(42, AnyCodableValue.IntegerValue(42).intValue)
        assertEquals(42, AnyCodableValue.StringValue("42").intValue)
        assertEquals(0, AnyCodableValue.StringValue("invalid").intValue)
        assertEquals(3, AnyCodableValue.FloatValue(3.7f).intValue)
        assertEquals(0, AnyCodableValue.NullValue.intValue)
    }

    @Test
    fun testFloatValueAccessor() {
        assertEquals(3.14f, AnyCodableValue.FloatValue(3.14f).floatValue)
        assertEquals(42f, AnyCodableValue.IntegerValue(42).floatValue)
        assertEquals(3.14f, AnyCodableValue.StringValue("3.14").floatValue)
        assertEquals(0f, AnyCodableValue.NullValue.floatValue)
    }

    @Test
    fun testDoubleValueAccessor() {
        assertEquals(3.14, AnyCodableValue.DoubleValue(3.14).doubleValue)
        assertEquals(42.0, AnyCodableValue.IntegerValue(42).doubleValue)
        assertEquals(3.14, AnyCodableValue.StringValue("3.14").doubleValue)
        assertEquals(0.0, AnyCodableValue.NullValue.doubleValue)
    }

    @Test
    fun testBooleanValueAccessor() {
        assertTrue(AnyCodableValue.BooleanValue(true).booleanValue)
        assertFalse(AnyCodableValue.BooleanValue(false).booleanValue)
        assertTrue(AnyCodableValue.IntegerValue(1).booleanValue)
        assertFalse(AnyCodableValue.IntegerValue(0).booleanValue)
        assertTrue(AnyCodableValue.StringValue("1").booleanValue)
        assertFalse(AnyCodableValue.StringValue("0").booleanValue)
        assertFalse(AnyCodableValue.NullValue.booleanValue)
    }

    @Test
    fun testEquality() {
        assertEquals(AnyCodableValue.IntegerValue(42), AnyCodableValue.IntegerValue(42))
        assertNotEquals(AnyCodableValue.IntegerValue(42), AnyCodableValue.IntegerValue(43))
        assertEquals(AnyCodableValue.StringValue("test"), AnyCodableValue.StringValue("test"))
        assertEquals(AnyCodableValue.NullValue, AnyCodableValue.NullValue)
    }
}
