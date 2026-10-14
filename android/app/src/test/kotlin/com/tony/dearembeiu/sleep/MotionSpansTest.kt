package com.tony.dearembeiu.sleep

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class MotionSpansTest {
    private val now = 1_000_000L

    @Test
    fun pairsEnterExit_clipsToWindow() {
        val raw = "100:1,200:0,300:1,400:0"
        assertArrayEquals(longArrayOf(100, 200, 300, 400), MotionSpans.stillSpans(raw, 0, 1000, now))
        assertArrayEquals(longArrayOf(150, 200, 300, 350), MotionSpans.stillSpans(raw, 150, 350, now))
    }

    @Test
    fun openSpan_closesAtMinToNow() {
        assertArrayEquals(longArrayOf(100, 500), MotionSpans.stillSpans("100:1", 0, 500, now))
        assertArrayEquals(longArrayOf(100, now), MotionSpans.stillSpans("100:1", 0, 5_000_000, now))
    }

    @Test
    fun orphanExit_ignored_garbageSkipped() {
        assertArrayEquals(longArrayOf(), MotionSpans.stillSpans("50:0,x:1,,7", 0, 1000, now))
    }

    @Test
    fun append_sortsAndPrunes() {
        val big = 10 * MotionSpans.KEEP_MS
        val old = big - MotionSpans.KEEP_MS - 1
        assertEquals("${big - 20}:0,${big - 10}:1", MotionSpans.append("$old:1,${big - 10}:1", big - 20, false, big))
        assertEquals("${big - 10}:1", MotionSpans.append(null, big - 10, true, big))
    }

    @Test
    fun closeOpen_addsSyntheticExitOnlyWhenLastIsEnter() {
        assertEquals("100:1,500:0", MotionSpans.closeOpen("100:1", 500))
        assertEquals("100:1,200:0", MotionSpans.closeOpen("100:1,200:0", 500))
        assertEquals("", MotionSpans.closeOpen(null, 500))
        assertArrayEquals(longArrayOf(100, 500), MotionSpans.stillSpans(MotionSpans.closeOpen("100:1", 500), 0, 5_000, 5_000))
    }

    @Test
    fun closeOpen_appStart_onlyClosesStaleEnter() {
        val h = 3600_000L
        val stale = MotionSpans.STALE_OPEN_MS
        val now = 100 * h
        // fresh ENTER (3h old): left open
        assertEquals("${now - 3 * h}:1", MotionSpans.closeOpen("${now - 3 * h}:1", now, stale))
        // stuck ENTER (>=16h old): closed at now
        assertEquals("${now - 17 * h}:1,$now:0", MotionSpans.closeOpen("${now - 17 * h}:1", now, stale))
        // boot (minAge 0): closed regardless of age
        assertEquals("${now - 3 * h}:1,$now:0", MotionSpans.closeOpen("${now - 3 * h}:1", now))
    }
}
