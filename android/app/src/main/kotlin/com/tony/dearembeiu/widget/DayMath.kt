package com.tony.dearembeiu.widget

import java.text.NumberFormat
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.Locale

/**
 * Day count + next milestone for the home-screen widget. Mirrors Dart
 * (LoveTreeService.daysTogether, _getNextMilestone / _milestoneLabel in
 * home_screen.dart) and ios/DearEmbeiuWidget/DayMath.swift — change all three
 * together or the widget drifts from the Home counter. java.time via
 * coreLibraryDesugaring on older Android.
 */
object DayMath {
    val milestones = intArrayOf(30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000)

    data class LabelStrings(
        val monthsOne: String,
        val monthsFmt: String,
        val yearsOne: String,
        val yearsFmt: String,
        val daysFmt: String,
    )

    /** Calendar days from `anniversary` (yyyy-MM-dd) to `today`, never below 0. */
    fun daysTogether(anniversary: String, today: LocalDate): Int {
        val start = try {
            LocalDate.parse(anniversary)
        } catch (_: Exception) {
            return 0
        }
        return ChronoUnit.DAYS.between(start, today).toInt().coerceAtLeast(0)
    }

    fun nextMilestone(days: Int): Int =
        milestones.firstOrNull { days < it } ?: ((days / 500) + 1) * 500

    /** The Home progress bar: days / next, clamped to 0…1. */
    fun progress(days: Int, next: Int): Float =
        if (next <= 0) 0f else (days.toFloat() / next).coerceIn(0f, 1f)

    /** Grouped integer in the app's language (vi → 1.500, en → 1,500). */
    fun format(n: Int, lang: String): String {
        val locale = if (lang == "vi") Locale.forLanguageTag("vi-VN") else Locale.US
        return NumberFormat.getIntegerInstance(locale).format(n)
    }

    /** "6 tháng" / "1 năm" / "1.500 ngày" from the snapshot's templates. */
    fun milestoneLabel(next: Int, s: LabelStrings, number: (Int) -> String): String = when {
        next % 365 == 0 -> (next / 365).let { if (it == 1) s.yearsOne else s.yearsFmt.replace("{count}", number(it)) }
        next < 365 && next % 30 == 0 -> (next / 30).let { if (it == 1) s.monthsOne else s.monthsFmt.replace("{count}", number(it)) }
        else -> s.daysFmt.replace("{count}", number(next))
    }
}
