package com.tony.dearembeiu.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.os.Build
import android.os.Bundle
import java.io.File

/**
 * Reader side of the store the Flutter channel writes (feature home-widget).
 * Snapshot keys: lib/services/home_widget_snapshot.dart; status keys:
 * lib/services/home_widget_status.dart. The writer is the plugin
 * packages/dear_embeiu_widget_channel (WidgetChannelPlugin.java, widget-today
 * D13) — file names below must match it. The launch flag lives in its own
 * file so clearing a snapshot never eats a tap.
 */
object WidgetStore {
    private const val SNAPSHOT_PREFS = "dear_embeiu_widget"
    private const val STATUS_PREFS = "dear_embeiu_widget_status"
    private const val LAUNCH_PREFS = "dear_embeiu_widget_launch"
    private const val PHOTO_FILE = "widget_photo.png"

    fun load(context: Context): Map<String, String> = read(context, SNAPSHOT_PREFS)

    /** "Hôm nay" line (feature widget-today, D6): todayDate, statusKind, statusText, … */
    fun loadStatus(context: Context): Map<String, String> = read(context, STATUS_PREFS)

    private fun read(context: Context, file: String): Map<String, String> =
        context.getSharedPreferences(file, Context.MODE_PRIVATE).all
            .mapNotNull { (key, value) -> (value as? String)?.let { key to it } }
            .toMap()

    /**
     * The couple photo center-cropped to this widget's cell and with the
     * corners rounded in the bitmap itself — clipToOutline on the root only
     * clips children from API 31, and the photo must not poke out before that.
     * Null = no photo (the layout keeps the brand gradient).
     */
    fun photoBitmap(context: Context, options: Bundle): Bitmap? {
        val file = File(context.filesDir, PHOTO_FILE)
        if (!file.exists()) return null
        val density = context.resources.displayMetrics.density
        // Portrait cell = min width × max height (AppWidgetManager docs).
        // ponytail: landscape launchers get a slightly stretched photo (fitXY).
        val w = ((options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0).takeIf { it > 0 } ?: 152) * density).toInt().coerceIn(1, 1080)
        val h = ((options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0).takeIf { it > 0 } ?: 152) * density).toInt().coerceIn(1, 1080)
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val src = BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply {
            inSampleSize = maxOf(1, minOf(bounds.outWidth / w, bounds.outHeight / h))
        }) ?: return null
        val scale = maxOf(w.toFloat() / src.width, h.toFloat() / src.height)
        val shader = BitmapShader(src, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP).apply {
            setLocalMatrix(Matrix().apply {
                setScale(scale, scale)
                postTranslate((w - src.width * scale) / 2f, (h - src.height * scale) / 2f)
            })
        }
        val radius = if (Build.VERSION.SDK_INT >= 31) {
            context.resources.getDimension(android.R.dimen.system_app_widget_background_radius)
        } else {
            28f * density
        }
        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        Canvas(out).drawRoundRect(
            RectF(0f, 0f, w.toFloat(), h.toFloat()), radius, radius,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { this.shader = shader },
        )
        src.recycle()
        return out
    }

    /** The plugin's consumeLaunch hands these back to Dart once and clears them. */
    fun recordLaunch(context: Context, family: String, target: String, focus: String, kind: String) {
        context.getSharedPreferences(LAUNCH_PREFS, Context.MODE_PRIVATE).edit()
            .putString("family", family).putString("target", target)
            .putString("focus", focus).putString("kind", kind).apply()
    }
}
