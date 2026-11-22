import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/prayer_times.dart';
import '../models/city_location.dart';
import '../services/kafeel_api_service.dart';
import '../services/storage_service.dart';
import '../services/data_service.dart';
import '../services/qibla_service.dart';
import '../services/app_notification_service.dart';
import '../services/adhan_scheduler_service.dart';
import '../services/settings_controller.dart';

class PrayerProvider extends ChangeNotifier {
  CityLocation _selectedCity = CityLocation.defaultCity;
  PrayerTimesModel? _prayerTimes;
  bool _isLoading = false;
  String _nextPrayerName = 'الظهر';
  String _timeUntilNextPrayer = '00:00:00';
  double _qiblaBearing = 207.0;
  Timer? _timer;

  CityLocation get selectedCity => _selectedCity;
  PrayerTimesModel? get prayerTimes => _prayerTimes;
  bool get isLoading => _isLoading;
  String get nextPrayerName => _nextPrayerName;
  String get timeUntilNextPrayer => _timeUntilNextPrayer;
  double get qiblaBearing => _qiblaBearing;

  PrayerProvider() {
    _qiblaBearing = QiblaService.calculateQiblaDirection(
      _selectedCity.latitude,
      _selectedCity.longitude,
    );
    if (_qiblaBearing <= 0) _qiblaBearing = 207.0;
    _init();
  }

  Future<void> _init() async {
    final savedCity = StorageService().getSavedCity();
    if (savedCity != null) {
      _selectedCity = savedCity;
    } else {
      final savedCityId = StorageService().getSelectedCityId();
      final cities = DataService().cities;
      if (cities.isNotEmpty) {
        _selectedCity = cities.firstWhere(
          (c) => c.id == savedCityId,
          orElse: () => cities.first,
        );
      }
    }
    _qiblaBearing = QiblaService.calculateQiblaDirection(
      _selectedCity.latitude,
      _selectedCity.longitude,
    );
    if (_qiblaBearing <= 0) _qiblaBearing = 207.0;
    await fetchPrayerTimes();
    _startCountdownTimer();
  }

  Future<void> selectCity(CityLocation city) async {
    _selectedCity = city;
    await StorageService().saveSelectedCity(city);
    _qiblaBearing = QiblaService.calculateQiblaDirection(city.latitude, city.longitude);
    if (_qiblaBearing <= 0) _qiblaBearing = 207.0;
    notifyListeners();
    await fetchPrayerTimes();
    try {
      await AdhanSchedulerService().onCityChanged(city);
    } catch (_) {}
  }

  /// Automatically detects device location via GPS, requests system permissions,
  /// maps to nearest city while preserving exact GPS coordinates, and updates prayer times.
  Future<String?> detectLocationViaGps() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Check and request permission first (triggers the exact native dialog from the screenshot)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLoading = false;
          notifyListeners();
          return 'permission_denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLoading = false;
        notifyListeners();
        return 'permission_denied_forever';
      }

      // 2. Check if location services (GPS hardware switch) are enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        _isLoading = false;
        notifyListeners();
        return 'service_disabled';
      }

      // 3. High accuracy location detection via GPS
      Position? position;

      // Layer 1: High Accuracy GPS position
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high, // High accuracy GPS requested
            distanceFilter: 10,
            forceLocationManager: true, // Safe for devices and emulators
            timeLimit: const Duration(seconds: 8),
          ),
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Location timeout'),
        );
      } catch (e) {
        debugPrint('getCurrentPosition high accuracy error: $e');
        // Layer 2: Fallback to last known position or medium accuracy
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 5),
              ),
            ).timeout(const Duration(seconds: 5));
          } catch (_) {}
        }
      }

      // Layer 3: If still null
      if (position == null) {
        _isLoading = false;
        notifyListeners();
        return 'تعذر التقاط إشارة GPS من الجهاز حالياً. يرجى التأكد من تشغيل الـ GPS أو اختيار المدينة يدوياً.';
      }

      // Check if position is Android Studio AVD default mock location (~37.422, -122.084 Mountain View, California)
      final bool isEmulatorMock =
          (position.latitude - 37.422).abs() < 0.25 && (position.longitude - (-122.084)).abs() < 0.25;

      final double targetLat = isEmulatorMock ? CityLocation.defaultCity.latitude : position.latitude;
      final double targetLng = isEmulatorMock ? CityLocation.defaultCity.longitude : position.longitude;

      // Find nearest city from cities list as baseline
      final cities = DataService().cities;
      CityLocation nearest = CityLocation.defaultCity;
      double minDistance = double.infinity;

      for (final city in cities) {
        final d = Geolocator.distanceBetween(
          targetLat,
          targetLng,
          city.latitude,
          city.longitude,
        );
        if (d < minDistance) {
          minDistance = d;
          nearest = city;
        }
      }

      String detectedNameAr = nearest.nameAr;
      String detectedNameEn = nearest.nameEn;
      String detectedCountryAr = nearest.countryAr;
      String detectedProvince = nearest.province;
      bool isHoly = nearest.isHolyCity;

      if (!isEmulatorMock) {
        // When internet is available, fetch exact Arabic place name via reverse geocoding
        try {
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$targetLat&lon=$targetLng&accept-language=ar',
          );
          final res = await http.get(url, headers: {
            'User-Agent': 'NoorAlatraApp/5.0 (contact: support@noor-alatra.app)',
          }).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200) {
            final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
            final addr = data['address'] as Map<String, dynamic>? ?? {};
            final cityName = addr['city'] ??
                addr['town'] ??
                addr['municipality'] ??
                addr['village'] ??
                addr['suburb'] ??
                addr['county'];
            final stateName = addr['state'] ?? addr['province'] ?? addr['region'];
            final countryName = addr['country'];

            if (cityName != null && cityName.toString().trim().isNotEmpty) {
              detectedNameAr = cityName.toString().trim();
            } else if (stateName != null && stateName.toString().trim().isNotEmpty) {
              detectedNameAr = stateName.toString().trim();
            }
            if (stateName != null && stateName.toString().trim().isNotEmpty) {
              detectedProvince = stateName.toString().trim();
            }
            if (countryName != null && countryName.toString().trim().isNotEmpty) {
              detectedCountryAr = countryName.toString().trim();
            }
          }
        } catch (e) {
          debugPrint('Reverse geocoding offline or timed out, using reference points: $e');
        }
      }

      final detectedCity = CityLocation(
        id: 'gps_${targetLat.toStringAsFixed(3)}_${targetLng.toStringAsFixed(3)}',
        nameAr: detectedNameAr,
        nameEn: detectedNameEn,
        countryAr: detectedCountryAr,
        latitude: targetLat,
        longitude: targetLng,
        timezone: nearest.timezone,
        isHolyCity: isHoly,
        province: detectedProvince,
      );

      await StorageService().saveGpsCity(detectedCity);
      await selectCity(detectedCity);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'تعذر تحديد الموقع عبر GPS: $e';
    }
  }

  Future<void> fetchPrayerTimes() async {
    _isLoading = true;
    notifyListeners();

    _prayerTimes = await KafeelApiService.getPrayerTimes(_selectedCity);
    _isLoading = false;
    _updateNextPrayer();
    _syncStickyNotification();
    if (_prayerTimes != null) {
      AppNotificationService().schedulePrayerAlarmsAndReminders(
        prayerTimes: _prayerTimes!,
        date: DateTime.now(),
      );
    }
    notifyListeners();
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _syncStickyNotification();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNextPrayer();
      if (DateTime.now().second == 0) {
        _syncStickyNotification();
      }
      notifyListeners();
    });
  }

  void _syncStickyNotification() {
    if (_prayerTimes == null) return;
    if (!SettingsController().stickyPrayerNotification) return;
    AppNotificationService().updateStickyPrayerTimesNotification(
      fajr: _prayerTimes!.fajr,
      sunrise: _prayerTimes!.sunrise,
      dhuhr: _prayerTimes!.dhuhr,
      asr: _prayerTimes!.asr,
      maghrib: _prayerTimes!.maghrib,
      isha: _prayerTimes!.isha,
      nextPrayerName: _nextPrayerName,
      nextPrayerCountdown: _timeUntilNextPrayer,
    );
  }

  final Set<String> _firedAlerts = {};

  void _checkPrayerReminders(DateTime now) {
    if (_prayerTimes == null) return;
    final settings = SettingsController();
    final todayKey = '${now.year}_${now.month}_${now.day}';

    final prayerList = [
      {'key': 'fajr', 'name': 'الفجر', 'time': _prayerTimes!.fajr, 'enabled': settings.notifyFajr},
      {'key': 'sunrise', 'name': 'الشروق', 'time': _prayerTimes!.sunrise, 'enabled': settings.notifySunrise},
      {'key': 'dhuhr', 'name': 'الظهر', 'time': _prayerTimes!.dhuhr, 'enabled': settings.notifyDhuhr},
      {'key': 'asr', 'name': 'العصر', 'time': _prayerTimes!.asr, 'enabled': settings.notifyAsr},
      {'key': 'maghrib', 'name': 'المغرب', 'time': _prayerTimes!.maghrib, 'enabled': settings.notifyMaghrib},
      {'key': 'isha', 'name': 'العشاء', 'time': _prayerTimes!.isha, 'enabled': settings.notifyIsha},
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

      // 1. 10 Minutes Reminder (between 9m 50s and 10m 10s)
      final alertKey10 = '${pKey}_10_$todayKey';
      if (diffSec >= 590 && diffSec <= 610 && !_firedAlerts.contains(alertKey10)) {
        _firedAlerts.add(alertKey10);
        AppNotificationService().showApproachingPrayerNotification(pName, 10);
      }

      // 2. 5 Minutes Reminder (between 4m 50s and 5m 10s)
      final alertKey5 = '${pKey}_5_$todayKey';
      if (diffSec >= 290 && diffSec <= 310 && !_firedAlerts.contains(alertKey5)) {
        _firedAlerts.add(alertKey5);
        AppNotificationService().showApproachingPrayerNotification(pName, 5);
      }

      // 3. Exact Adhan Arrival Time (between -5s and +5s)
      final alertKey0 = '${pKey}_0_$todayKey';
      if (diffSec >= -5 && diffSec <= 5 && !_firedAlerts.contains(alertKey0)) {
        _firedAlerts.add(alertKey0);
        if (pKey != 'sunrise') {
          AppNotificationService().playAdhanAndNotify(pName, muezzinName: settings.selectedMuezzin);
        }
      }
    }
  }

  void _updateNextPrayer() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    _checkPrayerReminders(now);

    final prayers = [
      {'name': 'الفجر', 'time': _prayerTimes!.fajr},
      {'name': 'الشروق', 'time': _prayerTimes!.sunrise},
      {'name': 'الظهر', 'time': _prayerTimes!.dhuhr},
      {'name': 'العصر', 'time': _prayerTimes!.asr},
      {'name': 'المغرب', 'time': _prayerTimes!.maghrib},
      {'name': 'العشاء', 'time': _prayerTimes!.isha},
    ];

    DateTime? nextDateTime;
    String candidateName = 'الفجر';

    for (final p in prayers) {
      final parts = p['time']!.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final pDate = DateTime(now.year, now.month, now.day, h, m);
        if (pDate.isAfter(now)) {
          nextDateTime = pDate;
          candidateName = p['name']!;
          break;
        }
      }
    }

    // If all today passed, next is tomorrow's Fajr
    if (nextDateTime == null) {
      final parts = _prayerTimes!.fajr.split(':');
      final h = int.tryParse(parts[0]) ?? 4;
      final m = int.tryParse(parts[1]) ?? 30;
      nextDateTime = DateTime(now.year, now.month, now.day + 1, h, m);
      candidateName = 'الفجر';
    }

    _nextPrayerName = candidateName;
    final diff = nextDateTime.difference(now);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    _timeUntilNextPrayer = '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
