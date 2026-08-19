package com.trinhsgroup.shared.network

import io.ktor.http.ContentType
import io.ktor.http.content.TextContent
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class JsonRequestBodyTest {

    /**
     * A payload built with buildJsonObject used to reach Ktor typed as `Any`, and content
     * negotiation then failed with "Serializer for class 'JsonLiteral' is not found" —
     * every POST and PUT in the app, profile updates and order creation included.
     */
    @Test
    fun jsonObjectGoesOutAsJsonText() {
        val body = buildJsonObject {
            put("first_name", "long")
            put("id", 42)
            put("billing", buildJsonObject { put("phone", "0935808888") })
        }

        val content = jsonRequestBody(body)

        assertIs<TextContent>(content)
        assertEquals(ContentType.Application.Json, content.contentType)
        assertEquals(
            """{"first_name":"long","id":42,"billing":{"phone":"0935808888"}}""",
            content.text
        )
    }

    @Test
    fun anythingElseIsLeftAlone() {
        val body = "already encoded"
        assertEquals(body, jsonRequestBody(body))
    }
}
