package com.tony.dearembeiu.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
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
open class DayCounterWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
    }

    /** The widget channel plugin (widget-today D13) asks for a redraw after every write. */
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) updateAll(context) else super.onReceive(context, intent)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, newOptions: Bundle) {
        render(context, manager, id)
    }

    companion object {
        const val EXTRA_FAMILY = "widget_family"
        // Where the "hôm nay" line on screen points (widget-today D7) + its kind for analytics.
        const val EXTRA_TARGET = "widget_target"
        const val EXTRA_FOCUS = "widget_focus"
        const val EXTRA_KIND = "widget_kind"
        // Sent by packages/dear_embeiu_widget_channel (WidgetChannelPlugin.ACTION_REFRESH).
        const val ACTION_REFRESH = "com.tony.dearembeiu.widget.REFRESH"
        private const val MEDIUM_MIN_WIDTH_DP = 250

        private val PROVIDERS = listOf(DayCounterWidget::class.java, DayCounterWidgetMedium::class.java)

        /** Called by the Flutter channel after every snapshot / photo update. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for (cls in PROVIDERS) {
                manager.getAppWidgetIds(ComponentName(context, cls)).forEach { render(context, manager, it) }
            }
            updatePickerPreviews(context, manager)
        }

        /**
         * The widget picker (2026-10-13, user: "preview khác widget ngoài màn
         * hình"): below API 35 the launcher only inflates `previewLayout` — static
         * XML, no snapshot, no photo — so the picker shows the night-sky sample.
         * API 35+ accepts a generated preview: hand it the SAME RemoteViews the
         * real widget gets (names, count, photo). Rate-limited by the system, so
         * only from updateAll (data changed), never from onUpdate.
         */
        private fun updatePickerPreviews(context: Context, manager: AppWidgetManager) {
            if (Build.VERSION.SDK_INT < 35) return
            val snapshot = WidgetStore.load(context)
            if (snapshot["state"] != "counter") return // XML sample is fine for the empty state
            for ((cls, medium) in listOf(DayCounterWidget::class.java to false, DayCounterWidgetMedium::class.java to true)) {
                val options = Bundle().apply {
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, if (medium) 328 else 152)
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 152)
                }
                val views = counterViews(context, snapshot, medium)
                val photo = WidgetStore.photoBitmap(context, options)
                if (photo != null) {
                    views.setImageViewBitmap(R.id.widget_photo, photo)
                    views.setViewVisibility(R.id.widget_photo, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)
                }
                // Never a status line in the picker: a sample, and private (design §6).
                applyStyle(views, dark = photo == null, counter = true, medium = medium, status = null)
                try {
                    manager.setWidgetPreview(ComponentName(context, cls), AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN, views)
                } catch (_: Exception) {
                    // Rate limit / host without the API: the XML sample stays.
                }
            }
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
            val status = if (counter) todayStatus(WidgetStore.loadStatus(context)) else null
            applyStyle(views, dark = photo == null, counter = counter, medium = medium, status = status,
                fontScale = context.resources.configuration.fontScale)
            views.setOnClickPendingIntent(R.id.widget_root, openApp(context, if (medium) "medium" else "small", status))
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
                val pct = (DayMath.progress(days, next) * 100).toInt()
                views.setProgressBar(R.id.widget_progress, 100, pct, false)
                views.setProgressBar(R.id.widget_progress_light, 100, pct, false)
                views.setTextViewText(R.id.widget_since, s["sinceText"] ?: "")
            }
            return views
        }

        /**
         * Night sky (design M2: translucent chip, white ink, lavender bar,
         * stars) without a photo; photo style (P3: white chip, navy ink, white
         * bar, no stars) with one. EVERY stateful property is set in BOTH
         * branches: when the layout id is unchanged the host REAPPLIES the new
         * RemoteViews onto the existing view tree instead of inflating it, so
         * XML defaults do not come back on their own (smoke 2026-10-12: the
         * previous couple's photo stayed under the new names). Only ids the
         * inflated layout has are touched — an action on a missing id fails
         * the whole widget.
         */
        /**
         * The stored "hôm nay" line, or null unless it belongs to today (D4.1:
         * after 0:00 it disappears at the next redraw, ≤30' with
         * updatePeriodMillis) and has text.
         */
        fun todayStatus(status: Map<String, String>, today: LocalDate = LocalDate.now()): Map<String, String>? =
            status.takeIf { it["todayDate"] == today.toString() && !it["statusText"].isNullOrEmpty() }

        private fun applyStyle(
            views: RemoteViews, dark: Boolean, counter: Boolean, medium: Boolean,
            status: Map<String, String>?, fontScale: Float = 1f,
        ) {
            val ink = if (dark) 0xFFFFFFFF.toInt() else 0xFF1A1A2E.toInt()
            views.setInt(R.id.widget_chip, "setBackgroundResource", if (dark) R.drawable.widget_chip_bg_dark else R.drawable.widget_chip_bg)
            views.setTextColor(R.id.widget_name1, ink)
            views.setImageViewResource(R.id.widget_heart, if (dark) R.drawable.widget_heart_light else R.drawable.widget_heart)
            views.setViewVisibility(R.id.widget_stars, if (dark) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.widget_sky, if (dark) View.VISIBLE else View.GONE)
            if (dark) {
                views.setImageViewBitmap(R.id.widget_photo, null)
                views.setViewVisibility(R.id.widget_photo, View.GONE)
                views.setViewVisibility(R.id.widget_scrim, View.GONE)
            }
            if (counter) views.setTextColor(R.id.widget_name2, ink)
            if (counter && medium) {
                views.setViewVisibility(R.id.widget_progress, if (dark) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.widget_progress_light, if (dark) View.GONE else View.VISIBLE)
                // Night sky: keep 48dp clear for the constellation top-right.
                views.setViewPadding(R.id.widget_milestone, 0, 0, if (dark) dp(views, 48) else 0, 0)
            }
            // "Hôm nay" line (widget-today, design §5.4/§9.1): both branches set
            // every property, for the same reapply reason as above. No status =
            // XML defaults = pixel-identical to 1.9.1.
            if (counter) {
                val show = status != null
                val text = if (medium) status?.get("statusText")
                    else status?.get("statusTextShort")?.takeIf { it.isNotEmpty() } ?: status?.get("statusText")
                views.setViewVisibility(R.id.widget_status, if (show) View.VISIBLE else View.GONE)
                views.setTextViewText(R.id.widget_status_text, text ?: "")
                views.setImageViewResource(R.id.widget_status_dot,
                    if (dark) R.drawable.widget_status_dot else R.drawable.widget_status_dot_light)
                if (medium) {
                    views.setViewVisibility(R.id.widget_since, if (show) View.GONE else View.VISIBLE)
                    views.setInt(R.id.widget_status_text, "setMaxLines", if (fontScale >= 1.3f) 1 else 2)
                } else {
                    views.setInt(R.id.widget_caption, "setMaxLines", if (show) 1 else 2)
                }
            }
        }

        private fun dp(views: RemoteViews, v: Int): Int =
            (v * android.content.res.Resources.getSystem().displayMetrics.density).toInt()

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
        private fun openApp(context: Context, family: String, status: Map<String, String>?): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_FAMILY, family)
                // "" when no line shows: the tap then lands on Home as before.
                putExtra(EXTRA_TARGET, status?.get("statusTarget") ?: "")
                putExtra(EXTRA_FOCUS, status?.get("statusFocus") ?: "")
                putExtra(EXTRA_KIND, status?.get("statusKind") ?: "")
            }
            val requestCode = if (family == "medium") 2 else 1
            return PendingIntent.getActivity(context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
    }
}

/** The 4×2 picker entry (xml/widget_day_info_medium). Same rendering. */
class DayCounterWidgetMedium : DayCounterWidget()
