package dev.edulabrador.sushiscore

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LaunchActionsTest {
    @Test
    fun shortcutIntentAddsSushi() {
        assertEquals(
            LaunchActions.ADD_SUSHI,
            LaunchActions.actionFor(LaunchActions.ADD_SUSHI_INTENT, 0, isRestoring = false),
        )
    }

    @Test
    fun normalLaunchDoesNothing() {
        assertNull(LaunchActions.actionFor("android.intent.action.MAIN", 0, isRestoring = false))
        assertNull(LaunchActions.actionFor(null, 0, isRestoring = false))
    }

    @Test
    fun relaunchFromRecentsDoesNotAddAgain() {
        assertNull(
            LaunchActions.actionFor(
                LaunchActions.ADD_SUSHI_INTENT,
                LaunchActions.FLAG_LAUNCHED_FROM_HISTORY or 0x10000000,
                isRestoring = false,
            ),
        )
    }

    @Test
    fun restoredActivityDoesNotAddAgain() {
        assertNull(LaunchActions.actionFor(LaunchActions.ADD_SUSHI_INTENT, 0, isRestoring = true))
    }

    @Test
    fun historyFlagMatchesAndroid() {
        // Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY, documented as 0x00100000.
        assertEquals(1048576, LaunchActions.FLAG_LAUNCHED_FROM_HISTORY)
    }
}
