import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // Feature home-widget: note which widget opened the app (cold start carries
  // the URL in connectionOptions, warm start in openURLContexts). Flutter's own
  // deep linking stays off (audit D8) — the app only needs to come to the front.
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                      options connectionOptions: UIScene.ConnectionOptions) {
    connectionOptions.urlContexts.forEach { HomeWidgetChannel.recordLaunch(url: $0.url) }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    URLContexts.forEach { HomeWidgetChannel.recordLaunch(url: $0.url) }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
