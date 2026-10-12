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
import android.os.Bundle
import com.tony.dearembeiu.widget.DayCounterWidget
import com.tony.dearembeiu.widget.WidgetStore

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Feature home-widget (D3/D8): Dart pushes the pre-translated snapshot,
        // we store it and redraw every widget; consumeLaunch hands back which
        // widget opened the app (recorded from the intent extra below).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dear_embeiu/widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val args = call.arguments as? Map<*, *>
                        val snapshot = args?.entries?.associate { it.key.toString() to it.value.toString() } ?: emptyMap()
                        WidgetStore.save(this, snapshot)
                        DayCounterWidget.updateAll(this)
                        result.success(null)
                    }
                    "setPhoto" -> {
                        WidgetStore.savePhoto(this, call.arguments as? ByteArray)
                        DayCounterWidget.updateAll(this)
                        result.success(null)
                    }
                    "consumeLaunch" -> result.success(WidgetStore.consumeLaunch(this))
                    else -> result.notImplemented()
                }
            }
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Only a fresh launch counts as a tap: a recreated activity (process
        // death, config change) or a relaunch from Recents still carries the
        // original widget intent — system_server keeps it with the extra.
        if (savedInstanceState == null &&
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0) {
            recordWidgetLaunch(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        recordWidgetLaunch(intent)
    }

    /** A tap on the home-screen widget carries its family; park it for Dart (feature home-widget). */
    private fun recordWidgetLaunch(intent: Intent?) {
        val family = intent?.getStringExtra(DayCounterWidget.EXTRA_FAMILY) ?: return
        WidgetStore.recordLaunch(this, family)
        intent.removeExtra(DayCounterWidget.EXTRA_FAMILY)
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
