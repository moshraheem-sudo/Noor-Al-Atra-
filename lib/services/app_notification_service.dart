import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'hijri_date_service.dart';
import 'data_service.dart';
import 'audio_player_service.dart';
import 'adhan_scheduler_service.dart';
import 'proximity_wakelock_service.dart';
import 'muezzin_download_service.dart';
import 'settings_controller.dart';
import '../models/prayer_times.dart';
import '../models/quran_chapter.dart';
import '../screens/quran_reader_screen.dart';
import '../screens/worship_category_detail_screen.dart';



@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == 'stop_adhan') {
    AppNotificationService().stopAdhan();
  } else if (response.actionId == 'toggle_adhan_volume' || response.actionId == 'lower_adhan_volume') {
    AdhanSchedulerService().toggleAdhanVolume();
  }
}

class AppNotificationService {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  GlobalKey<NavigatorState>? navigatorKey;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Timer? _quranTimer;

  // Curated Authentic Quran Verses in full Uthmani script with proper diacritics
  static final List<Map<String, dynamic>> uthmaniQuranVerses = [
    {
      'surahName': 'آل عمران',
      'surahId': 3,
      'ayahNum': 129,
      'text': 'وَلِلَّهِ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ يَغْفِرُ لِمَن يَشَاءُ وَيُعَذِّبُ مَن يَشَاءُ ۚ وَاللَّهُ غَفُورٌ رَّحِيمٌ',
    },
    {
      'surahName': 'البقرة',
      'surahId': 2,
      'ayahNum': 137,
      'text': 'فَسَيَكْفِيكَهُمُ اللَّهُ ۚ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    },
    {
      'surahName': 'البقرة',
      'surahId': 2,
      'ayahNum': 255,
      'text': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
    },
    {
      'surahName': 'البقرة',
      'surahId': 2,
      'ayahNum': 286,
      'text': 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ',
    },
    {
      'surahName': 'آل عمران',
      'surahId': 3,
      'ayahNum': 103,
      'text': 'وَاعْتَصِمُوا بِحَبْلِ اللَّهِ جَمِيعًا وَلَا تَفَرَّقُوا ۚ وَاذْكُرُوا نِعْمَتَ اللَّهِ عَلَيْكُمْ',
    },
    {
      'surahName': 'آل عمران',
      'surahId': 3,
      'ayahNum': 173,
      'text': 'الَّذِينَ قَالَ لَهُمُ النَّاسُ إِنَّ النَّاسَ قَدْ جَمَعُوا لَكُمْ فَاخْشَوْهُمْ فَزَادَهُمْ إِيمَانًا وَقَالُوا حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    },
    {
      'surahName': 'الرعد',
      'surahId': 13,
      'ayahNum': 28,
      'text': 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    },
    {
      'surahName': 'الإسراء',
      'surahId': 17,
      'ayahNum': 82,
      'text': 'وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ ۙ وَلَا يَزِيدُ الظَّالِمِينَ إِلَّا خَسَارًا',
    },
    {
      'surahName': 'النور',
      'surahId': 24,
      'ayahNum': 35,
      'text': 'اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ ۚ مَثَلُ نُورِهِ كَمِشْكَاةٍ فِيهَا مِصْبَاحٌ ۖ الْمِصْبَاحُ فِي زُجَاجَةٍ ۖ الزُّجَاجَةُ كَأَنَّهَا كَوْكَبٌ دُرِّيٌّ',
    },
    {
      'surahName': 'يس',
      'surahId': 36,
      'ayahNum': 58,
      'text': 'سَلَامٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ',
    },
    {
      'surahName': 'الزمر',
      'surahId': 39,
      'ayahNum': 53,
      'text': 'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا ۚ إِنَّهُ هُوَ الْغَفُورُ الرَّحِيمُ',
    },
    {
      'surahName': 'غافر',
      'surahId': 40,
      'ayahNum': 60,
      'text': 'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ',
    },
    {
      'surahName': 'الفتح',
      'surahId': 48,
      'ayahNum': 1,
      'text': 'إِنَّا فَتَحْنَا لَكَ فَتْحًا مُّبِينًا',
    },
    {
      'surahName': 'الحشر',
      'surahId': 59,
      'ayahNum': 22,
      'text': 'هُوَ اللَّهُ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ ۖ عَالِمُ الْغَيْبِ وَالشَّهَادَةِ ۖ هُوَ الرَّحْمَٰنُ الرَّحِيمُ',
    },
    {
      'surahName': 'الطلاق',
      'surahId': 65,
      'ayahNum': 3,
      'text': 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ ۚ إِنَّ اللَّهَ بَالِغُ أَمْرِهِ ۚ قَدْ جَعَلَ اللَّهُ لِكُلِّ شَيْءٍ قَدْرًا',
    },
    {
      'surahName': 'الإنسان',
      'surahId': 76,
      'ayahNum': 8,
      'text': 'وَيُطْعِمُونَ الطَّعَامَ عَلَىٰ حُبِّهِ مِسْكِينًا وَيَتِيمًا وَأَسِيرًا • إِنَّمَا نُطْعِمُكُمْ لِوَجْهِ اللَّهِ لَا نُرِيدُ مِنكُمْ جَزَاءً وَلَا شُكُورًا',
    },
    {
      'surahName': 'الضحى',
      'surahId': 93,
      'ayahNum': 5,
      'text': 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ',
    },
    {
      'surahName': 'الشرح',
      'surahId': 94,
      'ayahNum': 5,
      'text': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا • إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    },
    {
      'surahName': 'القدر',
      'surahId': 97,
      'ayahNum': 1,
      'text': 'إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ',
    },
    {
      'surahName': 'الكوثر',
      'surahId': 108,
      'ayahNum': 1,
      'text': 'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ • فَصَلِّ لِرَبِّكَ وَانْحَرْ • إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ',
    },
    {
      'surahName': 'الإخلاص',
      'surahId': 112,
      'ayahNum': 1,
      'text': 'قُلْ هُوَ اللَّهُ أَحَدٌ • اللَّهُ الصَّمَدُ • لَمْ يَلِدْ وَلَمْ يُولَدْ • وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
    },
  ];



  /// Initialize local notification channels
  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification action clicked: ${response.actionId} - ${response.payload}');
          _handleNotificationResponse(response);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Explicitly register Android Notification Channels for heads-up alerts, ongoing cards and sound
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        try {
          await androidPlugin.deleteNotificationChannel(channelId: 'adhan_live_channel');
          await androidPlugin.deleteNotificationChannel(channelId: 'adhan_live_channel_v2');
          await androidPlugin.deleteNotificationChannel(channelId: 'adhan_live_channel_v3');
          await androidPlugin.deleteNotificationChannel(channelId: 'sticky_prayer_cards_v7');
        } catch (_) {}

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'adhan_live_audio_channel_v6',
            'أذان الصلاة المباشر',
            description: 'إطلاق الأذان المبارك عند دخول وقت الفريضة الشرعي مع زر إيقاف فوري',
            importance: Importance.max,
            playSound: false,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'sticky_prayer_cards_v8',
            'مواقيت الصلاة الدائمة',
            description: 'عرض أوقات الصلاة في بطاقات أنيقة مثبتة في مركز الإشعارات',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'adhan_approaching_alerts_channel',
            'تنبيهات اقتراب الصلاة والأذان',
            description: 'إشعارات التذكير قبل موعد الصلاة بـ 10 و 5 دقائق',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'taqeebat_channel',
            'تعقيبات الصلاة',
            description: 'تذكير بتعقيبات الصلاة بعد انتهاء الأذان بخمس دقائق',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        try {
          await androidPlugin.deleteNotificationChannel(channelId: 'quran_verses_channel');
          await androidPlugin.deleteNotificationChannel(channelId: 'quran_verses_channel_v3');
          await androidPlugin.deleteNotificationChannel(channelId: 'quran_verses_channel_v4');
        } catch (_) {}
        cancelQuranNotification();
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'daily_deeds_channel',
            'أدعية وزيارات الأيام',
            description: 'تنبيهات بأدعية وزيارات اليوم المأثورة عن أهل البيت عليهم السلام',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'islamic_events_channel',
            'المناسبات الدينية والتقويم الهجري',
            description: 'تنبيهات بأيام الفضيلة والمناسبات الدينية',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  /// Request Notification and Exact Alarm / Background permissions explicitly
  Future<void> requestPermissionsAndBatteryOptimization() async {
    await init();
    if (!_isInitialized) return;
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
      // Request native Android Battery Optimization exemption (Doze bypass)
      await ProximityWakeLockService().requestIgnoreBatteryOptimizations();
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  /// Check if the app is currently exempt from battery optimization
  Future<bool> isBatteryOptimizationIgnored() async {
    return await ProximityWakeLockService().isBatteryOptimizationIgnored();
  }

  /// Handles user tapping notification bodies or actionable buttons
  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == 'stop_adhan') {
      stopAdhan();
      return;
    } else if (actionId == 'toggle_adhan_volume' || actionId == 'lower_adhan_volume') {
      AdhanSchedulerService().toggleAdhanVolume();
      return;
    }

    if (payload == null || payload.isEmpty) return;

    // 1. Quran Verse Notification ('quran_{surahId}_{ayahNum}')
    if (payload.startsWith('quran_')) {
      final parts = payload.split('_');
      if (parts.length >= 3) {
        final surahId = int.tryParse(parts[1]) ?? 1;
        final ayahNum = int.tryParse(parts[2]) ?? 1;

        final chapter = QuranChapter.allChapters.firstWhere(
          (c) => c.id == surahId,
          orElse: () => QuranChapter.allChapters.first,
        );

        final shouldAutoPlay = (actionId == 'listen_ayah');

        navigatorKey?.currentState?.push(
          MaterialPageRoute(
            builder: (_) => QuranReaderScreen(
              chapter: chapter,
              initialAyah: ayahNum,
              autoPlayAyah: shouldAutoPlay,
            ),
          ),
        );
      }
      return;
    }

    // 2. Post-Prayer Taqeebat Notification ('taqeebat_{prayerName}')
    if (payload.startsWith('taqeebat_')) {
      navigatorKey?.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const WorshipCategoryDetailScreen(
            title: 'تعقيبات الصلاة',
            categoryKey: 'taqeebat',
          ),
        ),
      );
      return;
    }

    // 3. Daily Deeds & Ziyarat Notification ('daily_deeds_{weekday}')
    if (payload.startsWith('daily_deeds_')) {
      navigatorKey?.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const WorshipCategoryDetailScreen(
            title: 'الأدعية والزيارات',
            tabs: [
              WorshipTabItem(title: 'أدعية الأيام', categoryKey: 'dailyPrayers'),
              WorshipTabItem(title: 'زيارات أيام الأسبوع', categoryKey: 'ziyaratsOfDays'),
            ],
          ),
        ),
      );
      return;
    }
  }

  /// 1. Quran verse notifications disabled per user request
  Future<void> showQuranVerseNotification({Map<String, dynamic>? verse}) async {
    await cancelQuranNotification();
  }

  /// 1.1 Trigger Post-Prayer Taqeebat Notification (5 minutes after Adhan)
  Future<void> showTaqeebatNotification(String prayerName) async {
    await init();
    if (!_isInitialized) return;

    final title = 'تعقيبات $prayerName المستحبة 🤲';
    final body = 'مضت 5 دقائق على صلاة $prayerName • حان وقت التعقيبات والدعاء المأثور';

    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      contentTitle: title,
    );

    final androidDetails = AndroidNotificationDetails(
      'taqeebat_channel',
      'تعقيبات الصلاة',
      channelDescription: 'تذكير بتعقيبات الصلاة بعد انتهاء الأذان بخمس دقائق',
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: bigTextStyleInformation,
      color: const Color(0xFF059669),
      enableLights: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/app_icon'),
      actions: const [
        AndroidNotificationAction(
          'open_taqeebat',
          'قراءة التعقيب 📖',
          showsUserInterface: true,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _localNotifications.show(
        id: 3500,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'taqeebat_$prayerName',
      );
    } catch (e) {
      debugPrint('Error showing Taqeebat notification: $e');
    }
  }

  /// 1.2 Trigger Daily Dua and Ziyarat Notification for the Day of Week
  Future<void> showDailyDuaAndZiyaratNotification() async {
    await init();
    if (!_isInitialized) return;

    final hijriInfo = HijriDateService.getHijriDate();
    final weekday = hijriInfo['weekday'] as String;
    final deeds = HijriDateService.getDeedsForDay();

    String title = 'أدعية وزيارات يوم $weekday المبارك 🕌';
    String body;
    if (deeds.isNotEmpty) {
      final names = deeds.take(2).map((d) => d['title']).join(' و ');
      body = 'من أعمال اليوم المستحبة: $names المأثورة عن أهل البيت (ع)';
    } else {
      body = 'اليوم $weekday • طابت أوقاتكم بذكر الله والصلاة على محمد وآل محمد';
    }

    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      contentTitle: title,
    );

    final androidDetails = AndroidNotificationDetails(
      'daily_deeds_channel',
      'أدعية وزيارات الأيام',
      channelDescription: 'تنبيهات بأدعية وزيارات اليوم المأثورة عن أهل البيت عليهم السلام',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
      color: const Color(0xFF1B3A57),
      enableLights: true,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/app_icon'),
      actions: const [
        AndroidNotificationAction(
          'open_daily_deeds',
          'فتح أعمال اليوم 📜',
          showsUserInterface: true,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _localNotifications.show(
        id: 1004,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'daily_deeds_$weekday',
      );
    } catch (e) {
      debugPrint('Error showing daily deeds notification: $e');
    }
  }

  /// 2. Send / Trigger Islamic Event Notification according to Hijri Calendar
  Future<void> showIslamicEventNotification() async {
    await init();
    if (!_isInitialized) return;

    final hijriInfo = HijriDateService.getHijriDate();
    final day = hijriInfo['day'] as int;
    final month = hijriInfo['month'] as int;
    final monthName = hijriInfo['monthName'] as String;
    final weekday = hijriInfo['weekday'] as String;

    final eventsForToday = DataService().events.where((e) => e.month == month && e.day == day).toList();

    String title;
    String body;

    if (eventsForToday.isNotEmpty) {
      final event = eventsForToday.first;
      title = 'مناسبة اليوم: ${event.name}';
      body = 'اليوم $weekday، $day $monthName هـ';
    } else {
      title = 'التقويم الهجري: $weekday';
      body = '$day $monthName ${hijriInfo['year']} هـ';
    }

    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      contentTitle: title,
    );

    final androidDetails = AndroidNotificationDetails(
      'islamic_events_channel',
      'المناسبات وأيام الفضيلة',
      channelDescription: 'تنبيهات المناسبات الدينية وأيام الفضيلة وفق التقويم الهجري الشرعي',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
      color: const Color(0xFF1B3A57),
      enableLights: true,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/app_icon'),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _localNotifications.show(
        id: 1002,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'islamic_event_${month}_$day',
      );
    } catch (e) {
      debugPrint('Error showing Islamic event notification: $e');
    }
  }

  /// Helper to format time into clean 12-hour format with ص/م matching the status bar widget
  static String formatPrayerTime12h(String time24) {
    final parts = time24.split(':');
    if (parts.length >= 2) {
      int h = int.tryParse(parts[0].trim()) ?? 0;
      final m = parts[1].trim().padLeft(2, '0');
      final isPM = h >= 12;
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      final hStr = h.toString().padLeft(2, '0');
      return isPM ? '$hStr:$m م' : '$hStr:$m ص';
    }
    return time24;
  }

  /// 3. Update Sticky / Ongoing Mobile Notification Bar for Prayer Times (Clean layout matching Prayer-Times app)
  Future<void> updateStickyPrayerTimesNotification({
    required String fajr,
    required String sunrise,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
    String? nextPrayerName,
    String? nextPrayerCountdown,
  }) async {
    await init();
    if (!_isInitialized) return;

    final formattedFajr = formatPrayerTime12h(fajr);
    final formattedSunrise = formatPrayerTime12h(sunrise);
    final formattedDhuhr = formatPrayerTime12h(dhuhr);
    final formattedMaghrib = formatPrayerTime12h(maghrib);

    // Persist prayer times for background boot receiver & system restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sticky_fajr', formattedFajr);
      await prefs.setString('sticky_sunrise', formattedSunrise);
      await prefs.setString('sticky_dhuhr', formattedDhuhr);
      await prefs.setString('sticky_maghrib', formattedMaghrib);
      await prefs.setBool('sticky_active', true);
    } catch (_) {}

    // 1. Native Custom Decorated Layout matching Prayer-Times app exactly
    bool customSuccess = false;
    if (Platform.isAndroid) {
      try {
        customSuccess = await ProximityWakeLockService().updateCustomPrayerNotification(
          fajr: formattedFajr,
          sunrise: formattedSunrise,
          dhuhr: formattedDhuhr,
          maghrib: formattedMaghrib,
        );
      } catch (e) {
        debugPrint('Error updating custom card prayer notification: $e');
      }
    }

    // 2. Fallback only if custom card notification is not supported or failed
    if (!customSuccess) {
      try {
        final summary = 'الفجر: $formattedFajr | الشروق: $formattedSunrise | الظهر: $formattedDhuhr | المغرب: $formattedMaghrib';
        final subtitle = (nextPrayerName != null && nextPrayerCountdown != null)
            ? 'الصلاة القادمة: $nextPrayerName خلال $nextPrayerCountdown'
            : 'مواقيت الصلاة وفق مركز الكفيل';

        final bigTextStyleInformation = BigTextStyleInformation(
          '$summary\n$subtitle',
          contentTitle: 'مواقيت الصلاة الشرعية 🕌',
          summaryText: 'تطبيق نور العترة',
        );

        final androidDetails = AndroidNotificationDetails(
          'prayer_ongoing_times_bar_v1',
          'شريط مواقيت الصلاة الدائم',
          channelDescription: 'بطاقة دائمة في لوحة الإشعارات تعرض مواقيت الصلاة لليوم بدقة',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          playSound: false,
          enableVibration: false,
          styleInformation: bigTextStyleInformation,
          color: const Color(0xFF00796B),
          icon: '@drawable/ic_notification',
          largeIcon: const DrawableResourceAndroidBitmap('@drawable/app_icon'),
        );

        final notificationDetails = NotificationDetails(android: androidDetails);
        await _localNotifications.show(
          id: 10001,
          title: 'مواقيت الصلاة الشرعية 🕌',
          body: summary,
          notificationDetails: notificationDetails,
          payload: 'sticky_prayer_times',
        );
      } catch (e) {
        debugPrint('Error showing local sticky notification: $e');
      }
    }
  }

  /// Schedules all OS-level exact alarms and reminders for prayers
  Future<void> schedulePrayerAlarmsAndReminders({
    required PrayerTimesModel prayerTimes,
    required DateTime date,
  }) async {
    await init();
    if (!_isInitialized) return;

    final settings = SettingsController();
    final now = DateTime.now();

    final prayers = [
      {'index': 1, 'key': 'fajr', 'name': 'الفجر', 'time': prayerTimes.fajr, 'enabled': settings.notifyFajr, 'isAdhan': true},
      {'index': 2, 'key': 'sunrise', 'name': 'الشروق', 'time': prayerTimes.sunrise, 'enabled': settings.notifySunrise, 'isAdhan': false},
      {'index': 3, 'key': 'dhuhr', 'name': 'الظهر', 'time': prayerTimes.dhuhr, 'enabled': settings.notifyDhuhr, 'isAdhan': true},
      {'index': 4, 'key': 'asr', 'name': 'العصر', 'time': prayerTimes.asr, 'enabled': settings.notifyAsr, 'isAdhan': true},
      {'index': 5, 'key': 'maghrib', 'name': 'المغرب', 'time': prayerTimes.maghrib, 'enabled': settings.notifyMaghrib, 'isAdhan': true},
      {'index': 6, 'key': 'isha', 'name': 'العشاء', 'time': prayerTimes.isha, 'enabled': settings.notifyIsha, 'isAdhan': true},
    ];

    final nowDay = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final dayOffset = targetDay.difference(nowDay).inDays;

    for (final p in prayers) {
      if (!(p['enabled'] as bool)) continue;

      final timeParts = (p['time'] as String).split(':');
      if (timeParts.length < 2) continue;

      final h = int.tryParse(timeParts[0].trim()) ?? 0;
      final m = int.tryParse(timeParts[1].trim()) ?? 0;
      final prayerDateTime = DateTime(date.year, date.month, date.day, h, m);
      final idx = p['index'] as int;
      final pName = p['name'] as String;
      final isAdhan = p['isAdhan'] as bool;
      final uniquePrayerId = (dayOffset * 10) + idx;

      // 1. 10-Minute Reminder Before Prayer (تذكير قبل الصلاة بـ 10 دقائق)
      final rem10Time = prayerDateTime.subtract(const Duration(minutes: 10));
      if (rem10Time.isAfter(now)) {
        try {
          await _localNotifications.zonedSchedule(
            id: 2100 + uniquePrayerId,
            title: 'اقتراب وقت صلاة $pName ⏳',
            body: 'بقي ١٠ دقائق على موعد أذان $pName • تهيأ للوضوء والصلاة',
            scheduledDate: tz.TZDateTime.from(rem10Time, tz.local),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'adhan_approaching_alerts_channel',
                'تنبيهات اقتراب الصلاة والأذان',
                channelDescription: 'إشعارات التذكير قبل موعد الصلاة بـ 10 و 5 دقائق',
                importance: Importance.high,
                priority: Priority.high,
                color: Color(0xFFC09040),
                enableLights: true,
                enableVibration: true,
                icon: '@drawable/ic_notification',
                largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            payload: 'approaching_${p['key']}_10',
          );
        } catch (e) {
          debugPrint('Error scheduling 10m reminder: $e');
        }
      }

      // 2. 5-Minute Reminder Before Prayer (تذكير قبل الصلاة بـ 5 دقائق)
      final rem5Time = prayerDateTime.subtract(const Duration(minutes: 5));
      if (rem5Time.isAfter(now)) {
        try {
          await _localNotifications.zonedSchedule(
            id: 2200 + uniquePrayerId,
            title: 'اقتراب أذان $pName 🕌',
            body: 'بقي ٥ دقائق على أذان $pName المبارك',
            scheduledDate: tz.TZDateTime.from(rem5Time, tz.local),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'adhan_approaching_alerts_channel',
                'تنبيهات اقتراب الصلاة والأذان',
                channelDescription: 'إشعارات التذكير قبل موعد الصلاة بـ 10 و 5 دقائق',
                importance: Importance.high,
                priority: Priority.high,
                color: Color(0xFFC09040),
                enableLights: true,
                enableVibration: true,
                icon: '@drawable/ic_notification',
                largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            payload: 'approaching_${p['key']}_5',
          );
        } catch (e) {
          debugPrint('Error scheduling 5m reminder: $e');
        }
      }

      // 3. Exact Adhan Arrival Notification & Native Alarm Clock
      if (isAdhan && prayerDateTime.isAfter(now)) {
        try {
          // Native Exact Alarm (Plays the Holy Adhan audio forcefully via AlarmManager & MediaPlayer Foreground Service)
          if (Platform.isAndroid) {
            final muezzinName = settings.selectedMuezzin;
            final muezzin = MuezzinDownloadService.muezzins.firstWhere(
              (m) => m.id == muezzinName || m.name == muezzinName,
              orElse: () => MuezzinDownloadService.muezzins.first,
            );
            final localPath = await MuezzinDownloadService().getLocalMuezzinPath(muezzin.id);

            await ProximityWakeLockService().scheduleNativePrayerAlarm(
              prayerName: pName,
              triggerTime: prayerDateTime,
              alarmId: 3000 + uniquePrayerId,
              muezzinPath: localPath,
              muezzinName: muezzin.name,
            );
          } else {
            // For non-Android platforms, schedule local notification with Stop action
            await _localNotifications.zonedSchedule(
              id: 4001,
              title: 'أذان $pName المبارك 🕌',
              body: 'حان الآن موعد صلاة $pName',
              scheduledDate: tz.TZDateTime.from(prayerDateTime, tz.local),
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'adhan_live_audio_channel_v6',
                  'أذان الصلاة المباشر',
                  channelDescription: 'إطلاق الأذان المبارك عند دخول وقت الفريضة الشرعي مع زر إيقاف فوري',
                  importance: Importance.max,
                  priority: Priority.max,
                  fullScreenIntent: true,
                  audioAttributesUsage: AudioAttributesUsage.alarm,
                  category: AndroidNotificationCategory.alarm,
                  visibility: NotificationVisibility.public,
                  color: Color(0xFF059669),
                  playSound: false,
                  enableVibration: true,
                  icon: '@drawable/ic_notification',
                  largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
                  actions: [
                    AndroidNotificationAction(
                      'stop_adhan',
                      'إيقاف الأذان ⏹',
                      showsUserInterface: true,
                      cancelNotification: true,
                    ),
                  ],
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.alarmClock,
              payload: 'adhan_${p['key']}',
            );
          }
        } catch (e) {
          debugPrint('Error scheduling exact Adhan: $e');
        }
      }

      // 4. Post-Prayer Taqeebat Notification (5 minutes after Adhan)
      if (isAdhan && settings.taqeebatNotifications) {
        final taqeebatTime = prayerDateTime.add(const Duration(minutes: 5));
        if (taqeebatTime.isAfter(now)) {
          try {
            await _localNotifications.zonedSchedule(
              id: 3500 + uniquePrayerId,
              title: 'تعقيبات صلاة $pName المستحبة 🤲',
              body: 'مضت ٥ دقائق على صلاة $pName • حان وقت التعقيبات والدعاء المأثور',
              scheduledDate: tz.TZDateTime.from(taqeebatTime, tz.local),
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'taqeebat_channel',
                  'تعقيبات الصلاة',
                  channelDescription: 'تذكير بتعقيبات الصلاة بعد انتهاء الأذان بخمس دقائق',
                  importance: Importance.high,
                  priority: Priority.high,
                  color: Color(0xFF059669),
                  icon: '@drawable/ic_notification',
                  largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
                  actions: [
                    AndroidNotificationAction(
                      'open_taqeebat',
                      'قراءة التعقيب 📖',
                      showsUserInterface: true,
                    ),
                  ],
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.alarmClock,
              payload: 'taqeebat_$pName',
            );
          } catch (e) {
            debugPrint('Error scheduling Taqeebat reminder: $e');
          }
        }
      }
    }
  }

  /// 4. Approaching Prayer Notification (10 minutes and 5 minutes before Prayer)
  Future<void> showApproachingPrayerNotification(String prayerName, int minutesRemaining) async {
    await init();
    if (!_isInitialized) return;

    final arabicMinutes = HijriDateService.toArabicDigits(minutesRemaining);
    const title = 'اقتراب وقت الصلاة';
    final body = 'بقي $arabicMinutes دقائق على أذان $prayerName';

    const androidDetails = AndroidNotificationDetails(
      'adhan_approaching_alerts_channel',
      'تنبيهات اقتراب الصلاة والأذان',
      channelDescription: 'إشعارات التذكير قبل موعد الصلاة بـ 10 و 5 دقائق',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFC09040),
      enableLights: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _localNotifications.show(
        id: 2000 + minutesRemaining,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'approaching_${prayerName}_$minutesRemaining',
      );
    } catch (e) {
      debugPrint('Error showing approaching prayer notification: $e');
    }
  }

  /// 5. Live Adhan at Exact Prayer Time: Stops other media and plays the Holy Adhan
  Future<void> playAdhanAndNotify(String prayerName, {String? muezzinName}) async {
    // Delegate to AdhanSchedulerService for alarm audio context and local file playback
    await AdhanSchedulerService().playAdhan(
      prayerName: prayerName,
      muezzinId: muezzinName,
    );
  }

  /// Show Adhan Live Notification with Stop Action
  Future<void> showAdhanNotification({
    required String prayerName,
    required String muezzinName,
  }) async {
    await init();
    if (!_isInitialized) return;

    final title = 'أذان $prayerName المبارك 🕌';
    final body = 'حان الآن موعد صلاة $prayerName';

    const androidDetails = AndroidNotificationDetails(
      'adhan_live_audio_channel_v6',
      'أذان الصلاة المباشر',
      channelDescription: 'إطلاق الأذان المبارك عند دخول وقت الفريضة الشرعي مع زر إيقاف فوري',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: true,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      color: Color(0xFF059669),
      enableLights: true,
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
      actions: [
        AndroidNotificationAction(
          'lower_adhan_volume',
          'خفض الصوت 🔉',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'stop_adhan',
          'إيقاف الأذان ⏹',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _localNotifications.show(
        id: 4001,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'adhan_$prayerName',
      );
    } catch (e) {
      debugPrint('Error showing Adhan notification: $e');
    }
  }

  /// Stop Adhan playback
  Future<void> stopAdhan() async {
    try {
      if (Platform.isAndroid) {
        await ProximityWakeLockService().stopNativeAdhan();
      }
      await AdhanSchedulerService().stopAdhan();
      await AudioPlayerService().stop();
      await cancelAdhanNotifications();
    } catch (_) {}
  }

  /// Cancel all active or pending Adhan notifications
  Future<void> cancelAdhanNotifications() async {
    try {
      if (_isInitialized) {
        await _localNotifications.cancel(id: 4001);
        for (int i = 3000; i <= 3006; i++) {
          await _localNotifications.cancel(id: i);
        }
      }
    } catch (_) {}
  }

  /// Cancel Sticky Prayer Notification
  Future<void> cancelStickyPrayerNotification() async {
    try {
      await ProximityWakeLockService().cancelCustomPrayerNotification();
      if (_isInitialized) {
        await _localNotifications.cancel(id: 1003);
      }
    } catch (_) {}
  }

  /// Show instant general notification
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    if (!_isInitialized) return;
    const androidDetails = AndroidNotificationDetails(
      'instant_notifications_channel',
      'تنبيهات فورية',
      channelDescription: 'قناة إرسال التنبيهات الفورية للمواقيت والأذان',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF059669),
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    try {
      await _localNotifications.show(
        id: 4000 + Random().nextInt(1000),
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  /// Cancel Quran Verses notification and timer permanently
  void setQuranNotificationActive(bool active) {
    _quranTimer?.cancel();
    _quranTimer = null;
    cancelQuranNotification();
  }

  /// Permanently cancel any Quran verse notification from the notification tray
  Future<void> cancelQuranNotification() async {
    _quranTimer?.cancel();
    _quranTimer = null;
    try {
      await _localNotifications.cancel(id: 1001);
      await _localNotifications.cancel(id: 1002);
      await ProximityWakeLockService().cancelQuranNotification();
    } catch (_) {}
  }

  /// إرسال إشعار فوري عند توفر تحديث جديد للتطبيق
  Future<void> showAppUpdateNotification({
    required String newVersion,
    required String changelog,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'app_updates_channel',
      'تحديثات تطبيق نور العترة',
      channelDescription: 'إشعارات توفر إصدارات وتحديثات جديدة للتطبيق',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF0F766E),
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
      showWhen: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    try {
      await _localNotifications.show(
        id: 99999,
        title: 'تحديث جديد متوفر: تطبيق نور العترة ($newVersion) ✨',
        body: 'يتوفر إصدار جديد يتضمن تحسينات ومزايا جديدة. اضغط للترقية الفورية.',
        notificationDetails: notificationDetails,
        payload: 'app_update',
      );
    } catch (e) {
      debugPrint('Error showing app update notification: $e');
    }
  }
}
