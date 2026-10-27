package dev.edulabrador.sushiscore

/** What the home screen widget shows, kept free of Android types for tests. */
object SushiWidgetState {
    const val PREFS = "sushi_widget"
    const val KEY_COUNT = "count"
    private const val MAX_SHOWN = 9999

    /** The count as the widget shows it: never negative, capped to fit. */
    fun countText(count: Int): String = when {
        count < 0 -> "0"
        count > MAX_SHOWN -> "$MAX_SHOWN+"
        else -> count.toString()
    }
}
