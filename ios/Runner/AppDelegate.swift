import AuthenticationServices
import CoreMotion
import FirebaseCore
import Flutter
import HealthKit
import UIKit
import UserNotifications
import WidgetKit
// ── arrival (đợt 2) ──
import CoreLocation
import MapKit
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    // ── arrival (đợt 2) ── geofence events run in a headless engine that needs
    // the plugins too (spike §6.4). Must come before the registrant below,
    // or native_geofence stops the app with fatalError at launch.
    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
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
    // ── arrival (đợt 2) ── location permission, one fix, address search.
    if let registrar = self.registrar(forPlugin: "ArrivalChannel") {
      ArrivalChannel.register(messenger: registrar.messenger())
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
      let mapped = (activities ?? []).map {
        MotionActivity(
          start: $0.startDate, stationary: $0.stationary, lowConfidence: $0.confidence == .low,
          unknown: $0.unknown, moving: $0.walking || $0.running || $0.cycling || $0.automotive)
      }
      let flat = MotionSpanBuilder.spans(activities: mapped, from: start, to: end, now: now)
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
  /// The "hôm nay" line (widget-today D6) — WidgetStatus.storeKey.
  static let statusKey = "widget_status"
  /// Widget tap → [family, target, focus, kind] (D7). 1.9.x stored a String
  /// under the old key; it is ignored after updating.
  static let launchKey = "widget_launch"

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
        // Signed out / left the couple: today's line must not outlive it (D6).
        if snapshot["state"] == "empty" { groupDefaults?.removeObject(forKey: statusKey) }
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
        result(nil)
      case "updateStatus":
        guard var status = call.arguments as? [String: String] else {
          result(FlutterError(code: "bad_args", message: "expected Map<String,String>", details: nil))
          return
        }
        // A push handled in the background only knows itself: keep a newer
        // line of the same day (pushes can arrive out of order, D3).
        let onlyIfNewer = status.removeValue(forKey: "onlyIfNewer") == "1"
        // partner_left (WT-R2-1): clear only a line older than the leave,
        // and remember the leave as `clearedAt` so a late push from before it
        // can't bring the old partner's line back.
        let clearIfOlder = status.removeValue(forKey: "clearIfOlder") == "1"
        let stored = groupDefaults?.dictionary(forKey: statusKey) as? [String: String] ?? [:]
        let storedAt = Int64(stored["statusAt"] ?? "") ?? 0
        let incomingAt = Int64(status["statusAt"] ?? "") ?? 0
        let clearedAt = Int64(stored["clearedAt"] ?? "") ?? 0
        if clearIfOlder {
          let mark = max(clearedAt, incomingAt)
          var next = storedAt < incomingAt ? status : stored
          next["clearedAt"] = String(mark)
          groupDefaults?.set(next, forKey: statusKey)
          if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
          result(nil)
          return
        }
        if onlyIfNewer,
           incomingAt < clearedAt
            || (stored["todayDate"] == status["todayDate"] && storedAt > incomingAt) {
          result(nil)
          return
        }
        if clearedAt > 0 { status["clearedAt"] = String(clearedAt) }
        groupDefaults?.set(status, forKey: statusKey)
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
        let launch = UserDefaults.standard.dictionary(forKey: launchKey) as? [String: String]
        UserDefaults.standard.removeObject(forKey: launchKey)
        result(launch)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Called from SceneDelegate for every URL the app is opened with.
  static func recordLaunch(url: URL) {
    guard url.scheme == "dearembeiu", url.host == "widget" else { return }
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func value(_ name: String) -> String { items.first(where: { $0.name == name })?.value ?? "" }
    // Dart whitelists every value (HomeWidgetBridge.parseLaunch).
    UserDefaults.standard.set([
      "family": value("family"), "target": value("target"),
      "focus": value("focus"), "kind": value("kind"),
    ], forKey: launchKey)
  }
}

// ── arrival (đợt 2) ──
/// Feature arrival: location permission (D8), one fix for "Dùng vị trí hiện
/// tại" and address search (D20: ONE `MKLocalSearch` per debounced query —
/// map items come with coordinates, so no per-suggestion lookups that Apple
/// throttles; never CLGeocoder — spike §6.8).
/// Launch engine only: geofence events run in native_geofence's headless
/// engine and never call this. Coordinates go back to Dart and stay on the
/// phone (D2); the typed text goes to Apple's map service (D22).
final class ArrivalChannel: NSObject, CLLocationManagerDelegate {
  private static var shared: ArrivalChannel?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "dear_embeiu/arrival", binaryMessenger: messenger)
    let me = ArrivalChannel()
    shared = me
    channel.setMethodCallHandler { call, result in me.handle(call, result) }
  }

  private let manager = CLLocationManager()
  private var permissionWaiters: [FlutterResult] = []
  private var askedStatus: CLAuthorizationStatus = .notDetermined
  private var askToken = 0
  private var resignedSinceAsk = false

  private var fixWaiters: [FlutterResult] = []
  private var fixToken = 0

  private var searchToken = 0
  private var searchResult: FlutterResult?
  private var activeSearch: MKLocalSearch?
  private var cache: [String: [[String: Any]]] = [:]
  // Vietnam box (overview D20): 8.18–23.39 N, 102.14–109.46 E.
  private let vietnam = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 15.785, longitude: 105.8),
    span: MKCoordinateSpan(latitudeDelta: 15.21, longitudeDelta: 7.32))

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(willResign),
      name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(didBecomeActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "permission": result(state())
    case "requestWhenInUse": request(always: false, result)
    case "requestAlways": request(always: true, result)
    case "openSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(nil)
    case "backgroundLabel": result(nil)
    case "currentFix": currentFix(timeoutMs: (args?["timeoutMs"] as? Int) ?? 15000, result)
    case "searchAvailable": result(true)
    case "search": search((args?["query"] as? String) ?? "", result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  // ── Permission ────────────────────────────────────────────────────────────

  private func state() -> [String: Any] {
    let level: String
    switch manager.authorizationStatus {
    case .notDetermined: level = "notDetermined"
    case .authorizedAlways: level = "always"
    case .authorizedWhenInUse: level = "whenInUse"
    default: level = "denied"
    }
    return ["level": level, "precise": manager.accuracyAuthorization == .fullAccuracy]
  }

  private func request(always: Bool, _ result: @escaping FlutterResult) {
    let status = manager.authorizationStatus
    // D8 order: "Luôn luôn" only after "Khi dùng ứng dụng" — from
    // notDetermined, requestAlways just reports the current state.
    let canAsk = always ? status == .authorizedWhenInUse : status == .notDetermined
    guard canAsk else {
      result(state())
      return
    }
    permissionWaiters.append(result)
    askedStatus = status
    resignedSinceAsk = false
    askToken += 1
    let token = askToken
    if always {
      manager.requestAlwaysAuthorization()
      // iOS asks for "Luôn luôn" once per install; after that nothing shows and
      // no callback comes. No sheet within 1 s = nothing to wait for.
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
        guard let self, self.askToken == token, !self.resignedSinceAsk else { return }
        self.finishPermission()
      }
    } else {
      manager.requestWhenInUseAuthorization()
    }
  }

  private func finishPermission() {
    guard !permissionWaiters.isEmpty else { return }
    askToken += 1
    let s = state()
    permissionWaiters.forEach { $0(s) }
    permissionWaiters.removeAll()
  }

  @objc private func willResign() { resignedSinceAsk = true }

  /// The system sheet closed without changing anything ("Giữ khi dùng ứng dụng").
  @objc private func didBecomeActive() {
    guard !permissionWaiters.isEmpty, resignedSinceAsk else { return }
    let token = askToken
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self, self.askToken == token else { return }
      self.finishPermission()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    // Also fires once when the manager is created: only a change counts.
    if !permissionWaiters.isEmpty, manager.authorizationStatus != askedStatus {
      finishPermission()
    }
  }

  // ── One fix ───────────────────────────────────────────────────────────────

  private func currentFix(timeoutMs: Int, _ result: @escaping FlutterResult) {
    let status = manager.authorizationStatus
    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
      result(nil)
      return
    }
    fixWaiters.append(result)
    guard fixWaiters.count == 1 else { return }
    fixToken += 1
    let token = fixToken
    manager.requestLocation()
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) { [weak self] in
      guard let self, self.fixToken == token else { return }
      self.manager.stopUpdatingLocation()
      self.finishFix(nil)
    }
  }

  private func finishFix(_ location: CLLocation?) {
    guard !fixWaiters.isEmpty else { return }
    fixToken += 1
    let payload: Any? = location.map {
      ["lat": $0.coordinate.latitude, "lng": $0.coordinate.longitude,
       "accuracy": max(0, $0.horizontalAccuracy)]
    }
    fixWaiters.forEach { $0(payload) }
    fixWaiters.removeAll()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    finishFix(locations.last)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishFix(nil)
  }

  // ── Address search ────────────────────────────────────────────────────────

  /// Dart sends the shortened text. Waits 500 ms for typing to settle; a newer
  /// query answers the older one with [] and cancels its search. Results are
  /// cached per text. `loadingThrottled` → "unavailable" (the UI then offers
  /// "Dùng vị trí hiện tại").
  private func search(_ query: String, _ result: @escaping FlutterResult) {
    searchToken += 1
    let token = searchToken
    searchResult?([])
    searchResult = result
    activeSearch?.cancel()
    activeSearch = nil
    if let hit = cache[query] {
      searchResult = nil
      result(hit)
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self, self.searchToken == token else { return }
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = query
      request.region = self.vietnam
      request.resultTypes = [.address, .pointOfInterest]
      let search = MKLocalSearch(request: request)
      self.activeSearch = search
      search.start { [weak self] response, error in
        guard let self, self.searchToken == token, let r = self.searchResult else { return }
        self.searchResult = nil
        self.activeSearch = nil
        if let error, (response?.mapItems ?? []).isEmpty {
          let ns = error as NSError
          if ns.domain == MKErrorDomain && ns.code == Int(MKError.placemarkNotFound.rawValue) {
            r([])
          } else if ns.domain == MKErrorDomain && ns.code == Int(MKError.loadingThrottled.rawValue) {
            r(FlutterError(code: "unavailable", message: "throttled", details: nil))
          } else {
            r(FlutterError(
              code: Self.isOffline(error) ? "offline" : "failed",
              message: ns.localizedDescription, details: nil))
          }
          return
        }
        let items = (response?.mapItems ?? []).prefix(5).map {
          self.map($0, title: $0.name ?? "", subtitle: nil)
        }
        if self.cache.count > 100 { self.cache.removeAll() }
        self.cache[query] = items
        r(items)
      }
    }
  }

  private func map(_ item: MKMapItem, title: String, subtitle: String?) -> [String: Any] {
    let p = item.placemark
    var full = p.title ?? ""
    for suffix in [", Việt Nam", ", Vietnam"] where full.hasSuffix(suffix) {
      full = String(full.dropLast(suffix.count))
    }
    let title = title.isEmpty ? (full.components(separatedBy: ",").first ?? "") : title
    var sub = subtitle ?? full
    if subtitle == nil, sub.hasPrefix(title) {
      sub = String(sub.dropFirst(title.count)).trimmingCharacters(in: CharacterSet(charactersIn: ", "))
    }
    return [
      "title": title,
      "subtitle": sub,
      "lat": p.coordinate.latitude,
      "lng": p.coordinate.longitude,
      "hasNumber": !(p.subThoroughfare ?? "").isEmpty,
      "address": [full, p.administrativeArea ?? ""].joined(separator: ", "),
    ]
  }

  private static func isOffline(_ error: Error) -> Bool {
    let ns = error as NSError
    return ns.domain == NSURLErrorDomain
      || (ns.domain == MKErrorDomain && ns.code == Int(MKError.serverFailure.rawValue))
  }
}
