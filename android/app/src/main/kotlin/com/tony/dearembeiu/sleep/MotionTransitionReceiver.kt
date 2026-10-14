package com.tony.dearembeiu.sleep

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

class MotionTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!MotionStore.enabled(context)) return
        if (!ActivityTransitionResult.hasResult(intent)) return
        val result = ActivityTransitionResult.extractResult(intent) ?: return
        val bootWall = System.currentTimeMillis() - SystemClock.elapsedRealtime()
        for (e in result.transitionEvents) {
            if (e.activityType != DetectedActivity.STILL) continue
            // elapsedRealtimeNanos is when it happened; delivery may lag.
            val t = bootWall + e.elapsedRealTimeNanos / 1_000_000
            MotionStore.record(context, t, e.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER)
        }
    }
}
