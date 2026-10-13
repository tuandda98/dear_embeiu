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

    /** Idempotent: re-registering the same PendingIntent replaces the old request. */
    fun start(c: Context): Boolean {
        if (!hasPermission(c)) return false
        return try {
            val transitions = listOf(
                ActivityTransition.ACTIVITY_TRANSITION_ENTER,
                ActivityTransition.ACTIVITY_TRANSITION_EXIT,
            ).map {
                ActivityTransition.Builder()
                    .setActivityType(DetectedActivity.STILL)
                    .setActivityTransition(it)
                    .build()
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            val pi = PendingIntent.getBroadcast(
                c, 0, Intent(c, MotionTransitionReceiver::class.java), flags,
            )
            ActivityRecognition.getClient(c)
                .requestActivityTransitionUpdates(ActivityTransitionRequest(transitions), pi)
            true
        } catch (_: Exception) {
            false
        }
    }
}
