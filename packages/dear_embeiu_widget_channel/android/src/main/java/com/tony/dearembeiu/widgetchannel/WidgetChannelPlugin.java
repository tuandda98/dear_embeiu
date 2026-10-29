package com.tony.dearembeiu.widgetchannel;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Android handler of {@code dear_embeiu/widget} (feature home-widget, moved here
 * by widget-today D13). A plugin rather than code in MainActivity because
 * firebase_messaging runs the background handler in its own FlutterEngine,
 * which only gets the plugins of GeneratedPluginRegistrant: there the channel
 * used to be missing and {@code updateStatus} threw MissingPluginException.
 *
 * <p>This module cannot see the app's classes, so it writes the same files the
 * app's {@code WidgetStore} reads (names below must match it) and asks the
 * app's {@code DayCounterWidget} to redraw with an explicit broadcast.
 */
public class WidgetChannelPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    // Keep in sync with android/app/.../widget/WidgetStore.kt + DayCounterWidget.kt.
    static final String SNAPSHOT_PREFS = "dear_embeiu_widget";
    static final String STATUS_PREFS = "dear_embeiu_widget_status";
    static final String LAUNCH_PREFS = "dear_embeiu_widget_launch";
    static final String PHOTO_FILE = "widget_photo.png";
    static final String WIDGET_CLASS = "com.tony.dearembeiu.widget.DayCounterWidget";
    static final String ACTION_REFRESH = "com.tony.dearembeiu.widget.REFRESH";
    /** Launch keys MainActivity records from the widget intent. */
    static final String[] LAUNCH_KEYS = {"family", "target", "focus", "kind"};

    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "dear_embeiu/widget");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "update": {
                Map<String, String> snapshot = strings(call.arguments);
                put(SNAPSHOT_PREFS, snapshot);
                // Signed out / left the couple: today's line must not outlive it (D6).
                if ("empty".equals(snapshot.get("state"))) put(STATUS_PREFS, new HashMap<>());
                refresh();
                result.success(null);
                break;
            }
            case "updateStatus": {
                Map<String, String> status = strings(call.arguments);
                // A push handled in the background only knows itself: keep a
                // newer line of the same day (pushes can arrive out of order, D3).
                boolean onlyIfNewer = "1".equals(status.remove("onlyIfNewer"));
                // partner_left (WT-R2-1): clear only a line older than the
                // leave, and remember the leave as `clearedAt` so a late push
                // from before it can't bring the old partner's line back.
                boolean clearIfOlder = "1".equals(status.remove("clearIfOlder"));
                // caro end (CARO-T4): replace only the line of this kind.
                String onlyIfKind = status.remove("onlyIfKind");
                SharedPreferences prefs = context.getSharedPreferences(STATUS_PREFS, Context.MODE_PRIVATE);
                if (onlyIfKind != null && !onlyIfKind.equals(prefs.getString("statusKind", ""))) {
                    result.success(null);
                    break;
                }
                long storedAt = parse(prefs.getString("statusAt", "0"));
                long incomingAt = parse(status.get("statusAt"));
                long clearedAt = parse(prefs.getString("clearedAt", "0"));
                if (clearIfOlder) {
                    Map<String, String> next = new HashMap<>();
                    if (storedAt < incomingAt) {
                        next.putAll(status);
                    } else {
                        for (Map.Entry<String, ?> e : prefs.getAll().entrySet()) {
                            if (e.getValue() instanceof String) next.put(e.getKey(), (String) e.getValue());
                        }
                    }
                    next.put("clearedAt", Long.toString(Math.max(clearedAt, incomingAt)));
                    put(STATUS_PREFS, next);
                    refresh();
                } else if (!onlyIfNewer || (incomingAt >= clearedAt && isNewer(status))) {
                    if (clearedAt > 0) status.put("clearedAt", Long.toString(clearedAt));
                    put(STATUS_PREFS, status);
                    refresh();
                }
                result.success(null);
                break;
            }
            case "setPhoto":
                savePhoto(call.arguments instanceof byte[] ? (byte[]) call.arguments : null);
                refresh();
                result.success(null);
                break;
            case "consumeLaunch":
                result.success(consumeLaunch());
                break;
            default:
                result.notImplemented();
        }
    }

    private boolean isNewer(Map<String, String> status) {
        SharedPreferences prefs = context.getSharedPreferences(STATUS_PREFS, Context.MODE_PRIVATE);
        String day = prefs.getString("todayDate", "");
        if (!day.equals(status.get("todayDate"))) return true;
        return parse(status.get("statusAt")) >= parse(prefs.getString("statusAt", "0"));
    }

    private static long parse(String s) {
        try {
            return s == null ? 0L : Long.parseLong(s);
        } catch (NumberFormatException e) {
            return 0L;
        }
    }

    private static Map<String, String> strings(Object args) {
        Map<String, String> out = new HashMap<>();
        if (args instanceof Map) {
            for (Map.Entry<?, ?> e : ((Map<?, ?>) args).entrySet()) {
                if (e.getKey() != null && e.getValue() != null) {
                    out.put(e.getKey().toString(), e.getValue().toString());
                }
            }
        }
        return out;
    }

    /** commit, not apply: the background isolate may be torn down right after. */
    private void put(String file, Map<String, String> values) {
        SharedPreferences.Editor editor =
                context.getSharedPreferences(file, Context.MODE_PRIVATE).edit().clear();
        for (Map.Entry<String, String> e : values.entrySet()) editor.putString(e.getKey(), e.getValue());
        editor.commit();
    }

    /** PNG already downscaled by Flutter (HomeWidgetBridge.photoMaxEdge); null removes it. */
    private void savePhoto(byte[] png) {
        File file = new File(context.getFilesDir(), PHOTO_FILE);
        if (png == null) {
            //noinspection ResultOfMethodCallIgnored
            file.delete();
            return;
        }
        File tmp = new File(file.getPath() + ".tmp");
        try (FileOutputStream out = new FileOutputStream(tmp)) {
            out.write(png);
        } catch (Exception e) {
            return;
        }
        //noinspection ResultOfMethodCallIgnored
        tmp.renameTo(file);
    }

    /** Which widget opened the app and where its line pointed, once; null = not from the widget. */
    private Map<String, String> consumeLaunch() {
        SharedPreferences prefs = context.getSharedPreferences(LAUNCH_PREFS, Context.MODE_PRIVATE);
        if (prefs.getString("family", null) == null) return null;
        Map<String, String> out = new HashMap<>();
        for (String key : LAUNCH_KEYS) out.put(key, prefs.getString(key, ""));
        prefs.edit().clear().apply();
        return out;
    }

    /** Explicit broadcast to the app's own provider; it redraws both sizes (DayCounterWidget.updateAll). */
    private void refresh() {
        Intent intent = new Intent(ACTION_REFRESH);
        intent.setComponent(new ComponentName(context.getPackageName(), WIDGET_CLASS));
        context.sendBroadcast(intent);
    }
}
