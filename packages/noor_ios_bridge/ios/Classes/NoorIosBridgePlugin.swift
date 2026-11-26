import Flutter
import UIKit
import Photos
import Speech
import AVFoundation

public class NoorIosBridgePlugin: NSObject, FlutterPlugin {
    private static var proximityHandler: ProximityStreamHandler?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()

        // 1. MethodChannel for wakelock, wallpaper, and system bridge
        let wakelockChannel = FlutterMethodChannel(
            name: "com.example.flutter_noor_alatra/wakelock",
            binaryMessenger: messenger
        )
        let instance = NoorIosBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: wakelockChannel)

        // 2. EventChannel for proximity sensor
        let proximityChannel = FlutterEventChannel(
            name: "com.example.flutter_noor_alatra/proximity",
            binaryMessenger: messenger
        )
        let handler = ProximityStreamHandler()
        proximityHandler = handler
        proximityChannel.setStreamHandler(handler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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

        case "setDeviceWallpaper":
            guard let args = call.arguments as? [String: Any],
                  let filePath = args["filePath"] as? String,
                  let image = UIImage(contentsOfFile: filePath) else {
                result(false)
                return
            }

            let saveBlock = {
                DispatchQueue.main.async {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    result(true)
                }
            }

            if #available(iOS 14, *) {
                let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
                switch status {
                case .authorized, .limited:
                    saveBlock()
                case .notDetermined:
                    PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                        if newStatus == .authorized || newStatus == .limited {
                            saveBlock()
                        } else {
                            result(FlutterError(code: "PHOTOS_DENIED", message: "تم رفض إذن الوصول إلى ألبوم الصور", details: nil))
                        }
                    }
                case .denied, .restricted:
                    result(FlutterError(code: "PHOTOS_DENIED", message: "إذن ألبوم الصور مرفوض، يرجى تفعيله من إعدادات iPhone", details: nil))
                @unknown default:
                    result(false)
                }
            } else {
                let status = PHPhotoLibrary.authorizationStatus()
                if status == .authorized {
                    saveBlock()
                } else if status == .notDetermined {
                    PHPhotoLibrary.requestAuthorization { newStatus in
                        if newStatus == .authorized {
                            saveBlock()
                        } else {
                            result(FlutterError(code: "PHOTOS_DENIED", message: "تم رفض إذن الوصول إلى ألبوم الصور", details: nil))
                        }
                    }
                } else {
                    result(FlutterError(code: "PHOTOS_DENIED", message: "إذن ألبوم الصور مرفوض، يرجى تفعيله من إعدادات iPhone", details: nil))
                }
            }

        case "startVoiceRecognition":
            // Check speech recognition permission on iOS
            SFSpeechRecognizer.requestAuthorization { authStatus in
                switch authStatus {
                case .authorized:
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        if granted {
                            result("") // Permission granted, ready
                        } else {
                            result(FlutterError(code: "MIC_DENIED", message: "إذن الميكروفون مرفوض في إعدادات iOS", details: nil))
                        }
                    }
                case .denied, .restricted:
                    result(FlutterError(code: "SPEECH_DENIED", message: "إذن التعرف على الصوت مرفوض في إعدادات iOS", details: nil))
                case .notDetermined:
                    result("")
                @unknown default:
                    result("")
                }
            }

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

        case "isAdhanPlaying":
            result(false)

        case "isAdhanVolumeLowered":
            result(false)

        case "getAdhanStatus":
            result(["isPlaying": false, "prayerName": "الصلاة"])

        case "stopNativeAdhan", "toggleAdhanVolume", "lowerAdhanVolume", "scheduleNativePrayerAlarm", "cancelNativePrayerAlarm":
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

class ProximityStreamHandler: NSObject, FlutterStreamHandler {
    private var observer: NSObjectProtocol?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        DispatchQueue.main.async {
            UIDevice.current.isProximityMonitoringEnabled = true
        }

        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            let isNear = UIDevice.current.proximityState
            events(isNear ? 1 : 0)
        }

        // Send initial state immediately
        let initial = UIDevice.current.proximityState ? 1 : 0
        events(initial)

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        DispatchQueue.main.async {
            UIDevice.current.isProximityMonitoringEnabled = false
        }
        return nil
    }
}
