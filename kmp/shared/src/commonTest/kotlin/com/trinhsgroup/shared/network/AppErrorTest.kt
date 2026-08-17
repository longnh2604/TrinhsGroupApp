package com.trinhsgroup.shared.network

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Tests for AppError and ErrorCode.
 */
class AppErrorTest {

    @Test
    fun testErrorCodeFromCode() {
        assertEquals(ErrorCode.BAD_REQUEST, ErrorCode.fromCode(400))
        assertEquals(ErrorCode.NOT_FOUND, ErrorCode.fromCode(404))
        assertEquals(ErrorCode.INTERNAL_SERVER_ERROR, ErrorCode.fromCode(500))
        assertEquals(ErrorCode.UNKNOWN, ErrorCode.fromCode(999)) // Unknown code
    }

    @Test
    fun testErrorCodeMessages() {
        assertEquals("Bad Request", ErrorCode.BAD_REQUEST.message)
        assertEquals("Not Found", ErrorCode.NOT_FOUND.message)
        assertEquals("Internal Server Error", ErrorCode.INTERNAL_SERVER_ERROR.message)
        assertEquals("No internet connection!", ErrorCode.CONNECTION.message)
        assertEquals("Error. Please try again!", ErrorCode.UNKNOWN.message)
    }

    @Test
    fun testAppErrorFromErrorCode() {
        val error = AppError(ErrorCode.NOT_FOUND)
        assertEquals(404, error.statusCode)
        assertEquals("Not Found", error.message)
    }

    @Test
    fun testAppErrorFromCode() {
        val error = AppError(code = 500)
        assertEquals(500, error.statusCode)
        assertEquals("Internal Server Error", error.message)
    }

    @Test
    fun testAppErrorFromUnknownCode() {
        val error = AppError(code = 418) // I'm a teapot - not defined
        assertEquals(418, error.statusCode)
        assertEquals("Error. Please try again!", error.message)
    }

    @Test
    fun testAppErrorUnknown() {
        val error = AppError.unknown
        assertEquals(ErrorCode.UNKNOWN.code, error.statusCode)
        assertEquals(ErrorCode.UNKNOWN.message, error.message)
    }

    @Test
    fun testAppErrorConnection() {
        val error = AppError.connection
        assertEquals(ErrorCode.CONNECTION.code, error.statusCode)
        assertEquals("No internet connection!", error.message)
    }
}
