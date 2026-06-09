import FirebaseCore
import Flutter
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

    // App-icon badge channel (feature notifications, D-notif-2): Dart sets the
    // badge to the real unread count and clears it (0) when everything is read,
    // so the icon badge tracks the in-app bell instead of being stuck.
    if let controller = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(
        name: "app/badge",
        binaryMessenger: controller.binaryMessenger
      )
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
