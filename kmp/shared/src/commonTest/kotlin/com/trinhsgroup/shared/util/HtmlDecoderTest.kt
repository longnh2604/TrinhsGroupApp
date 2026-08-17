package com.trinhsgroup.shared.util

import kotlin.test.Test
import kotlin.test.assertEquals

class HtmlDecoderTest {

    @Test
    fun testDecodeBasicEntities() {
        assertEquals("&", HtmlDecoder.decode("&amp;"))
        assertEquals("<", HtmlDecoder.decode("&lt;"))
        assertEquals(">", HtmlDecoder.decode("&gt;"))
        assertEquals("\"", HtmlDecoder.decode("&quot;"))
        assertEquals("'", HtmlDecoder.decode("&apos;"))
    }

    @Test
    fun testDecodeNumericEntities() {
        // &#60; = '<'
        assertEquals("<", HtmlDecoder.decode("&#60;"))
        // &#62; = '>'
        assertEquals(">", HtmlDecoder.decode("&#62;"))
    }

    @Test
    fun testDecodeHexEntities() {
        // &#x3C; = '<' (hex 3C = 60 decimal)
        assertEquals("<", HtmlDecoder.decode("&#x3C;"))
        // &#x3e; = '>' (hex 3E = 62 decimal)
        assertEquals(">", HtmlDecoder.decode("&#x3e;"))
    }

    @Test
    fun testDecodeNbsp() {
        // Non-breaking space
        assertEquals("\u00A0", HtmlDecoder.decode("&nbsp;"))
    }

    @Test
    fun testDecodeSpecialCharacters() {
        assertEquals("©", HtmlDecoder.decode("&copy;"))
        assertEquals("®", HtmlDecoder.decode("&reg;"))
        assertEquals("™", HtmlDecoder.decode("&trade;"))
        assertEquals("€", HtmlDecoder.decode("&euro;"))
    }

    @Test
    fun testDecodeMixedContent() {
        assertEquals("Tom & Jerry", HtmlDecoder.decode("Tom &amp; Jerry"))
        assertEquals("<html>", HtmlDecoder.decode("&lt;html&gt;"))
        assertEquals("5 < 10 & 10 > 5", HtmlDecoder.decode("5 &lt; 10 &amp; 10 &gt; 5"))
    }

    @Test
    fun testDecodeNoEntities() {
        assertEquals("Hello World", HtmlDecoder.decode("Hello World"))
        assertEquals("", HtmlDecoder.decode(""))
    }

    @Test
    fun testDecodeMalformedEntities() {
        // Should leave malformed entities unchanged
        assertEquals("&invalid;", HtmlDecoder.decode("&invalid;"))
        assertEquals("&#xyz;", HtmlDecoder.decode("&#xyz;"))
    }

    @Test
    fun testStringExtension() {
        assertEquals("Tom & Jerry", "Tom &amp; Jerry".decodingHTMLEntities())
    }
}
