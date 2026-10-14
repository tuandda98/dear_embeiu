package com.tony.dearembeiu.sleep

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Re-register transition updates after reboot / app update (registration is lost). */
class MotionBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        MotionTracker.resume(context, rebooted = intent.action == Intent.ACTION_BOOT_COMPLETED)
    }
}
