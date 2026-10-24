package dev.edulabrador.sushiscore

import java.io.ByteArrayInputStream
import java.io.IOException
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Test

class TextFilesTest {
    @Test
    fun readsUtf8AcrossBufferBoundaries() {
        val text = "ñ🍣".repeat(5000) // multi-byte characters spanning 8 KB chunks
        assertEquals(text, TextFiles.readUtf8(ByteArrayInputStream(text.toByteArray())))
    }

    @Test
    fun readsEmptyFile() {
        assertEquals("", TextFiles.readUtf8(ByteArrayInputStream(ByteArray(0))))
    }

    @Test
    fun acceptsExactlyTheLimit() {
        assertEquals(10, TextFiles.readUtf8(ByteArrayInputStream(ByteArray(10) { 'a'.code.toByte() }), 10).length)
    }

    @Test
    fun rejectsFilesOverTheLimit() {
        try {
            TextFiles.readUtf8(ByteArrayInputStream(ByteArray(11)), maxBytes = 10)
            fail("Expected IOException")
        } catch (expected: IOException) {
        }
    }

    @Test
    fun exportNamesAreSafeJsonFiles() {
        assertEquals("sushi-tracker-2026-10-24.json", TextFiles.exportFileName("sushi-tracker-2026-10-24"))
        assertEquals("backup.json", TextFiles.exportFileName("backup.json"))
        assertEquals("a-b-c.json", TextFiles.exportFileName("a/b\\c"))
        assertEquals(TextFiles.DEFAULT_NAME, TextFiles.exportFileName(null))
        assertEquals(TextFiles.DEFAULT_NAME, TextFiles.exportFileName("../.."))
        assertEquals(85, TextFiles.exportFileName("x".repeat(200)).length)
    }
}
