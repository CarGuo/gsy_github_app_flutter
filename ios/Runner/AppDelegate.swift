import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FLTWebviewFlutterPlugin.register(with: self.registrar(forPlugin: "FLTWebviewFlutterPlugin"))

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
