package com.tony.dearembeiu

import android.Manifest
import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Feature sleep (2026-10-10): rebuild last nights from screen on/off
        // events (UsageStatsManager, API 28+). Needs the special "Usage access"
        // the user grants in system Settings. Reads timestamps only — no app
        // names, no content.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dear_embeiu/sleep")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                    "hasPermission" -> result.success(hasUsageAccess())
                    "requestPermission", "openSettings" -> {
                        openUsageAccessSettings()
                        result.success(false)
                    }
                    "screenEvents" -> {
                        val from = call.argument<Number>("from")?.toLong() ?: 0L
                        val to = call.argument<Number>("to")?.toLong() ?: System.currentTimeMillis()
                        // Iterating two weeks of usage events can take a moment.
                        Thread {
                            val events = try {
                                screenEvents(from, to)
                            } catch (_: Exception) {
                                LongArray(0)
                            }
                            Handler(Looper.getMainLooper()).post { result.success(events) }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return if (mode == AppOpsManager.MODE_DEFAULT) {
            checkCallingOrSelfPermission(Manifest.permission.PACKAGE_USAGE_STATS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            mode == AppOpsManager.MODE_ALLOWED
        }
    }

    private fun openUsageAccessSettings() {
        // Some OEMs open this app's own toggle when the package is given; the
        // rest only know the generic list.
        try {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, Uri.parse("package:$packageName")))
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
            } catch (_: Exception) {
                // No settings screen at all — the app keeps its manual mode.
            }
        }
    }

    /** Flat [time, 1|0, time, 1|0, …] — 1 = screen became interactive. */
    private fun screenEvents(from: Long, to: Long): LongArray {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return LongArray(0)
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(from, to) ?: return LongArray(0)
        val out = ArrayList<Long>()
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.SCREEN_INTERACTIVE -> {
                    out.add(event.timeStamp)
                    out.add(1L)
                }
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    out.add(event.timeStamp)
                    out.add(0L)
                }
            }
        }
        return out.toLongArray()
    }
}
