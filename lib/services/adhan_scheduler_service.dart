import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'app_notification_service.dart';
import 'muezzin_download_service.dart';
import 'settings_controller.dart';
import 'proximity_wakelock_service.dart';

import 'storage_service.dart';
import 'kafeel_api_service.dart';
import '../models/prayer_times.dart';
import '../models/city_location.dart';

enum AdhanAlertType {
  fullAdhan,
  takbeeratOnly,
  shortNotification,
  vibrationOnly,
  silent,
}

class AdhanSchedulerService {
  static final AdhanSchedulerService _instance = AdhanSchedulerService._internal();
  factory AdhanSchedulerService() => _instance;
  AdhanSchedulerService._internal();

  final AudioPlayer _adhanPlayer = AudioPlayer();
  Timer? _schedulerTimer;
  String? _currentAdhanPrayerName;

  /// Reactive Notifiers for In-App UI & Home Screen Banner
  final ValueNotifier<bool> isPlayingAdhanNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentAdhanPrayerNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isVolumeLoweredNotifier = ValueNotifier<bool>(false);

  PrayerTimesModel? _cachedPrayerTimes;
  String? _cachedDateStr;
  String? _cachedCityId;

  final Set<String> _firedAlerts = {};

  bool get isPlayingAdhan => isPlayingAdhanNotifier.value;
  bool get isVolumeLowered => isVolumeLoweredNotifier.value;
  String? get currentAdhanPrayerName => currentAdhanPrayerNotifier.value;

  void init() {
    _startSchedulerLoop();
    syncAdhanPlayingState();
    _checkAndTriggerPrayers();
    // Immediate force update of sticky prayer notification
    final savedCity = StorageService().getSavedCity() ?? CityLocation.defaultCity;
    KafeelApiService.getPrayerTimes(savedCity, targetDate: DateTime.now()).then((times) {
      if (times != null) {
        _cachedPrayerTimes = times;
        AppNotificationService().updateStickyPrayerTimesNotification(
          fajr: times.fajr,
          sunrise: times.sunrise,
          dhuhr: times.dhuhr,
          asr: times.asr,
          maghrib: times.maghrib,
          isha: times.isha,
        );
      }
    });
  }

  /// Syncs active playing state between native Android AdhanAudioService and Dart
  Future<bool> syncAdhanPlayingState() async {
    bool playing = false;
    String? prayerName;

    if (Platform.isAndroid) {
      try {
        final status = await ProximityWakeLockService().getAdhanStatus();
        playing = status['isPlaying'] == true;
        if (playing) {
          prayerName = status['prayerName'] as String?;
          final isLow = status['isVolumeLowered'] == true;
          if (isVolumeLoweredNotifier.value != isLow) {
            isVolumeLoweredNotifier.value = isLow;
          }
        } else {
          if (isVolumeLoweredNotifier.value) {
            isVolumeLoweredNotifier.value = false;
          }
        }
      } catch (_) {}
    }

    if (!playing && _adhanPlayer.state == PlayerState.playing) {
      playing = true;
      prayerName = _currentAdhanPrayerName;
    }

    if (isPlayingAdhanNotifier.value != playing || (playing && currentAdhanPrayerNotifier.value != prayerName)) {
      isPlayingAdhanNotifier.value = playing;
      if (playing) {
        final pName = prayerName ?? _currentAdhanPrayerName ?? 'الصلاة';
        _currentAdhanPrayerName = pName;
        currentAdhanPrayerNotifier.value = pName;
      } else {
        _currentAdhanPrayerName = null;
        currentAdhanPrayerNotifier.value = null;
        isVolumeLoweredNotifier.value = false;
      }
    }
    return playing;
  }

  /// Called whenever the user selects or updates their city/GPS location
  Future<void> onCityChanged(CityLocation newCity) async {
    _cachedCityId = newCity.id;
    _cachedPrayerTimes = null;
    _cachedDateStr = null;
    _firedAlerts.clear();
    await _checkAndTriggerPrayers();
  }

  void _startSchedulerLoop() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      syncAdhanPlayingState();
      _checkAndTriggerPrayers();
    });
  }

  Future<void> _checkAndTriggerPrayers() async {
    final now = DateTime.now();
    final todayKey = '${now.year}_${now.month}_${now.day}';
    final savedCity = StorageService().getSavedCity() ?? CityLocation.defaultCity;

    if (_cachedDateStr != todayKey || _cachedPrayerTimes == null || _cachedCityId != savedCity.id) {
      _cachedCityId = savedCity.id;
      _cachedPrayerTimes = await KafeelApiService.getPrayerTimes(savedCity, targetDate: now);
      _cachedDateStr = todayKey;

      if (_cachedPrayerTimes != null) {
        AppNotificationService().schedulePrayerAlarmsAndReminders(
          prayerTimes: _cachedPrayerTimes!,
          date: now,
        );
        final tomorrow = now.add(const Duration(days: 1));
        KafeelApiService.getPrayerTimes(savedCity, targetDate: tomorrow).then((tomTimes) {
          AppNotificationService().schedulePrayerAlarmsAndReminders(
            prayerTimes: tomTimes,
            date: tomorrow,
          );
        });
      }
    }

    final pTimes = _cachedPrayerTimes;
    if (pTimes == null) return;

    final settings = SettingsController();

    // Keep sticky notification active and updated every minute
    if (now.second == 0 || !_firedAlerts.contains('sticky_init_$todayKey')) {
      _firedAlerts.add('sticky_init_$todayKey');
      AppNotificationService().updateStickyPrayerTimesNotification(
        fajr: pTimes.fajr,
        sunrise: pTimes.sunrise,
        dhuhr: pTimes.dhuhr,
        asr: pTimes.asr,
        maghrib: pTimes.maghrib,
        isha: pTimes.isha,
      );
    }

    final prayerList = [
      {'key': 'fajr', 'name': 'الفجر', 'time': pTimes.fajr, 'enabled': settings.notifyFajr},
      {'key': 'sunrise', 'name': 'الشروق', 'time': pTimes.sunrise, 'enabled': settings.notifySunrise},
      {'key': 'dhuhr', 'name': 'الظهر', 'time': pTimes.dhuhr, 'enabled': settings.notifyDhuhr},
      {'key': 'asr', 'name': 'العصر', 'time': pTimes.asr, 'enabled': settings.notifyAsr},
      {'key': 'maghrib', 'name': 'المغرب', 'time': pTimes.maghrib, 'enabled': settings.notifyMaghrib},
      {'key': 'isha', 'name': 'العشاء', 'time': pTimes.isha, 'enabled': settings.notifyIsha},
    ];

    for (final p in prayerList) {
      if (!(p['enabled'] as bool)) continue;

      final parts = (p['time'] as String).split(':');
      if (parts.length < 2) continue;

      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final prayerDate = DateTime(now.year, now.month, now.day, h, m);
      final diffSec = prayerDate.difference(now).inSeconds;

      final pKey = p['key'] as String;
      final pName = p['name'] as String;

      // 1. 10 Minutes Reminder (between 9m 45s and 10m 15s)
      final alertKey10 = '${pKey}_10_$todayKey';
      if (diffSec >= 585 && diffSec <= 615 && !_firedAlerts.contains(alertKey10)) {
        _firedAlerts.add(alertKey10);
        AppNotificationService().showApproachingPrayerNotification(pName, 10);
      }

      // 2. 5 Minutes Reminder (between 4m 45s and 5m 15s)
      final alertKey5 = '${pKey}_5_$todayKey';
      if (diffSec >= 285 && diffSec <= 315 && !_firedAlerts.contains(alertKey5)) {
        _firedAlerts.add(alertKey5);
        AppNotificationService().showApproachingPrayerNotification(pName, 5);
      }

      // 3. Exact Adhan Arrival Time (between -15s and +15s window to never miss a tick)
      final alertKey0 = '${pKey}_0_$todayKey';
      if (diffSec >= -15 && diffSec <= 15 && !_firedAlerts.contains(alertKey0)) {
        _firedAlerts.add(alertKey0);
        if (pKey != 'sunrise') {
          ProximityWakeLockService().isAdhanPlaying().then((playing) {
            if (!playing) {
              playAdhan(prayerName: pName, muezzinId: settings.selectedMuezzin);
            }
          });
        }
      }

      // 4. Post-Prayer Taqeebat Notification (5 minutes after prayer/adhan: elapsed between 300s and 360s)
      final alertKeyTaqeebat = '${pKey}_taqeebat_$todayKey';
      if (diffSec <= -300 && diffSec >= -360 && !_firedAlerts.contains(alertKeyTaqeebat)) {
        _firedAlerts.add(alertKeyTaqeebat);
        if (pKey != 'sunrise' && settings.taqeebatNotifications) {
          AppNotificationService().showTaqeebatNotification(pName);
        }
      }
    }

    // 5. Daily Morning Deeds and Ziyarat Notification (Triggered once daily in the morning between 06:00 and 11:00)
    final alertKeyDailyDeeds = 'daily_deeds_$todayKey';
    if (now.hour >= 6 && now.hour <= 11 && !_firedAlerts.contains(alertKeyDailyDeeds)) {
      _firedAlerts.add(alertKeyDailyDeeds);
      if (settings.dailyDeedsNotifications) {
        AppNotificationService().showDailyDuaAndZiyaratNotification();
      }
    }
  }

  /// Triggers full Adhan playback and high-priority notification
  Future<void> playAdhan({
    required String prayerName,
    String? muezzinId,
  }) async {
    try {
      _currentAdhanPrayerName = prayerName;
      isPlayingAdhanNotifier.value = true;
      isVolumeLoweredNotifier.value = false;
      currentAdhanPrayerNotifier.value = prayerName;

      final targetMuezzinId = muezzinId ?? _getStoredMuezzinId();
      final muezzin = MuezzinDownloadService.muezzins.firstWhere(
        (m) => m.id == targetMuezzinId || m.name == targetMuezzinId,
        orElse: () => MuezzinDownloadService.muezzins.first,
      );

      final localPath = await MuezzinDownloadService().getLocalMuezzinPath(muezzin.id);

      // 1. On Android, launch native Android Foreground Adhan Service (forces audio through ALARM stream)
      if (Platform.isAndroid) {
        final alreadyPlaying = await ProximityWakeLockService().isAdhanPlaying();
        if (alreadyPlaying) {
          debugPrint('Native Adhan is already playing continuously, ignoring duplicate request.');
          return;
        }
        debugPrint('Launching native Adhan service for $prayerName with muezzin: ${muezzin.name}');
        await ProximityWakeLockService().playNativeAdhan(
          prayerName: prayerName,
          muezzinPath: localPath,
          muezzinName: muezzin.name,
        );
      } else {
        // Fallback for non-Android: use flutter audioplayer
        AppNotificationService().showAdhanNotification(
          prayerName: prayerName,
          muezzinName: muezzin.name,
        );

        try {
          await _adhanPlayer.setAudioContext(
            AudioContext(
              iOS: AudioContextIOS(
                category: AVAudioSessionCategory.playback,
                options: const {
                  AVAudioSessionOptions.duckOthers,
                },
              ),
            ),
          );
          await _adhanPlayer.setVolume(1.0);
        } catch (_) {}

        await _adhanPlayer.stop();
        if (localPath != null) {
          await _adhanPlayer.play(DeviceFileSource(localPath));
        } else if (muezzin.id == 'amer_kazemi') {
          await _adhanPlayer.play(AssetSource('audio/adhan.mp3'));
        } else {
          try {
            await _adhanPlayer.play(UrlSource(muezzin.cdnUrl));
          } catch (_) {
            await _adhanPlayer.play(AssetSource('audio/adhan.mp3'));
          }
        }
      }

      _adhanPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          _currentAdhanPrayerName = null;
          isPlayingAdhanNotifier.value = false;
          isVolumeLoweredNotifier.value = false;
          currentAdhanPrayerNotifier.value = null;
        }
      });
    } catch (e) {
      debugPrint('Error playing adhan: $e');
      _currentAdhanPrayerName = null;
      isPlayingAdhanNotifier.value = false;
      isVolumeLoweredNotifier.value = false;
      currentAdhanPrayerNotifier.value = null;
    }
  }

  String _getStoredMuezzinId() {
    final name = SettingsController().selectedMuezzin;
    for (final m in MuezzinDownloadService.muezzins) {
      if (m.name == name || m.id == name) return m.id;
    }
    return 'amer_kazemi';
  }

  /// Toggle Adhan volume between normal (100%) and low (~20%) without stopping playback
  Future<void> toggleAdhanVolume() async {
    final nextState = !isVolumeLoweredNotifier.value;
    await setAdhanVolume(nextState);
  }

  /// Set Adhan volume: true for low quiet volume (~20%), false for full volume (100%)
  Future<void> setAdhanVolume(bool isLow) async {
    isVolumeLoweredNotifier.value = isLow;
    try {
      if (Platform.isAndroid) {
        await ProximityWakeLockService().setNativeAdhanVolume(isLow: isLow);
      }
      await _adhanPlayer.setVolume(isLow ? 0.2 : 1.0);
    } catch (e) {
      debugPrint('Error setting adhan volume: $e');
    }
  }

  /// Stop current adhan immediately
  Future<void> stopAdhan() async {
    try {
      if (Platform.isAndroid) {
        await ProximityWakeLockService().stopNativeAdhan();
      }
      await _adhanPlayer.stop();
      _currentAdhanPrayerName = null;
      isPlayingAdhanNotifier.value = false;
      isVolumeLoweredNotifier.value = false;
      currentAdhanPrayerNotifier.value = null;
      await AppNotificationService().cancelAdhanNotifications();
    } catch (e) {
      debugPrint('Error stopping adhan: $e');
    }
  }

  /// Test Adhan Ringing and Notification
  Future<void> testAdhanSound(BuildContext context) async {
    final muezzinName = SettingsController().selectedMuezzin;
    await playAdhan(prayerName: 'صلاة الظهر (تجربة الأذان)');
    
    if (context.mounted) {
      final sm = ScaffoldMessenger.of(context);
      sm.hideCurrentSnackBar();
      sm.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
          ),
          backgroundColor: const Color(0xFF0F1E2E),
          elevation: 6,
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up_rounded, color: Color(0xFF38BDF8), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'يتم الآن تجربة الأذان بصوت $muezzinName',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'إيقاف ⏹️',
            textColor: Colors.amberAccent,
            onPressed: () {
              stopAdhan();
              sm.hideCurrentSnackBar();
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> forceRefreshStickyNotification() async {
    final savedCity = StorageService().getSavedCity() ?? CityLocation.defaultCity;
    if (_cachedCityId != savedCity.id || _cachedPrayerTimes == null) {
      _cachedCityId = savedCity.id;
      _cachedPrayerTimes = await KafeelApiService.getPrayerTimes(savedCity, targetDate: DateTime.now());
    }
    final pTimes = _cachedPrayerTimes;
    if (pTimes != null) {
      AppNotificationService().updateStickyPrayerTimesNotification(
        fajr: pTimes.fajr,
        sunrise: pTimes.sunrise,
        dhuhr: pTimes.dhuhr,
        asr: pTimes.asr,
        maghrib: pTimes.maghrib,
        isha: pTimes.isha,
      );
    }
  }

  void dispose() {
    _schedulerTimer?.cancel();
    _adhanPlayer.dispose();
  }
}
