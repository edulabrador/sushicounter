package dev.edulabrador.sushiscore

import org.junit.Assert.assertEquals
import org.junit.Test

class SushiWidgetStateTest {
    @Test
    fun showsTheCount() {
        assertEquals("0", SushiWidgetState.countText(0))
        assertEquals("42", SushiWidgetState.countText(42))
        assertEquals("9999", SushiWidgetState.countText(9999))
    }

    @Test
    fun neverShowsNegativeOrOverlongCounts() {
        assertEquals("0", SushiWidgetState.countText(-3))
        assertEquals("9999+", SushiWidgetState.countText(12000))
    }
}
