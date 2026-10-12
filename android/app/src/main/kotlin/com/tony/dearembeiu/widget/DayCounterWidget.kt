package com.tony.dearembeiu.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.tony.dearembeiu.MainActivity
import com.tony.dearembeiu.R
import java.time.LocalDate

/**
 * Home-screen day counter (feature home-widget). Reads the snapshot Flutter
 * stored through [WidgetStore], recomputes days + milestone ([DayMath]) and
 * picks the small or medium layout from the current cell width.
 */
class DayCounterWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, newOptions: Bundle) {
        render(context, manager, id)
    }

    companion object {
        const val EXTRA_FAMILY = "widget_family"
        private const val MEDIUM_MIN_WIDTH_DP = 250

        /** Called by the Flutter channel after every snapshot update. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, DayCounterWidget::class.java))
                .forEach { render(context, manager, it) }
        }

        fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val snapshot = WidgetStore.load(context)
            val minWidth = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val medium = minWidth >= MEDIUM_MIN_WIDTH_DP
            val counter = snapshot["state"] == "counter"
            val views = if (counter) counterViews(context, snapshot, medium) else emptyViews(context, snapshot)
            // Couple photo behind the numbers (the one the CounterCard shows);
            // the empty state never shows a photo even if a stale file exists.
            val photo = if (counter) WidgetStore.photoBitmap(context, manager.getAppWidgetOptions(id)) else null
            if (photo != null) {
                views.setImageViewBitmap(R.id.widget_photo, photo)
                views.setViewVisibility(R.id.widget_photo, View.VISIBLE)
                views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)
            }
            views.setOnClickPendingIntent(R.id.widget_root, openApp(context, if (medium) "medium" else "small"))
            manager.updateAppWidget(id, views)
        }

        private fun counterViews(context: Context, s: Map<String, String>, medium: Boolean): RemoteViews {
            val lang = s["lang"] ?: "vi"
            val days = DayMath.daysTogether(s["anniversary"] ?: "", LocalDate.now())
            val next = DayMath.nextMilestone(days)
            val number = { n: Int -> DayMath.format(n, lang) }
            val views = RemoteViews(context.packageName, if (medium) R.layout.widget_day_medium else R.layout.widget_day_small)
            bindChip(views, s["name1"] ?: "", s["name2"] ?: "")
            views.setTextViewText(R.id.widget_days, number(days))
            views.setTextViewText(R.id.widget_caption, s["daysLabel"] ?: "")
            if (medium) {
                val strings = DayMath.LabelStrings(
                    monthsOne = s["monthsOne"] ?: "", monthsFmt = s["monthsFmt"] ?: "{count}",
                    yearsOne = s["yearsOne"] ?: "", yearsFmt = s["yearsFmt"] ?: "{count}",
                    daysFmt = s["daysFmt"] ?: "{count}",
                )
                val label = DayMath.milestoneLabel(next, strings, number)
                views.setTextViewText(R.id.widget_milestone, (s["milestoneFmt"] ?: "{label}").replace("{label}", label))
                val left = next - days
                views.setTextViewText(R.id.widget_days_left, when {
                    left <= 0 -> s["todayLabel"] ?: ""
                    left == 1 -> s["daysLeftOne"] ?: ""
                    else -> (s["daysLeftFmt"] ?: "{count}").replace("{count}", number(left))
                })
                views.setProgressBar(R.id.widget_progress, 100, (DayMath.progress(days, next) * 100).toInt(), false)
                views.setTextViewText(R.id.widget_since, s["sinceText"] ?: "")
            }
            return views
        }

        private fun emptyViews(context: Context, s: Map<String, String>): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_day_empty)
            views.setTextViewText(R.id.widget_name1, s["emptyChip"] ?: "DEAR EMBEIU")
            views.setTextViewText(R.id.widget_empty_text, s["emptyText"] ?: context.getString(R.string.widget_empty_tap))
            return views
        }

        private fun bindChip(views: RemoteViews, name1: String, name2: String) {
            views.setTextViewText(R.id.widget_name1, name1)
            views.setTextViewText(R.id.widget_name2, name2)
            views.setViewVisibility(R.id.widget_name1, if (name1.isEmpty()) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_name2, if (name2.isEmpty()) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_heart, if (name1.isEmpty() || name2.isEmpty()) View.GONE else View.VISIBLE)
        }

        /** Explicit intent (not ACTION_MAIN) so a running singleTop MainActivity gets onNewIntent + the extra. */
        private fun openApp(context: Context, family: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_FAMILY, family)
            }
            val requestCode = if (family == "medium") 2 else 1
            return PendingIntent.getActivity(context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
    }
}
