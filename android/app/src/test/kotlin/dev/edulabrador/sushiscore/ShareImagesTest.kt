package dev.edulabrador.sushiscore

import java.io.File
import java.nio.file.Files
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ShareImagesTest {
    private fun tempDir(): File = Files.createTempDirectory("share").toFile()

    @Test
    fun acceptsOnlyPlainPngNames() {
        assertTrue(ShareImages.isSafeName("sushi-session-20261024-2130.png"))
        assertFalse(ShareImages.isSafeName(null))
        assertFalse(ShareImages.isSafeName("../secrets.png"))
        assertFalse(ShareImages.isSafeName("a/b.png"))
        assertFalse(ShareImages.isSafeName("image.jpg"))
        assertFalse(ShareImages.isSafeName(".png"))
        assertFalse(ShareImages.isSafeName("x".repeat(65) + ".png"))
    }

    @Test
    fun resolvesInsideTheShareFolderOnly() {
        val cache = tempDir()
        assertEquals(File(File(cache, "shared"), "a.png"), ShareImages.fileFor(cache, "a.png"))
        assertNull(ShareImages.fileFor(cache, "../a.png"))
    }

    @Test
    fun keepsOnlyTheLatestImage() {
        val cache = tempDir()
        ShareImages.write(cache, "first.png", byteArrayOf(1))
        val second = ShareImages.write(cache, "second.png", byteArrayOf(2, 3))
        assertArrayEquals(byteArrayOf(2, 3), second.readBytes())
        assertEquals(listOf("second.png"), File(cache, "shared").list()!!.toList())
    }

    @Test(expected = IllegalArgumentException::class)
    fun refusesUnsafeNamesWhenWriting() {
        ShareImages.write(tempDir(), "../escape.png", byteArrayOf(1))
    }
}
