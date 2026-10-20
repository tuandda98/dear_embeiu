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
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.tony.dearembeiu.sleep.MotionStore
import com.tony.dearembeiu.sleep.MotionTracker
import com.tony.dearembeiu.widget.DayCounterWidget
import com.tony.dearembeiu.widget.WidgetStore

private const val MOTION_REQ = 4711

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The widget channel (`dear_embeiu/widget`) is the plugin in
        // packages/dear_embeiu_widget_channel (widget-today D13): registered
        // here by GeneratedPluginRegistrant AND in firebase_messaging's
        // background engine, which never runs this method.
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
                    "motionSupported" -> result.success(
                        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(this) == ConnectionResult.SUCCESS
                    )
                    "motionPermission" -> result.success(motionPermission())
                    "requestMotionPermission" -> requestMotionPermission(result)
                    "startMotionTracking" -> MotionTracker.start(this) { result.success(it) }
                    "stopMotionTracking" -> MotionTracker.stop(this) { result.success(it) }
                    "motionCoverageStart" -> result.success(MotionStore.coverageStart(this))
                    "motionStillSpans" -> {
                        val from = call.argument<Number>("from")?.toLong() ?: 0L
                        val to = call.argument<Number>("to")?.toLong() ?: System.currentTimeMillis()
                        result.success(
                            try { MotionStore.stillSpans(this, from, to) } catch (_: Exception) { LongArray(0) }
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private var pendingMotionResult: MethodChannel.Result? = null

    private fun motionPermission(): String = when {
        MotionTracker.hasPermission(this) -> "granted"
        MotionStore.asked(this) -> "denied"
        else -> "notDetermined"
    }

    private fun requestMotionPermission(result: MethodChannel.Result) {
        if (MotionTracker.hasPermission(this)) {
            result.success(true)
            return
        }
        pendingMotionResult?.success(false)
        pendingMotionResult = result
        MotionStore.markAsked(this)
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACTIVITY_RECOGNITION), MOTION_REQ)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != MOTION_REQ) return
        val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingMotionResult?.success(ok)
        pendingMotionResult = null
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

    /**
     * A tap on the home-screen widget carries its family and where the "hôm
     * nay" line points (widget-today D7); park them for Dart (consumeLaunch).
     */
    private fun recordWidgetLaunch(intent: Intent?) {
        val family = intent?.getStringExtra(DayCounterWidget.EXTRA_FAMILY) ?: return
        WidgetStore.recordLaunch(
            this, family,
            target = intent.getStringExtra(DayCounterWidget.EXTRA_TARGET) ?: "",
            focus = intent.getStringExtra(DayCounterWidget.EXTRA_FOCUS) ?: "",
            kind = intent.getStringExtra(DayCounterWidget.EXTRA_KIND) ?: "",
        )
        for (extra in listOf(DayCounterWidget.EXTRA_FAMILY, DayCounterWidget.EXTRA_TARGET,
                DayCounterWidget.EXTRA_FOCUS, DayCounterWidget.EXTRA_KIND)) {
            intent.removeExtra(extra)
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
