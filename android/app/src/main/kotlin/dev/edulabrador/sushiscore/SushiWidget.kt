package dev.edulabrador.sushiscore

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home screen widget with the current session count. Its button opens the
 * app with the same "add one sushi" action as the launcher shortcut, so the
 * count only ever changes inside the app.
 */
class SushiWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        /** Stores [count] and redraws every placed widget. */
        fun refresh(context: Context, count: Int) {
            context.getSharedPreferences(SushiWidgetState.PREFS, Context.MODE_PRIVATE)
                .edit()
                .putInt(SushiWidgetState.KEY_COUNT, count)
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, SushiWidget::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        fun storedCount(context: Context): Int =
            context.getSharedPreferences(SushiWidgetState.PREFS, Context.MODE_PRIVATE)
                .getInt(SushiWidgetState.KEY_COUNT, 0)

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val views = RemoteViews(context.packageName, R.layout.sushi_widget)
            views.setTextViewText(
                R.id.widget_count,
                SushiWidgetState.countText(storedCount(context)),
            )
            views.setOnClickPendingIntent(R.id.widget_root, open(context, Intent.ACTION_MAIN, 0))
            views.setOnClickPendingIntent(
                R.id.widget_add,
                open(context, LaunchActions.ADD_SUSHI_INTENT, 1),
            )
            manager.updateAppWidget(ids, views)
        }

        private fun open(context: Context, action: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
                .setAction(action)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
