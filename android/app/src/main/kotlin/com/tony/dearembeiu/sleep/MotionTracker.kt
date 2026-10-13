package com.tony.dearembeiu.sleep

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity
import com.google.android.gms.location.ActivityRecognition

object MotionTracker {
    fun hasPermission(c: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            c.checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED

    private fun pendingIntent(c: Context): PendingIntent {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        return PendingIntent.getBroadcast(c, 0, Intent(c, MotionTransitionReceiver::class.java), flags)
    }

    /** Dart-driven: sets enabled, registers, reports the real Task outcome. */
    fun start(c: Context, done: (Boolean) -> Unit) {
        if (!hasPermission(c)) return done(false)
        MotionStore.setEnabled(c)
        register(c, MotionSpans.STALE_OPEN_MS, done)
    }

    /**
     * Boot / app update: only when Dart enabled tracking and the permission is still there.
     * [rebooted]: the phone was off, so an open ENTER is closed now. An app update (often at
     * night, phone still on the charger) only closes a stale one, like [start].
     */
    fun resume(c: Context, rebooted: Boolean) {
        if (MotionStore.enabled(c) && hasPermission(c)) {
            register(c, if (rebooted) 0 else MotionSpans.STALE_OPEN_MS) {}
        }
    }

    /** Idempotent: re-registering the same PendingIntent replaces the old request. */
    private fun register(c: Context, closeMinAgeMs: Long, done: (Boolean) -> Unit) {
        try {
            val now = System.currentTimeMillis()
            MotionStore.closeOpen(c, now, closeMinAgeMs)
            val transitions = listOf(
                ActivityTransition.ACTIVITY_TRANSITION_ENTER,
                ActivityTransition.ACTIVITY_TRANSITION_EXIT,
            ).map {
                ActivityTransition.Builder()
                    .setActivityType(DetectedActivity.STILL)
                    .setActivityTransition(it)
                    .build()
            }
            ActivityRecognition.getClient(c)
                .requestActivityTransitionUpdates(ActivityTransitionRequest(transitions), pendingIntent(c))
                .addOnSuccessListener { MotionStore.markCoverage(c, now); done(true) }
                .addOnFailureListener { done(false) }
        } catch (_: Exception) {
            done(false)
        }
    }

    fun stop(c: Context, done: (Boolean) -> Unit) {
        // Clear first: even if removal fails, nothing is recorded (receiver checks enabled).
        MotionStore.clear(c)
        try {
            ActivityRecognition.getClient(c)
                .removeActivityTransitionUpdates(pendingIntent(c))
                .addOnSuccessListener { done(true) }
                .addOnFailureListener { done(false) }
        } catch (_: Exception) {
            done(false)
        }
    }
}
