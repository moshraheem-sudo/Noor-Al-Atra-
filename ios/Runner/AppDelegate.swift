import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var proximityHandler: ProximityStreamHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      setupChannels(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupChannels(messenger: engineBridge.binaryMessenger)
  }

  private func setupChannels(messenger: FlutterBinaryMessenger) {
    let wakelockChannel = FlutterMethodChannel(
      name: "com.example.flutter_noor_alatra/wakelock",
      binaryMessenger: messenger
    )

    wakelockChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "enableKeepScreenOn":
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = true
        }
        result(true)

      case "disableKeepScreenOn":
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = false
        }
        result(true)

      case "isBatteryOptimizationIgnored",
           "requestIgnoreBatteryOptimizations",
           "openBatterySettings",
           "canScheduleExactAlarms",
           "openExactAlarmSettings",
           "updateCustomPrayerNotification",
           "cancelCustomPrayerNotification",
           "cancelQuranNotification":
        result(true)

      case "showCustomQuranNotification", "installApk":
        result(false)

      case "setDeviceWallpaper":
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(false)
          return
        }
        if let image = UIImage(contentsOfFile: filePath) {
          UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
          result(true)
        } else {
          result(false)
        }

      case "startVoiceRecognition":
        result("")

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let proximityChannel = FlutterEventChannel(
      name: "com.example.flutter_noor_alatra/proximity",
      binaryMessenger: messenger
    )
    let handler = ProximityStreamHandler()
    self.proximityHandler = handler
    proximityChannel.setStreamHandler(handler)
  }
}

class ProximityStreamHandler: NSObject, FlutterStreamHandler {
  private var observer: NSObjectProtocol?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    UIDevice.current.isProximityMonitoringEnabled = true
    observer = NotificationCenter.default.addObserver(
      forName: UIDevice.proximityStateDidChangeNotification,
      object: nil,
      queue: .main
    ) { _ in
      let isNear = UIDevice.current.proximityState
      events(isNear ? 1 : 0)
    }
    events(UIDevice.current.proximityState ? 1 : 0)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
      self.observer = nil
    }
    UIDevice.current.isProximityMonitoringEnabled = false
    return nil
  }
}
