package com.tony.dearembeiu.sleep

import android.content.Context

/** Pure string logic (unit-tested): events = "<ms>:<1|0>,…" (1 = ENTER STILL, 0 = EXIT). */
object MotionSpans {
    const val KEEP_MS = 14L * 24 * 3600 * 1000

    fun parse(raw: String?): List<Pair<Long, Boolean>> =
        (raw ?: "").split(',').mapNotNull {
            val p = it.split(':')
            val t = p.getOrNull(0)?.toLongOrNull() ?: return@mapNotNull null
            if (p.size != 2) return@mapNotNull null
            t to (p[1] == "1")
        }

    fun format(events: List<Pair<Long, Boolean>>): String =
        events.joinToString(",") { "${it.first}:${if (it.second) 1 else 0}" }

    /** Append, sort, drop older than 14 days. */
    fun append(raw: String?, t: Long, enter: Boolean, now: Long): String =
        format((parse(raw) + (t to enter)).filter { it.first >= now - KEEP_MS }.sortedBy { it.first })

    /** Flat [start, end, …] still spans clipped to [from,to]; open span closes at min(to, now). */
    fun stillSpans(raw: String?, from: Long, to: Long, now: Long): LongArray {
        val out = ArrayList<Long>()
        var open: Long? = null
        fun emit(s: Long, e: Long) {
            val a = maxOf(s, from)
            val b = minOf(e, to)
            if (b > a) { out.add(a); out.add(b) }
        }
        for ((t, enter) in parse(raw).sortedBy { it.first }) {
            if (enter) {
                if (open == null) open = t
            } else if (open != null) {
                emit(open, t)
                open = null
            }
        }
        open?.let { emit(it, minOf(to, now)) }
        return out.toLongArray()
    }
}

object MotionStore {
    private const val PREFS = "dear_embeiu_motion"
    private const val KEY = "events"
    private const val ASKED = "asked"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun record(c: Context, t: Long, enter: Boolean) {
        val p = prefs(c)
        p.edit().putString(KEY, MotionSpans.append(p.getString(KEY, null), t, enter, System.currentTimeMillis())).apply()
    }

    fun stillSpans(c: Context, from: Long, to: Long): LongArray =
        MotionSpans.stillSpans(prefs(c).getString(KEY, null), from, to, System.currentTimeMillis())

    fun asked(c: Context) = prefs(c).getBoolean(ASKED, false)
    fun markAsked(c: Context) = prefs(c).edit().putBoolean(ASKED, true).apply()
}
