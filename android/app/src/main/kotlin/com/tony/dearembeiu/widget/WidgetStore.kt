package com.tony.dearembeiu.widget

import android.content.Context

/**
 * Shared store between the Flutter channel and the widget provider
 * (feature home-widget). Snapshot keys: lib/services/home_widget_snapshot.dart.
 * The launch flag lives in its own file so clearing a snapshot never eats a tap.
 */
object WidgetStore {
    private const val SNAPSHOT_PREFS = "dear_embeiu_widget"
    private const val LAUNCH_PREFS = "dear_embeiu_widget_launch"
    private const val KEY_FAMILY = "family"

    fun save(context: Context, snapshot: Map<String, String>) {
        val editor = context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE).edit().clear()
        snapshot.forEach { (key, value) -> editor.putString(key, value) }
        editor.apply()
    }

    fun load(context: Context): Map<String, String> =
        context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE).all
            .mapNotNull { (key, value) -> (value as? String)?.let { key to it } }
            .toMap()

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
