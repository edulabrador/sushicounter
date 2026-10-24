package dev.edulabrador.sushiscore

/** Maps launcher-shortcut intents to actions the Flutter side understands. */
object LaunchActions {
    const val ADD_SUSHI_INTENT = "dev.edulabrador.sushiscore.ADD_SUSHI"
    const val ADD_SUSHI = "addSushi"

    /** Same value as android.content.Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY. */
    const val FLAG_LAUNCHED_FROM_HISTORY = 0x00100000

    /**
     * The action an intent asks for, or null. A shortcut must add exactly one
     * sushi per tap, so relaunches from Recents and activity restores (which
     * replay the original intent) are ignored.
     */
    fun actionFor(intentAction: String?, flags: Int, isRestoring: Boolean): String? {
        if (isRestoring || flags and FLAG_LAUNCHED_FROM_HISTORY != 0) return null
        return if (intentAction == ADD_SUSHI_INTENT) ADD_SUSHI else null
    }
}
