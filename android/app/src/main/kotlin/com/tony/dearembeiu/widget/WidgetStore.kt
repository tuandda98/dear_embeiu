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
 * Shared store between the Flutter channel and the widget provider
 * (feature home-widget). Snapshot keys: lib/services/home_widget_snapshot.dart.
 * The launch flag lives in its own file so clearing a snapshot never eats a tap.
 */
object WidgetStore {
    private const val SNAPSHOT_PREFS = "dear_embeiu_widget"
    private const val LAUNCH_PREFS = "dear_embeiu_widget_launch"
    private const val KEY_FAMILY = "family"
    private const val PHOTO_FILE = "widget_photo.png"

    fun save(context: Context, snapshot: Map<String, String>) {
        val editor = context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE).edit().clear()
        snapshot.forEach { (key, value) -> editor.putString(key, value) }
        editor.apply()
    }

    fun load(context: Context): Map<String, String> =
        context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE).all
            .mapNotNull { (key, value) -> (value as? String)?.let { key to it } }
            .toMap()

    /** PNG already downscaled by Flutter (HomeWidgetBridge.photoMaxEdge); null removes it. */
    fun savePhoto(context: Context, png: ByteArray?) {
        val file = File(context.filesDir, PHOTO_FILE)
        if (png == null) {
            file.delete()
        } else {
            File(file.path + ".tmp").apply { writeBytes(png); renameTo(file) }
        }
    }

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

    fun recordLaunch(context: Context, family: String) {
        context.getSharedPreferences(LAUNCH_PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_FAMILY, family).apply()
    }

    /** Returns the family of the widget that opened the app, once. */
    fun consumeLaunch(context: Context): String? {
        val prefs = context.getSharedPreferences(LAUNCH_PREFS, Context.MODE_PRIVATE)
        val family = prefs.getString(KEY_FAMILY, null) ?: return null
        prefs.edit().remove(KEY_FAMILY).apply()
        return family
    }
}
