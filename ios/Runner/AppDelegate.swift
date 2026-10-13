import AuthenticationServices
import CoreMotion
import FirebaseCore
import Flutter
import HealthKit
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    GeneratedPluginRegistrant.register(with: self)

    // App channels go through a plugin registrar, exactly like the generated
    // plugins above. With the UIScene lifecycle the window (and its root
    // FlutterViewController) doesn't exist yet at this point, so the registrar
    // hands out the launch engine's messenger instead.
    if let registrar = self.registrar(forPlugin: "AppChannels") {
      registerBadgeChannel(messenger: registrar.messenger(), application: application)
      SleepHealthChannel.register(messenger: registrar.messenger())
      InviteClipboardChannel.register(messenger: registrar.messenger())
      AppleIdStateChannel.register(messenger: registrar.messenger())
      HomeWidgetChannel.register(messenger: registrar.messenger())
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // App-icon badge channel (feature notifications, D-notif-2): Dart sets the
  // badge to the real unread count and clears it (0) when everything is read,
  // so the icon badge tracks the in-app bell instead of being stuck.
  private func registerBadgeChannel(
    messenger: FlutterBinaryMessenger,
    application: UIApplication
  ) {
    let badgeChannel = FlutterMethodChannel(name: "app/badge", binaryMessenger: messenger)
    badgeChannel.setMethodCallHandler { (call, result) in
      guard call.method == "setBadge",
            let args = call.arguments as? [String: Any],
            let count = args["count"] as? Int else {
        result(FlutterMethodNotImplemented)
        return
      }
      let safeCount = max(0, count)
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(safeCount)
      } else {
        application.applicationIconBadgeNumber = safeCount
      }
      result(nil)
    }
  }
}

/// Feature pairing-funnel (PF9): tells Dart whether the clipboard holds a web
/// link WITHOUT reading it. Reading is what shows iOS's "Allow Paste" alert, so
/// Setup reads only when there is a link, once per `changeCount`.
final class InviteClipboardChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "dear_embeiu/clipboard", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "probe" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let board = UIPasteboard.general
      let changeCount = board.changeCount
      board.detectPatterns(for: [\.probableWebURL]) { detection in
        var hasUrl = false
        if case .success(let found) = detection {
          hasUrl = found.contains(\UIPasteboard.DetectedValues.probableWebURL)
        }
        DispatchQueue.main.async {
          result(["hasUrl": hasUrl, "changeCount": changeCount])
        }
      }
    }
  }
}

/// Audit 2026-10-12 BUG-25: is the account's Apple user id authorized for
/// the Apple ID signed in on this iPhone? Deleting an account that also has
/// a password opens the Apple sheet only then: on another Apple ID the sheet
/// would sign that one in. Shows no UI.
final class AppleIdStateChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "dear_embeiu/apple_id", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "credentialState" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let userId = (call.arguments as? [String: Any])?["userId"] as? String,
            !userId.isEmpty else {
        result(FlutterError(code: "bad-args", message: "userId missing", details: nil))
        return
      }
      ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, error in
        let answer: String
        switch state {
        case .authorized: answer = "authorized"
        case .revoked: answer = "revoked"
        case .notFound: answer = "notFound"
        case .transferred: answer = "transferred"
        @unknown default: answer = "unknown"
        }
        DispatchQueue.main.async {
          if let error = error {
            result(FlutterError(
              code: "credential-state", message: error.localizedDescription, details: nil))
          } else {
            result(answer)
          }
        }
      }
    }
  }
}

/// Feature sleep (2026-10-10): reads — never writes — the sleep that iPhone /
/// Apple Watch saved in Health (`sleepAnalysis`). iOS gives apps no screen
/// lock history, so Health is the only automatic source. Same channel name as
/// the Android side (`MainActivity.kt`).
final class SleepHealthChannel {
  private static let store = HKHealthStore()

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "dear_embeiu/sleep", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isSupported":
        result(HKHealthStore.isHealthDataAvailable())
      case "hasPermission":
        // Read authorization is private on iOS: a denial looks like no data.
        result(HKHealthStore.isHealthDataAvailable())
      case "requestPermission":
        guard HKHealthStore.isHealthDataAvailable(),
              let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
          result(false)
          return
        }
        store.requestAuthorization(toShare: nil, read: [type]) { done, _ in
          DispatchQueue.main.async { result(done) }
        }
      case "openSettings":
        if let url = URL(string: "x-apple-health://") {
          UIApplication.shared.open(url)
        }
        result(nil)
      case "sleepSamples":
        let args = call.arguments as? [String: Any]
        let from = (args?["from"] as? NSNumber)?.doubleValue ?? 0
        let to = (args?["to"] as? NSNumber)?.doubleValue ?? Date().timeIntervalSince1970 * 1000
        readSamples(from: from, to: to, result: result)
      case "motionSupported":
        result(CMMotionActivityManager.isActivityAvailable())
      case "motionPermission":
        result(motionPermission())
      case "requestMotionPermission":
        requestMotion(result: result)
      case "startMotionTracking", "stopMotionTracking":
        // Core Motion records on its own; nothing to register or clear.
        result(true)
      case "motionCoverageStart":
        // iOS keeps 7 days of motion history.
        result(Int64((Date().timeIntervalSince1970 - 7 * 86400) * 1000))
      case "motionStillSpans":
        let args = call.arguments as? [String: Any]
        let from = (args?["from"] as? NSNumber)?.doubleValue ?? 0
        let to = (args?["to"] as? NSNumber)?.doubleValue ?? Date().timeIntervalSince1970 * 1000
        motionStillSpans(from: from, to: to, result: result)
      case "excludeFromBackup":
        // Sleep data stays on this phone (privacy policy): its folder is
        // left out of iCloud / computer backups. Set on the folder, so every
        // file Hive writes inside (compaction swaps files) is covered too.
        guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
          result(false)
          return
        }
        var url = URL(fileURLWithPath: path, isDirectory: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
          try url.setResourceValues(values)
          result(true)
        } catch {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Answers a flat Int64 array [startMs, endMs, value, …].
  private static func readSamples(from: Double, to: Double, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(),
          let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
      result(FlutterStandardTypedData(int64: Data()))
      return
    }
    let predicate = HKQuery.predicateForSamples(
      withStart: Date(timeIntervalSince1970: from / 1000),
      end: Date(timeIntervalSince1970: to / 1000),
      options: []
    )
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
    let query = HKSampleQuery(
      sampleType: type,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [sort]
    ) { _, samples, _ in
      var flat: [Int64] = []
      for case let sample as HKCategorySample in samples ?? [] {
        flat.append(Int64(sample.startDate.timeIntervalSince1970 * 1000))
        flat.append(Int64(sample.endDate.timeIntervalSince1970 * 1000))
        flat.append(Int64(sample.value))
      }
      let data = flat.withUnsafeBufferPointer { Data(buffer: $0) }
      DispatchQueue.main.async { result(FlutterStandardTypedData(int64: data)) }
    }
    store.execute(query)
  }

  // MARK: Motion fallback (feature sleep-motion): phone-lying-still spans.
  private static let motion = CMMotionActivityManager()
  private static let motionQueue = OperationQueue()

  private static func motionPermission() -> String {
    switch CMMotionActivityManager.authorizationStatus() {
    case .authorized: return "granted"
    case .notDetermined: return "notDetermined"
    default: return "denied"
    }
  }

  /// Triggers the permission prompt with one short query, then re-reads status.
  private static func requestMotion(result: @escaping FlutterResult) {
    guard CMMotionActivityManager.isActivityAvailable() else { result(false); return }
    if motionPermission() == "granted" { result(true); return }
    let now = Date()
    motion.queryActivityStarting(from: now.addingTimeInterval(-60), to: now, to: motionQueue) { _, _ in
      DispatchQueue.main.async { result(motionPermission() == "granted") }
    }
  }

  /// Flat Int64 [startMs, endMs, …] of stationary spans inside [from, to].
  private static func motionStillSpans(from: Double, to: Double, result: @escaping FlutterResult) {
    let empty = FlutterStandardTypedData(int64: Data())
    guard CMMotionActivityManager.isActivityAvailable(), motionPermission() == "granted" else {
      result(empty)
      return
    }
    let now = Date()
    // iOS keeps only 7 days of history.
    let start = max(Date(timeIntervalSince1970: from / 1000), now.addingTimeInterval(-7 * 86400))
    let end = min(Date(timeIntervalSince1970: to / 1000), now)
    guard start < end else { result(empty); return }
    motion.queryActivityStarting(from: start, to: end, to: motionQueue) { activities, _ in
      var flat: [Int64] = []
      var open: Date?
      func close(_ at: Date) {
        if let s = open, at > s {
          flat.append(Int64(s.timeIntervalSince1970 * 1000))
          flat.append(Int64(at.timeIntervalSince1970 * 1000))
        }
        open = nil
      }
      for a in activities ?? [] {
        let moving = a.walking || a.running || a.cycling || a.automotive
        if moving {
          close(a.startDate)
        } else if a.stationary && a.confidence != .low && !a.unknown {
          if open == nil { open = max(a.startDate, start) }
        } else if !(a.stationary || a.unknown) {
          close(a.startDate)
        }
        // Low-confidence stationary / unknown: neutral, the span stays as is.
      }
      close(end)
      let data = flat.withUnsafeBufferPointer { Data(buffer: $0) }
      DispatchQueue.main.async { result(FlutterStandardTypedData(int64: data)) }
    }
  }
}

/// Feature home-widget (D3/D8): Dart pushes the pre-translated snapshot, we
/// store it in the App Group and ask WidgetKit to redraw. A widget tap opens
/// `dearembeiu://widget?family=…`; the family is parked in UserDefaults until
/// Dart asks (`consumeLaunch`) so Analytics gets one `widget_tap` per tap.
final class HomeWidgetChannel {
  static let snapshotKey = "widget_snapshot"
  static let launchKey = "widget_launch_family"

  private static var groupDefaults: UserDefaults? {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else { return nil }
    return UserDefaults(suiteName: group)
  }

  /// Same file the extension reads (WidgetSnapshot.photoURL).
  private static var photoURL: URL? {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else { return nil }
    return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
      .appendingPathComponent("widget_photo.png")
  }

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "dear_embeiu/widget", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "update":
        guard let snapshot = call.arguments as? [String: String] else {
          result(FlutterError(code: "bad_args", message: "expected Map<String,String>", details: nil))
          return
        }
        groupDefaults?.set(snapshot, forKey: snapshotKey)
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
        result(nil)
      case "setPhoto":
        if let url = photoURL {
          if let png = (call.arguments as? FlutterStandardTypedData)?.data {
            try? png.write(to: url, options: .atomic)
          } else {
            try? FileManager.default.removeItem(at: url)
          }
        }
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
        result(nil)
      case "consumeLaunch":
        let family = UserDefaults.standard.string(forKey: launchKey)
        UserDefaults.standard.removeObject(forKey: launchKey)
        result(family)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Called from SceneDelegate for every URL the app is opened with.
  static func recordLaunch(url: URL) {
    guard url.scheme == "dearembeiu", url.host == "widget" else { return }
    let family = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first(where: { $0.name == "family" })?.value ?? "unknown"
    UserDefaults.standard.set(family, forKey: launchKey)
  }
}
