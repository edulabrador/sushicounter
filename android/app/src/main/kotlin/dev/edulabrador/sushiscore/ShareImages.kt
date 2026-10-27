package dev.edulabrador.sushiscore

import java.io.File

/** Where shared session images are kept, and which names may be served. */
object ShareImages {
    const val DIRECTORY = "shared"
    private val SAFE_NAME = Regex("[A-Za-z0-9_-]{1,64}\\.png")

    fun isSafeName(name: String?): Boolean = name != null && SAFE_NAME.matches(name)

    /** The file for [name] in the share folder, or null for any other name. */
    fun fileFor(cacheDir: File, name: String?): File? =
        if (name != null && isSafeName(name)) File(File(cacheDir, DIRECTORY), name) else null

    /** Writes [bytes] as the only shared image, so old ones do not pile up. */
    fun write(cacheDir: File, name: String, bytes: ByteArray): File {
        val file = fileFor(cacheDir, name) ?: throw IllegalArgumentException("Unsafe image name")
        val directory = file.parentFile!!
        directory.mkdirs()
        directory.listFiles()?.forEach { if (it.name != file.name) it.delete() }
        file.writeBytes(bytes)
        return file
    }
}
