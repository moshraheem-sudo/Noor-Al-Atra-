import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_notification_service.dart';
import 'adhan_scheduler_service.dart';

enum AppThemePalette {
  icyBlue,
  emeraldGreen,
  royalDark,
}

class SettingsController extends ChangeNotifier {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  SharedPreferences? _prefs;

  // 1. Notifications & Alerts
  bool _quranNotifications = false;
  bool _eventsNotifications = true;
  bool _dailyDeedsNotifications = true;
  bool _taqeebatNotifications = true;
  bool _stickyPrayerNotification = true;
  bool _notifyPrePrayer15Min = true;
  bool _notifyFajr = true;
  bool _notifySunrise = false;
  bool _notifyDhuhr = true;
  bool _notifyAsr = true;
  bool _notifyMaghrib = true;
  bool _notifyIsha = true;
  String _selectedMuezzin = 'الحاج عامر الكاظمي';
  final Map<String, String?> _prayerMuezzins = {
    'fajr': null,
    'dhuhr': null,
    'asr': null,
    'maghrib': null,
    'isha': null,
  };
  String _calculationMethod = 'kafeel'; // kafeel, tehran, lewa_qom, lewa_haqq
  String _midnightMethod = 'fajr'; // fajr (إلى الفجر), sunrise (إلى الشروق)

  // Prayer Alert Types: 'full' (أذان كامل), 'takbeer' (تكبيرات), 'short' (إشعار صوتي), 'vibrate' (اهتزاز), 'silent' (صامت)
  final Map<String, String> _prayerAlertTypes = {
    'fajr': 'full',
    'dhuhr': 'full',
    'asr': 'full',
    'maghrib': 'full',
    'isha': 'full',
  };

  // Prayer manual offsets (-60 to +60 minutes)
  final Map<String, int> _prayerOffsets = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'sunset': 0,
    'maghrib': 0,
    'isha': 0,
    'midnight': 0,
  };

  // Prayer Visibility in Home/Prayer screen
  final Map<String, bool> _prayerVisibility = {
    'fajr': true,
    'sunrise': true,
    'dhuhr': true,
    'asr': true,
    'sunset': true,
    'maghrib': true,
    'isha': true,
    'midnight': true,
  };

  // 2. Home Screen Customization
  bool _showDailyDeedsBanner = true;
  bool _showPrayerCard = true;
  bool _showEventsCard = true;
  bool _showQabasBanner = true;
  bool _showAlmojibCard = true;

  // 3. Theme & Appearance
  AppThemePalette _themePalette = AppThemePalette.icyBlue;

  // 4. Quran & Reading Settings
  bool _smartKashida = true;
  double _fontScale = 1.0; // 100%
  String _quranFontType = 'الرسم العثماني';
  String _defaultReciter = 'عبد الباسط عبد الصمد';

  // 5. Hijri Timing
  String _hijriMode = 'online'; // 'online' or 'manual'
  int _hijriManualOffset = 0;

  // Getters
  bool get quranNotifications => false;
  bool get eventsNotifications => _eventsNotifications;
  bool get dailyDeedsNotifications => _dailyDeedsNotifications;
  bool get taqeebatNotifications => _taqeebatNotifications;
  bool get stickyPrayerNotification => _stickyPrayerNotification;
  bool get notifyPrePrayer15Min => _notifyPrePrayer15Min;
  bool get notifyFajr => _notifyFajr;
  bool get notifySunrise => _notifySunrise;
  bool get notifyDhuhr => _notifyDhuhr;
  bool get notifyAsr => _notifyAsr;
  bool get notifyMaghrib => _notifyMaghrib;
  bool get notifyIsha => _notifyIsha;
  String get selectedMuezzin => _selectedMuezzin;
  Map<String, String?> get prayerMuezzins => _prayerMuezzins;

  bool isPrayerNotificationEnabled(String prayer) {
    if (prayer.contains('فجر') || prayer == 'fajr') return notifyFajr;
    if (prayer.contains('شروق') || prayer == 'sunrise') return notifySunrise;
    if (prayer.contains('ظهر') || prayer == 'dhuhr') return notifyDhuhr;
    if (prayer.contains('عصر') || prayer == 'asr') return notifyAsr;
    if (prayer.contains('مغرب') || prayer == 'maghrib') return notifyMaghrib;
    if (prayer.contains('عشاء') || prayer == 'isha') return notifyIsha;
    return false;
  }

  /// Returns the customized muezzin for a specific prayer, or falls back to _selectedMuezzin
  String getMuezzinForPrayer(String prayerKeyOrName) {
    String key = prayerKeyOrName.toLowerCase().trim();
    if (key.contains('فجر') || key == 'fajr') {
      key = 'fajr';
    } else if (key.contains('ظهر') || key == 'dhuhr') {
      key = 'dhuhr';
    } else if (key.contains('عصر') || key == 'asr') {
      key = 'asr';
    } else if (key.contains('مغرب') || key == 'maghrib') {
      key = 'maghrib';
    } else if (key.contains('عشاء') || key == 'isha') {
      key = 'isha';
    }

    final custom = _prayerMuezzins[key];
    if (custom != null && custom.trim().isNotEmpty && custom != 'default') {
      return custom.trim();
    }
    return _selectedMuezzin;
  }
  String get calculationMethod => _calculationMethod;
  String get midnightMethod => _midnightMethod;
  Map<String, String> get prayerAlertTypes => _prayerAlertTypes;
  Map<String, int> get prayerOffsets => _prayerOffsets;
  Map<String, bool> get prayerVisibility => _prayerVisibility;

  bool get showDailyDeedsBanner => _showDailyDeedsBanner;
  bool get showPrayerCard => _showPrayerCard;
  bool get showEventsCard => _showEventsCard;
  bool get showQabasBanner => _showQabasBanner;
  bool get showAlmojibCard => _showAlmojibCard;

  AppThemePalette get themePalette => _themePalette;
  bool get smartKashida => _smartKashida;
  double get fontScale => _fontScale;
  int get fontScalePercentage => (_fontScale * 100).round();
  String get quranFontType => _quranFontType;
  String get defaultReciter => _defaultReciter;

  String get hijriMode => _hijriMode;
  int get hijriManualOffset => _hijriManualOffset;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPreferences();
  }

  void _loadPreferences() {
    if (_prefs == null) return;
    _quranNotifications = false;
    _eventsNotifications = _prefs!.getBool('settings_events_notif') ?? true;
    _dailyDeedsNotifications = _prefs!.getBool('settings_daily_deeds_notif') ?? true;
    _taqeebatNotifications = _prefs!.getBool('settings_taqeebat_notif') ?? true;
    _stickyPrayerNotification = _prefs!.getBool('settings_sticky_prayer_notif') ?? true;
    _notifyPrePrayer15Min = _prefs!.getBool('settings_notify_pre_prayer') ?? true;
    _notifyFajr = _prefs!.getBool('settings_notify_fajr') ?? true;
    _notifySunrise = _prefs!.getBool('settings_notify_sunrise') ?? false;
    _notifyDhuhr = _prefs!.getBool('settings_notify_dhuhr') ?? true;
    _notifyAsr = _prefs!.getBool('settings_notify_asr') ?? true;
    _notifyMaghrib = _prefs!.getBool('settings_notify_maghrib') ?? true;
    _notifyIsha = _prefs!.getBool('settings_notify_isha') ?? true;
    _selectedMuezzin = _prefs!.getString('settings_selected_muezzin') ?? 'الحاج عامر الكاظمي';
    for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final saved = _prefs!.getString('settings_muezzin_$key');
      _prayerMuezzins[key] = (saved != null && saved.isNotEmpty && saved != 'default') ? saved : null;
    }
    _calculationMethod = _prefs!.getString('settings_calc_method') ?? 'kafeel';
    _midnightMethod = _prefs!.getString('settings_midnight_method') ?? 'fajr';

    // Load prayer offsets
    for (final key in _prayerOffsets.keys) {
      _prayerOffsets[key] = _prefs!.getInt('settings_prayer_offset_$key') ?? 0;
    }

    // Load prayer visibility
    for (final key in _prayerVisibility.keys) {
      _prayerVisibility[key] = _prefs!.getBool('settings_prayer_vis_$key') ?? true;
    }

    // Load prayer alert types
    for (final key in _prayerAlertTypes.keys) {
      _prayerAlertTypes[key] = _prefs!.getString('settings_prayer_alert_$key') ?? 'full';
    }

    _showDailyDeedsBanner = _prefs!.getBool('settings_show_daily_deeds') ?? true;
    _showPrayerCard = _prefs!.getBool('settings_show_prayer_card') ?? true;
    _showEventsCard = _prefs!.getBool('settings_show_events_card') ?? true;
    _showQabasBanner = _prefs!.getBool('settings_show_qabas_banner') ?? true;
    _showAlmojibCard = _prefs!.getBool('settings_show_almojib_card') ?? true;

    final paletteName = _prefs!.getString('settings_theme_palette') ?? 'icyBlue';
    if (paletteName == 'emeraldGreen') {
      _themePalette = AppThemePalette.emeraldGreen;
    } else if (paletteName == 'royalDark') {
      _themePalette = AppThemePalette.royalDark;
    } else {
      _themePalette = AppThemePalette.icyBlue;
    }

    _smartKashida = _prefs!.getBool('settings_smart_kashida') ?? true;
    _fontScale = _prefs!.getDouble('settings_font_scale') ?? 1.0;
    _quranFontType = _prefs!.getString('settings_quran_font_type') ?? 'الرسم العثماني';
    _defaultReciter = _prefs!.getString('settings_default_reciter') ?? 'عبد الباسط عبد الصمد';

    _hijriMode = _prefs!.getString('settings_hijri_mode') ?? 'online';
    _hijriManualOffset = _prefs!.getInt('settings_hijri_offset') ?? 0;

    // Ensure Quran notifications are completely stopped and cancelled
    AppNotificationService().setQuranNotificationActive(false);

    notifyListeners();
  }

  // Setters with persistence
  Future<void> setQuranNotifications(bool val) async {
    _quranNotifications = false;
    await _prefs?.setBool('settings_quran_notif', false);
    AppNotificationService().setQuranNotificationActive(false);
    notifyListeners();
  }

  Future<void> setEventsNotifications(bool val) async {
    _eventsNotifications = val;
    await _prefs?.setBool('settings_events_notif', val);
    if (val) {
      AppNotificationService().showIslamicEventNotification();
    }
    notifyListeners();
  }

  Future<void> setDailyDeedsNotifications(bool val) async {
    _dailyDeedsNotifications = val;
    await _prefs?.setBool('settings_daily_deeds_notif', val);
    if (val) {
      AppNotificationService().showDailyDuaAndZiyaratNotification();
    }
    notifyListeners();
  }

  Future<void> setTaqeebatNotifications(bool val) async {
    _taqeebatNotifications = val;
    await _prefs?.setBool('settings_taqeebat_notif', val);
    notifyListeners();
    await AppNotificationService().refreshPrayerSchedules();
  }

  Future<void> setStickyPrayerNotification(bool val) async {
    _stickyPrayerNotification = val;
    await _prefs?.setBool('settings_sticky_prayer_notif', val);
    if (!val) {
      AppNotificationService().cancelStickyPrayerNotification();
    } else {
      AdhanSchedulerService().forceRefreshStickyNotification();
    }
    notifyListeners();
  }

  Future<void> setPrayerNotification(String prayer, bool val) async {
    switch (prayer) {
      case 'fajr':
        _notifyFajr = val;
        await _prefs?.setBool('settings_notify_fajr', val);
        break;
      case 'sunrise':
        _notifySunrise = val;
        await _prefs?.setBool('settings_notify_sunrise', val);
        break;
      case 'dhuhr':
        _notifyDhuhr = val;
        await _prefs?.setBool('settings_notify_dhuhr', val);
        break;
      case 'asr':
        _notifyAsr = val;
        await _prefs?.setBool('settings_notify_asr', val);
        break;
      case 'maghrib':
        _notifyMaghrib = val;
        await _prefs?.setBool('settings_notify_maghrib', val);
        break;
      case 'isha':
        _notifyIsha = val;
        await _prefs?.setBool('settings_notify_isha', val);
        break;
    }
    notifyListeners();
    final scheduler = AdhanSchedulerService();
    if (!val) await scheduler.syncAdhanPlayingState();
    final activePrayer = scheduler.currentAdhanPrayerName;
    if (!val && activePrayer != null && !isPrayerNotificationEnabled(activePrayer)) {
      await scheduler.stopAdhan();
    }
    await AppNotificationService().refreshPrayerSchedules();
  }

  Future<void> setNotifyPrePrayer15Min(bool val) async {
    _notifyPrePrayer15Min = val;
    await _prefs?.setBool('settings_notify_pre_prayer', val);
    notifyListeners();
    await AppNotificationService().refreshPrayerSchedules();
  }

  Future<void> setPrayerOffset(String prayerKey, int offset) async {
    _prayerOffsets[prayerKey] = offset.clamp(-60, 60);
    await _prefs?.setInt('settings_prayer_offset_$prayerKey', _prayerOffsets[prayerKey]!);
    notifyListeners();
  }

  Future<void> setPrayerVisibility(String prayerKey, bool visible) async {
    _prayerVisibility[prayerKey] = visible;
    await _prefs?.setBool('settings_prayer_vis_$prayerKey', visible);
    notifyListeners();
  }

  Future<void> setPrayerAlertType(String prayerKey, String alertType) async {
    _prayerAlertTypes[prayerKey] = alertType;
    await _prefs?.setString('settings_prayer_alert_$prayerKey', alertType);
    notifyListeners();
  }

  Future<void> setMidnightMethod(String val) async {
    _midnightMethod = val;
    await _prefs?.setString('settings_midnight_method', val);
    notifyListeners();
  }

  Future<void> setSelectedMuezzin(String val) async {
    _selectedMuezzin = val;
    await _prefs?.setString('settings_selected_muezzin', val);
    notifyListeners();
    await AppNotificationService().refreshPrayerSchedules();
  }

  Future<void> setPrayerMuezzin(String prayerKey, String? muezzinName) async {
    final key = prayerKey.toLowerCase().trim();
    if (muezzinName == null || muezzinName.isEmpty || muezzinName == 'default') {
      _prayerMuezzins[key] = null;
      await _prefs?.remove('settings_muezzin_$key');
    } else {
      _prayerMuezzins[key] = muezzinName;
      await _prefs?.setString('settings_muezzin_$key', muezzinName);
    }
    notifyListeners();
    await AppNotificationService().refreshPrayerSchedules();
  }

  Future<void> setCalculationMethod(String val) async {
    _calculationMethod = val;
    await _prefs?.setString('settings_calc_method', val);
    notifyListeners();
  }

  Future<void> setShowDailyDeedsBanner(bool val) async {
    _showDailyDeedsBanner = val;
    await _prefs?.setBool('settings_show_daily_deeds', val);
    notifyListeners();
  }

  Future<void> setShowPrayerCard(bool val) async {
    _showPrayerCard = val;
    await _prefs?.setBool('settings_show_prayer_card', val);
    notifyListeners();
  }

  Future<void> setShowEventsCard(bool val) async {
    _showEventsCard = val;
    await _prefs?.setBool('settings_show_events_card', val);
    notifyListeners();
  }

  Future<void> setShowQabasBanner(bool val) async {
    _showQabasBanner = val;
    await _prefs?.setBool('settings_show_qabas_banner', val);
    notifyListeners();
  }

  Future<void> setShowAlmojibCard(bool val) async {
    _showAlmojibCard = val;
    await _prefs?.setBool('settings_show_almojib_card', val);
    notifyListeners();
  }

  Future<void> setThemePalette(AppThemePalette palette) async {
    _themePalette = palette;
    String name = 'icyBlue';
    if (palette == AppThemePalette.emeraldGreen) name = 'emeraldGreen';
    if (palette == AppThemePalette.royalDark) name = 'royalDark';
    await _prefs?.setString('settings_theme_palette', name);
    notifyListeners();
  }

  Future<void> setSmartKashida(bool val) async {
    _smartKashida = val;
    await _prefs?.setBool('settings_smart_kashida', val);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.7, 1.5);
    await _prefs?.setDouble('settings_font_scale', _fontScale);
    notifyListeners();
  }

  void incrementFontScale() {
    double next = (_fontScale + 0.05).clamp(0.7, 1.5);
    setFontScale(double.parse(next.toStringAsFixed(2)));
  }

  void decrementFontScale() {
    double next = (_fontScale - 0.05).clamp(0.7, 1.5);
    setFontScale(double.parse(next.toStringAsFixed(2)));
  }

  Future<void> setQuranFontType(String val) async {
    _quranFontType = val;
    await _prefs?.setString('settings_quran_font_type', val);
    notifyListeners();
  }

  Future<void> setDefaultReciter(String val) async {
    _defaultReciter = val;
    await _prefs?.setString('settings_default_reciter', val);
    notifyListeners();
  }

  Future<void> setHijriMode(String mode) async {
    _hijriMode = mode;
    await _prefs?.setString('settings_hijri_mode', mode);
    notifyListeners();
  }

  Future<void> setHijriManualOffset(int offset) async {
    _hijriManualOffset = offset;
    await _prefs?.setInt('settings_hijri_offset', offset);
    notifyListeners();
  }

  /// Calculate Cache Size
  Future<String> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      if (totalSize < 1024) return '$totalSize بايت';
      if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} ك.ب';
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} م.ب';
    } catch (_) {
      return '0.0 م.ب';
    }
  }

  /// Clear App Cache
  Future<bool> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final children = tempDir.listSync();
        for (var child in children) {
          if (child is File) {
            await child.delete();
          } else if (child is Directory) {
            await child.delete(recursive: true);
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    await _prefs?.clear();
    _loadPreferences();
    notifyListeners();
  }
}
