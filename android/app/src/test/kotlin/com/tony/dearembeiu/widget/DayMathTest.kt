package com.tony.dearembeiu.widget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Feature home-widget: DayMath.kt must match Dart (LoveTreeService.daysTogether
 * + _getNextMilestone in home_screen.dart) and ios/DearEmbeiuWidget/DayMath.swift
 * — same vectors in all three.
 */
class DayMathTest {
    private val today = LocalDate.of(2026, 10, 12)

    @Test
    fun daysTogether_countsCalendarDays_neverNegative() {
        assertEquals(0, DayMath.daysTogether("2026-10-12", today))
        assertEquals(1, DayMath.daysTogether("2026-10-11", today))
        assertEquals(365, DayMath.daysTogether("2025-10-12", today))
        assertEquals(1247, DayMath.daysTogether("2023-05-14", today))
        assertEquals(0, DayMath.daysTogether("2026-10-13", today))
        assertEquals(0, DayMath.daysTogether("garbage", today))
    }

    @Test
    fun nextMilestone_matchesHome() {
        val table = listOf(0 to 30, 29 to 30, 30 to 50, 364 to 365, 365 to 500, 1247 to 1500,
            2999 to 3000, 3000 to 3500, 3499 to 3500, 3500 to 4000)
        table.forEach { (days, next) -> assertEquals("next($days)", next, DayMath.nextMilestone(days)) }
    }

    @Test
    fun progress_isDaysOverNext_clamped() {
        assertEquals(0.8313f, DayMath.progress(1247, 1500), 0.001f)
        assertEquals(1f, DayMath.progress(10, 5), 0f)
        assertEquals(0f, DayMath.progress(10, 0), 0f)
    }

    @Test
    fun format_groupsPerLanguage() {
        assertEquals("1.500", DayMath.format(1500, "vi"))
        assertEquals("1,500", DayMath.format(1500, "en"))
    }

    @Test
    fun milestoneLabel_monthsYearsDays() {
        val s = DayMath.LabelStrings(monthsOne = "1 month", monthsFmt = "{count} months",
            yearsOne = "1 year", yearsFmt = "{count} years", daysFmt = "{count} days")
        val label = { n: Int -> DayMath.milestoneLabel(n, s) { DayMath.format(it, "en") } }
        assertEquals("1 month", label(30))
        assertEquals("6 months", label(180))
        assertEquals("1 year", label(365))
        assertEquals("2 years", label(730))
        assertEquals("1,500 days", label(1500))
        assertEquals("50 days", label(50))
    }
}
