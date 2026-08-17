package com.trinhsgroup.shared.auth

import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * The `exp` decode decides whether the app trusts a stored session, so it gets a direct test.
 * Reading the store itself needs a platform KeyValueStore, which is why only the parsing is
 * exercised here.
 */
@OptIn(ExperimentalEncodingApi::class)
class AuthTokenStoreTest {

    private fun jwt(payload: String): String {
        val encoded = Base64.UrlSafe.withPadding(Base64.PaddingOption.ABSENT)
            .encode(payload.encodeToByteArray())
        return "header.$encoded.signature"
    }

    @Test
    fun `reads the exp claim`() {
        assertEquals(1_800_000_000L, jwtExpirationEpochSeconds(jwt("""{"exp":1800000000}""")))
    }

    @Test
    fun `survives a payload without exp`() {
        assertNull(jwtExpirationEpochSeconds(jwt("""{"user_id":42}""")))
    }

    @Test
    fun `rejects anything that is not a three part token`() {
        assertNull(jwtExpirationEpochSeconds("not-a-jwt"))
        assertNull(jwtExpirationEpochSeconds(""))
        assertNull(jwtExpirationEpochSeconds("header.payload"))
    }

    @Test
    fun `survives a payload that is not JSON`() {
        assertNull(jwtExpirationEpochSeconds(jwt("plain text")))
        assertNull(jwtExpirationEpochSeconds("header.!!!not-base64!!!.signature"))
    }
}
