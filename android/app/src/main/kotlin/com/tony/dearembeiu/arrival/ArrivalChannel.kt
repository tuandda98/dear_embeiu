package com.tony.dearembeiu.arrival

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.Locale

private const val ARRIVAL_REQ = 4712
private const val PREFS = "dear_embeiu_arrival"

/**
 * Feature arrival (đợt 2): location permission, one location fix for "Dùng vị
 * trí hiện tại" and address search for the place screens. Main engine only —
 * the geofence background callback (plugin native_geofence) never calls it.
 * Coordinates read here go back to Dart and stay on the phone (D2).
 */
class ArrivalChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val main = Handler(Looper.getMainLooper())
    private var pendingPermission: MethodChannel.Result? = null
    private var permissionAskedAt = 0L
    private var askingBackground = false

    init {
        MethodChannel(messenger, "dear_embeiu/arrival").setMethodCallHandler { call, result ->
            when (call.method) {
                "permission" -> result.success(state())
                "requestWhenInUse" -> requestWhenInUse(result)
                "requestAlways" -> requestAlways(result)
                "openSettings" -> {
                    openAppSettings()
                    result.success(null)
                }
                "backgroundLabel" -> result.success(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        activity.packageManager.backgroundPermissionOptionLabel.toString()
                    } else {
                        null
                    }
                )
                "currentFix" -> currentFix(call.argument<Number>("timeoutMs")?.toLong() ?: 15000L, result)
                "searchAvailable" -> result.success(Geocoder.isPresent())
                "search" -> search(call.argument<String>("query") ?: "", result)
                else -> result.notImplemented()
            }
        }
    }

    // ── Permission (D8) ─────────────────────────────────────────────────────

    private fun granted(p: String) =
        ContextCompat.checkSelfPermission(activity, p) == PackageManager.PERMISSION_GRANTED

    private fun state(): Map<String, Any> {
        val fine = granted(Manifest.permission.ACCESS_FINE_LOCATION)
        val any = fine || granted(Manifest.permission.ACCESS_COARSE_LOCATION)
        val background = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            granted(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        val asked = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean("asked", false)
        val level = when {
            !any -> if (asked) "denied" else "notDetermined"
            background -> "always"
            else -> "whenInUse"
        }
        return mapOf("level" to level, "precise" to fine)
    }

    private fun ask(result: MethodChannel.Result, permissions: Array<String>, background: Boolean) {
        pendingPermission?.success(state())
        pendingPermission = result
        askingBackground = background
        permissionAskedAt = SystemClock.elapsedRealtime()
        activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean("asked", true).apply()
        ActivityCompat.requestPermissions(activity, permissions, ARRIVAL_REQ)
    }

    private fun requestWhenInUse(result: MethodChannel.Result) {
        ask(
            result,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            background = false,
        )
    }

    /** API 30+: the system opens the app's location page ("Cho phép mọi lúc"). */
    private fun requestAlways(result: MethodChannel.Result) {
        val any = granted(Manifest.permission.ACCESS_FINE_LOCATION) ||
            granted(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || !any) {
            result.success(state())
            return
        }
        ask(result, arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION), background = true)
    }

    /** From MainActivity.onRequestPermissionsResult; true = ours. */
    fun onPermissionResult(requestCode: Int): Boolean {
        if (requestCode != ARRIVAL_REQ) return false
        // An answer within 400 ms = the system showed nothing (the user had
        // refused for good): send them to the app's page instead.
        if (askingBackground &&
            !granted(Manifest.permission.ACCESS_BACKGROUND_LOCATION) &&
            SystemClock.elapsedRealtime() - permissionAskedAt < 400) {
            openAppSettings()
        }
        pendingPermission?.success(state())
        pendingPermission = null
        return true
    }

    private fun openAppSettings() {
        try {
            activity.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))
            )
        } catch (_: Exception) {
        }
    }

    // ── One fix ("Dùng vị trí hiện tại") ────────────────────────────────────

    private fun currentFix(timeoutMs: Long, result: MethodChannel.Result) {
        val fine = granted(Manifest.permission.ACCESS_FINE_LOCATION)
        if (!fine && !granted(Manifest.permission.ACCESS_COARSE_LOCATION)) {
            result.success(null)
            return
        }
        val lm = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val candidates = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            if (fine) add(LocationManager.GPS_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
        }
        val provider = candidates.firstOrNull {
            try { lm.isProviderEnabled(it) } catch (_: Exception) { false }
        }
        if (provider == null) {
            result.success(null) // location services off
            return
        }
        var done = false
        val cancel = CancellationSignal()
        var listener: LocationListener? = null
        fun finish(location: Location?) {
            if (done) return
            done = true
            listener?.let { lm.removeUpdates(it) }
            cancel.cancel()
            result.success(
                location?.let {
                    mapOf(
                        "lat" to it.latitude,
                        "lng" to it.longitude,
                        "accuracy" to (if (it.hasAccuracy()) it.accuracy.toDouble() else 0.0),
                    )
                }
            )
        }
        main.postDelayed({ finish(null) }, timeoutMs)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                lm.getCurrentLocation(provider, cancel, activity.mainExecutor) { finish(it) }
            } else {
                val l = LocationListener { finish(it) }
                listener = l
                @Suppress("DEPRECATION")
                lm.requestLocationUpdates(provider, 0L, 0f, l, Looper.getMainLooper())
            }
        } catch (_: SecurityException) {
            finish(null)
        } catch (_: Exception) {
            finish(null)
        }
    }

    // ── Address search (D20) ────────────────────────────────────────────────

    private fun search(query: String, result: MethodChannel.Result) {
        if (!Geocoder.isPresent()) {
            result.error("unavailable", "no geocoder", null)
            return
        }
        val geocoder = Geocoder(activity, Locale("vi", "VN"))
        // Vietnam box (overview D20).
        val box = doubleArrayOf(8.18, 102.14, 23.39, 109.46)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                geocoder.getFromLocationName(query, 5, box[0], box[1], box[2], box[3],
                    object : Geocoder.GeocodeListener {
                        override fun onGeocode(addresses: MutableList<Address>) {
                            main.post { result.success(addresses.map(::toMap)) }
                        }

                        override fun onError(errorMessage: String?) {
                            main.post { result.error("offline", errorMessage, null) }
                        }
                    })
            } catch (e: IllegalArgumentException) {
                result.error("failed", e.message, null)
            }
            return
        }
        Thread {
            try {
                @Suppress("DEPRECATION")
                val found = geocoder.getFromLocationName(query, 5, box[0], box[1], box[2], box[3]) ?: emptyList()
                val maps = found.map(::toMap)
                main.post { result.success(maps) }
            } catch (e: IOException) {
                main.post { result.error("offline", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("failed", e.message, null) }
            }
        }.start()
    }

    private fun toMap(a: Address): Map<String, Any?> {
        val line = (a.getAddressLine(0) ?: "")
            .replace(Regex(",\\s*(Việt Nam|Vietnam)\\s*$"), "")
            .trim()
        val street = listOfNotNull(a.subThoroughfare, a.thoroughfare)
            .filter { it.isNotBlank() }
            .joinToString(" ")
        val title = street.ifBlank { a.featureName?.takeIf { it.isNotBlank() } ?: line.substringBefore(",") }.trim()
        val subtitle = if (line.startsWith(title)) {
            line.substring(title.length).trimStart(',', ' ')
        } else {
            line
        }
        return mapOf(
            "title" to title,
            "subtitle" to subtitle,
            "lat" to a.latitude,
            "lng" to a.longitude,
            "hasNumber" to !a.subThoroughfare.isNullOrBlank(),
            "address" to listOfNotNull(line, a.adminArea).joinToString(", "),
        )
    }
}
