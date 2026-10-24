package dev.edulabrador.sushiscore

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream

/** Plain helpers for backup files, kept free of Android types for unit tests. */
object TextFiles {
    /** Far above any real backup; stops a wrong pick from exhausting memory. */
    const val MAX_IMPORT_BYTES = 10 * 1024 * 1024
    const val DEFAULT_NAME = "sushi-tracker-backup.json"

    fun readUtf8(input: InputStream, maxBytes: Int = MAX_IMPORT_BYTES): String {
        val output = ByteArrayOutputStream()
        val buffer = ByteArray(8 * 1024)
        var total = 0
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            total += read
            if (total > maxBytes) throw IOException("File is larger than $maxBytes bytes")
            output.write(buffer, 0, read)
        }
        return output.toString(Charsets.UTF_8.name())
    }

    /** A safe document title ending in .json, whatever Dart passes in. */
    fun exportFileName(requested: String?): String {
        val cleaned = requested.orEmpty()
            .replace(Regex("[^A-Za-z0-9._-]"), "-")
            .trim('-', '.')
            .take(80)
        if (cleaned.isEmpty()) return DEFAULT_NAME
        return if (cleaned.endsWith(".json", ignoreCase = true)) cleaned else "$cleaned.json"
    }
}
