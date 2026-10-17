package com.trinhsgroup.shared.viewmodel

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Tests for signup form validation matching iOS SignupView.isFormValid.
 */
class SignupValidationTest {

    @Test
    fun `password needs at least 8 characters`() {
        assertFalse(AuthViewModel.isPasswordValid(""))
        assertFalse(AuthViewModel.isPasswordValid("1234567"))
        assertTrue(AuthViewModel.isPasswordValid("12345678"))
    }

    @Test
    fun `email must match the iOS pattern`() {
        assertTrue(AuthViewModel.isEmailValid("test@example.com"))
        assertFalse(AuthViewModel.isEmailValid("test@example"))
        assertFalse(AuthViewModel.isEmailValid("not an email"))
    }

    @Test
    fun `login needs both email and password`() {
        assertTrue(AuthViewModel.isLoginFormValid("test@example.com", "x"))
        assertFalse(AuthViewModel.isLoginFormValid("", "x"))
        assertFalse(AuthViewModel.isLoginFormValid("test@example.com", ""))
    }

    @Test
    fun `form is valid only when every field is`() {
        assertTrue(AuthViewModel.isSignupFormValid("long", "test@example.com", "12345678"))
        assertFalse(AuthViewModel.isSignupFormValid("", "test@example.com", "12345678"))
        assertFalse(AuthViewModel.isSignupFormValid("long", "test@example", "12345678"))
        assertFalse(AuthViewModel.isSignupFormValid("long", "test@example.com", "1234567"))
    }
}
