import FirebaseCore
import Flutter
import HealthKit
import UIKit
import UserNotifications

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
}
