import Flutter
import UIKit
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      GMSServices.provideAPIKey("API_KEY")
      
      GeneratedPluginRegistrant.register(with: self)
      
      guard let pluginRegistrar = self.registrar(forPlugin: "plugin-name") else { return false }
      let factory = FlutterStreetViewFactory(messenger: pluginRegistrar.messenger())
      pluginRegistrar.register(
          factory,
          withId: "flutter-street-view")
      
      let eventChannel = FlutterEventChannel(name: "flutter_compass", binaryMessenger: pluginRegistrar.messenger());
      eventChannel.setStreamHandler(FlutterCompass())
      
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
