import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProximityWakeLockService {
  static final ProximityWakeLockService _instance = ProximityWakeLockService._internal();
  factory ProximityWakeLockService() => _instance;
  ProximityWakeLockService._internal();

  static const EventChannel _proximityChannel =
      EventChannel('com.example.flutter_noor_alatra/proximity');
  static const MethodChannel _wakelockChannel =
      MethodChannel('com.example.flutter_noor_alatra/wakelock');

  Stream<int>? _proximityStream;

  /// Returns a stream of proximity events: 1 if near, 0 if far
  Stream<int> get proximityStream {
    _proximityStream ??= _proximityChannel
        .receiveBroadcastStream()
        .map<int>((dynamic event) => (event as num).toInt())
        .handleError((error) {
      debugPrint('Proximity sensor stream error: $error');
      return 0;
    });
    return _proximityStream!;
  }

  /// Keep screen always on during prayer
  Future<void> enableKeepScreenOn() async {
    try {
      await _wakelockChannel.invokeMethod('enableKeepScreenOn');
    } catch (e) {
      debugPrint('Error enabling keep screen on: $e');
    }
  }

  /// Release screen lock
  Future<void> disableKeepScreenOn() async {
    try {
      await _wakelockChannel.invokeMethod('disableKeepScreenOn');
    } catch (e) {
      debugPrint('Error disabling keep screen on: $e');
    }
  }

  /// Show custom card prayer notification matching Android system status bar cards
  Future<bool> updateCustomPrayerNotification({
    required String fajr,
    required String sunrise,
    required String dhuhr,
    required String maghrib,
  }) async {
    try {
      final res = await _wakelockChannel.invokeMethod('updateCustomPrayerNotification', {
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'maghrib': maghrib,
      });
      return res == true;
    } catch (e) {
      debugPrint('Error showing custom card prayer notification: $e');
      return false;
    }
  }

  /// Cancel custom card prayer notification
  Future<void> cancelCustomPrayerNotification() async {
    try {
      await _wakelockChannel.invokeMethod('cancelCustomPrayerNotification');
    } catch (e) {
      debugPrint('Error canceling custom card prayer notification: $e');
    }
  }

  /// Launch native Arabic voice recognition dialog and return recognized speech string
  Future<String?> startVoiceRecognition({String prompt = 'تحدث الآن للبحث...'}) async {
    try {
      final res = await _wakelockChannel.invokeMethod<String>('startVoiceRecognition', {
        'prompt': prompt,
      });
      return res?.trim();
    } catch (e) {
      debugPrint('Error starting voice recognition: $e');
      return null;
    }
  }

  /// Check if the app is already whitelisted / exempt from battery optimization
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return res ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request exemption from battery optimization directly to prevent delayed prayer alarms
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return res ?? false;
    } catch (e) {
      debugPrint('Error requesting battery optimization: $e');
      return false;
    }
  }

  /// Open system battery optimization settings
  Future<void> openBatterySettings() async {
    try {
      await _wakelockChannel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint('Error opening battery settings: $e');
    }
  }

  /// Check if exact alarms can be scheduled on Android 12+
  Future<bool> canScheduleExactAlarms() async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('canScheduleExactAlarms');
      return res ?? true;
    } catch (e) {
      debugPrint('Error checking exact alarms: $e');
      return true;
    }
  }

  /// Open exact alarm permission settings
  Future<void> openExactAlarmSettings() async {
    try {
      await _wakelockChannel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      debugPrint('Error opening exact alarm settings: $e');
    }
  }

  /// Play the Holy Adhan using native Android alarm stream (bypasses silent mode & powers through lock screen)
  Future<bool> playNativeAdhan({
    required String prayerName,
    String? muezzinPath,
    String? muezzinName,
  }) async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('playNativeAdhan', {
        'prayerName': prayerName,
        'muezzinPath': muezzinPath,
        'muezzinName': muezzinName ?? 'الحاج عامر الكاظمي',
      });
      return res == true;
    } catch (e) {
      debugPrint('Error in playNativeAdhan: $e');
      return false;
    }
  }

  /// Stop native Holy Adhan playback immediately
  Future<void> stopNativeAdhan() async {
    try {
      await _wakelockChannel.invokeMethod('stopNativeAdhan');
    } catch (e) {
      debugPrint('Error in stopNativeAdhan: $e');
    }
  }

  /// Toggle native Holy Adhan volume between normal (100%) and low (~20%)
  Future<bool> toggleNativeAdhanVolume() async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('toggleAdhanVolume');
      return res == true;
    } catch (e) {
      debugPrint('Error in toggleNativeAdhanVolume: $e');
      return false;
    }
  }

  /// Set native Holy Adhan volume to low (~20%) or restore normal (100%)
  Future<bool> setNativeAdhanVolume({required bool isLow}) async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('lowerAdhanVolume', {'isLow': isLow});
      return res == true;
    } catch (e) {
      debugPrint('Error in setNativeAdhanVolume: $e');
      return false;
    }
  }

  /// Check if native Holy Adhan volume is currently lowered
  Future<bool> isAdhanVolumeLowered() async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('isAdhanVolumeLowered');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Check if native Holy Adhan is currently playing
  Future<bool> isAdhanPlaying() async {
    try {
      final res = await _wakelockChannel.invokeMethod<bool>('isAdhanPlaying');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Get current Adhan status map (isPlaying, prayerName)
  Future<Map<String, dynamic>> getAdhanStatus() async {
    try {
      final res = await _wakelockChannel.invokeMapMethod<String, dynamic>('getAdhanStatus');
      return res ?? {'isPlaying': false, 'prayerName': 'الصلاة'};
    } catch (_) {
      return {'isPlaying': false, 'prayerName': 'الصلاة'};
    }
  }

  /// Schedule exact native alarm clock using AlarmManager.setAlarmClock for a prayer
  Future<void> scheduleNativePrayerAlarm({
    required String prayerName,
    required DateTime triggerTime,
    required int alarmId,
    String? muezzinPath,
    String? muezzinName,
  }) async {
    try {
      await _wakelockChannel.invokeMethod('scheduleNativePrayerAlarm', {
        'prayerName': prayerName,
        'triggerTimeMs': triggerTime.millisecondsSinceEpoch,
        'alarmId': alarmId,
        'muezzinPath': muezzinPath,
        'muezzinName': muezzinName ?? 'الحاج عامر الكاظمي',
      });
    } catch (e) {
      debugPrint('Error scheduling native prayer alarm: $e');
    }
  }

  /// Cancel scheduled native alarm clock
  Future<void> cancelNativePrayerAlarm(int alarmId) async {
    try {
      await _wakelockChannel.invokeMethod('cancelNativePrayerAlarm', {
        'alarmId': alarmId,
      });
    } catch (e) {
      debugPrint('Error canceling native prayer alarm: $e');
    }
  }
}

