import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HijriDateService {
  // Primary Hijri repository by user (moshraheem-sudo/hijri)
  static const String hijriRepoRawUrl =
      'https://raw.githubusercontent.com/moshraheem-sudo/hijri/main/hijri.json';

  /// Notifier to instantly inform UI components when the Hijri date has been synced or modified
  static final ValueNotifier<int> dateNotifier = ValueNotifier<int>(0);

  // Verified Shia anchor from repository (Default initial anchor: 1 Rabi' al-Thani 1448 = 2026-09-13)
  static int _anchorHijriDay = 1;
  static int _anchorHijriMonth = 4;
  static int _anchorHijriYear = 1448;
  static DateTime _anchorGregorianDate = DateTime(2026, 9, 13);

  static int _onlineAdjustment = 0;
  static bool _hasLoadedStoredAdjustment = false;

  static const List<String> weekdaysAr = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد'
  ];

  static const List<String> monthsGregorianAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  static const List<String> monthsHijriAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة'
  ];

  /// Loads stored online Hijri adjustment and verified anchor from local storage
  static Future<void> loadStoredAdjustment() async {
    if (_hasLoadedStoredAdjustment) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('hijri_anchor_day')) {
        _anchorHijriDay = prefs.getInt('hijri_anchor_day') ?? 1;
        _anchorHijriMonth = prefs.getInt('hijri_anchor_month') ?? 4;
        _anchorHijriYear = prefs.getInt('hijri_anchor_year') ?? 1448;
        final gStr = prefs.getString('hijri_anchor_gregorian');
        if (gStr != null) {
          final dt = DateTime.tryParse(gStr);
          if (dt != null) _anchorGregorianDate = dt;
        }
      }
      if (prefs.containsKey('hijri_online_offset')) {
        _onlineAdjustment = prefs.getInt('hijri_online_offset') ?? 0;
      }
      _hasLoadedStoredAdjustment = true;
    } catch (e) {
      debugPrint('Error loading stored Hijri adjustment: $e');
    }
  }

  /// Calculates Hijri date based on the verified GitHub repository anchor
  static Map<String, dynamic> _calculateFromAnchor(DateTime dt, int adjustment) {
    final target = DateTime(dt.year, dt.month, dt.day);
    final anchor = DateTime(
      _anchorGregorianDate.year,
      _anchorGregorianDate.month,
      _anchorGregorianDate.day,
    );

    int diffDays = target.difference(anchor).inDays + adjustment;

    int hDay = _anchorHijriDay;
    int hMonth = _anchorHijriMonth;
    int hYear = _anchorHijriYear;

    if (diffDays >= 0) {
      hDay += diffDays;
      while (true) {
        final daysInMonth = getDaysInHijriMonth(hYear, hMonth);
        if (hDay <= daysInMonth) break;
        hDay -= daysInMonth;
        hMonth++;
        if (hMonth > 12) {
          hMonth = 1;
          hYear++;
        }
      }
    } else {
      hDay += diffDays;
      while (hDay < 1) {
        hMonth--;
        if (hMonth < 1) {
          hMonth = 12;
          hYear--;
        }
        final daysInPrevMonth = getDaysInHijriMonth(hYear, hMonth);
        hDay += daysInPrevMonth;
      }
    }

    final safeMonth = (hMonth >= 1 && hMonth <= 12) ? hMonth : 4;
    final weekday = weekdaysAr[dt.weekday - 1];
    final monthName = monthsHijriAr[safeMonth - 1];

    return {
      'day': hDay,
      'month': safeMonth,
      'monthName': monthName,
      'year': hYear,
      'weekday': weekday,
      'formatted': '$weekday، $hDay $monthName $hYear هـ',
      'shortFormatted': '$hDay $monthName $hYear هـ',
    };
  }

  /// Returns the current or target Hijri date using official synced Shia calculations
  static Map<String, dynamic> getHijriDate([DateTime? date]) {
    final dt = date ?? DateTime.now();
    return _calculateFromAnchor(dt, _onlineAdjustment);
  }

  /// Checks if current or provided date is on days 28, 29, 30, or 1 of the Hijri month
  static bool isCriticalTransitionDay([DateTime? date]) {
    final current = getHijriDate(date);
    final day = current['day'] as int? ?? 1;
    return day == 28 || day == 29 || day == 30 || day == 1;
  }

  /// Checks and executes mandatory synchronization:
  /// 1. Always on first install / application launch.
  /// 2. Always on the critical transition days (28, 29, 30, and 1) of every Hijri month.
  static Future<void> checkAndEnforceMandatorySync() async {
    try {
      await loadStoredAdjustment();
      final prefs = await SharedPreferences.getInstance();
      final hasSyncedFirstRun = prefs.getBool('hijri_first_run_synced') ?? false;

      // Rule 1: First install / launch mandatory sync
      if (!hasSyncedFirstRun) {
        debugPrint('[HijriDateService] First run detected: executing mandatory sync...');
        final success = await syncHijriFromRepository(force: true);
        if (success) {
          await prefs.setBool('hijri_first_run_synced', true);
        }
        return;
      }

      // Rule 2: Mandatory auto-sync on days 28, 29, 30, and 1
      if (isCriticalTransitionDay()) {
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final lastSyncDate = prefs.getString('hijri_last_transition_sync');
        if (lastSyncDate != todayStr) {
          debugPrint('[HijriDateService] Critical transition day detected: executing mandatory sync...');
          final success = await syncHijriFromRepository(force: true);
          if (success) {
            await prefs.setString('hijri_last_transition_sync', todayStr);
          }
        }
      }
    } catch (e) {
      debugPrint('[HijriDateService] Error in checkAndEnforceMandatorySync: $e');
    }
  }

  /// Automatically synchronizes the Hijri calendar date from GitHub repository & shrines
  static Future<bool> syncHijriFromRepository({bool force = false}) async {
    try {
      await loadStoredAdjustment();

      // 1. Primary: Official GitHub Repository hijri.json (moshraheem-sudo/hijri)
      // Uses cache-busting timestamp and no-cache headers to ensure freshly verified data
      try {
        final cacheBusterUrl = Uri.parse(
          '$hijriRepoRawUrl?t=${DateTime.now().millisecondsSinceEpoch}',
        );
        final res = await http.get(
          cacheBusterUrl,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
          final data = json.decode(res.body);
          final hDay = data['hijri_day'] as int?;
          final hMonth = data['hijri_month'] as int?;
          final hYear = data['hijri_year'] as int?;
          final gDateStr = data['gregorian_date'] as String?;
          final gAnchorStr = data['gregorian_anchor_date'] as String?;

          if (hDay != null && hMonth != null && hYear != null) {
            if (gDateStr != null && DateTime.tryParse(gDateStr) != null) {
              final parsedGDate = DateTime.tryParse(gDateStr)!;
              await _saveRepoAnchor(hDay, hMonth, hYear, parsedGDate);
              debugPrint('Hijri date synced from GitHub repo: $hDay/$hMonth/$hYear (Date: $gDateStr)');
              return true;
            } else if (gAnchorStr != null && DateTime.tryParse(gAnchorStr) != null) {
              final parsedAnchor = DateTime.tryParse(gAnchorStr)!;
              await _saveRepoAnchor(1, hMonth, hYear, parsedAnchor);
              debugPrint('Hijri date synced from GitHub repo anchor: 1/$hMonth/$hYear (Anchor: $gAnchorStr)');
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching Hijri repo: $e');
      }

      // 2. Secondary: Official AlKafeel Holy Shrine API
      try {
        final uri = Uri.parse(
          'https://hq.alkafeel.net/Api/init/init.php?v=jsonPrayerTimes&timezone=+3&long=44.0228&lati=32.6143',
        );
        final res = await http.get(uri, headers: {
          'User-Agent': 'HaqybatAlMomen/1.0 (Android; Mobile)',
          'Accept': 'application/json, text/plain, */*',
        }).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200 && res.body.startsWith('{')) {
          final data = json.decode(res.body);
          final rawDate = (data['date'] ?? data['hijriDate'])?.toString().trim();
          if (rawDate != null && rawDate.isNotEmpty) {
            final match = RegExp(r'(\d{1,2})\s+([^\d]+)\s+(\d{4})').firstMatch(rawDate);
            if (match != null) {
              final d = int.tryParse(match.group(1)!);
              final mName = match.group(2)!.trim();
              final y = int.tryParse(match.group(3)!);
              int m = 4;
              for (int i = 0; i < monthsHijriAr.length; i++) {
                if (mName.contains(monthsHijriAr[i]) || (i == 3 && mName.contains('الثاني'))) {
                  m = i + 1;
                  break;
                }
              }
              if (d != null && y != null && d >= 1 && d <= 30) {
                await _saveRepoAnchor(d, m, y, DateTime.now());
                debugPrint('Hijri date synced from AlKafeel: $d/$m/$y');
                return true;
              }
            }
          }
        }
      } catch (_) {}

      // 3. Tertiary: Aladhan Shia Ithna-Ashari API
      try {
        final now = DateTime.now();
        final uri = Uri.parse('https://api.aladhan.com/v1/gToH/${now.day}-${now.month}-${now.year}?method=0');
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final hijri = data['data']['hijri'];
          final remoteDay = int.tryParse(hijri['day'].toString());
          final remoteMonth = int.tryParse(hijri['month']['number'].toString());
          final remoteYear = int.tryParse(hijri['year'].toString());
          if (remoteDay != null && remoteMonth != null && remoteYear != null) {
            await _saveRepoAnchor(remoteDay, remoteMonth, remoteYear, now);
            debugPrint('Hijri date synced from Aladhan API: $remoteDay/$remoteMonth/$remoteYear');
            return true;
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error syncing Hijri date from repository: $e');
    }
    return false;
  }

  static Future<void> _saveRepoAnchor(int hDay, int hMonth, int hYear, DateTime gDate) async {
    _anchorHijriDay = hDay;
    _anchorHijriMonth = hMonth;
    _anchorHijriYear = hYear;
    _anchorGregorianDate = gDate;
    _onlineAdjustment = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hijri_anchor_day', hDay);
    await prefs.setInt('hijri_anchor_month', hMonth);
    await prefs.setInt('hijri_anchor_year', hYear);
    await prefs.setString(
      'hijri_anchor_gregorian',
      '${gDate.year}-${gDate.month.toString().padLeft(2, '0')}-${gDate.day.toString().padLeft(2, '0')}',
    );
    await prefs.setInt('hijri_online_offset', 0);
    dateNotifier.value++;
  }

  static void applyRemoteHijriDay(int targetRemoteDay) async {
    final now = DateTime.now();
    final cur = getHijriDate(now);
    final curDay = cur['day'] as int;
    final diff = targetRemoteDay - curDay;
    if (diff != 0) {
      _onlineAdjustment += diff;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hijri_online_offset', _onlineAdjustment);
      debugPrint('Hijri day adjusted to $targetRemoteDay (offset: $_onlineAdjustment)');
    }
  }

  static String getGregorianFormatted([DateTime? date]) {
    final dt = date ?? DateTime.now();
    final weekday = weekdaysAr[dt.weekday - 1];
    final monthName = monthsGregorianAr[dt.month - 1];
    return '$weekday، ${dt.day} $monthName ${dt.year} م';
  }

  /// Converts an integer or string with digits to Arabic-Indic digits (e.g. 15 -> ١٥)
  static String toArabicDigits(dynamic value) {
    if (value == null) return '';
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? digits[digit] : char;
    }).join();
  }

  /// Calculates the start date of Ramadan for a given Hijri year,
  /// dynamically connected to the current active Hijri day and calendar progression.
  /// Computes according to 30 days standard from the active Hijri date so that any change
  /// or adjustment in the Hijri date automatically reflects in Ramadan's start date.
  static DateTime getRamadanStartDate(int targetHijriYear) {
    final now = DateTime.now();
    final todayG = DateTime(now.year, now.month, now.day);
    final todayH = getHijriDate(now);
    final int curYear = (todayH['year'] as int?) ?? targetHijriYear;
    final int curMonth = (todayH['month'] as int?) ?? 4;
    final int curDay = (todayH['day'] as int?) ?? 1;

    int daysFromTodayToRamadan = 0;

    if (curMonth == 9) {
      // Currently inside Ramadan: 1 Ramadan was (curDay - 1) days ago
      daysFromTodayToRamadan = -(curDay - 1);
    } else if (curMonth < 9) {
      // Before Ramadan: calculate remaining days in current month to 30 days
      int daysLeftInCurMonth = 30 - curDay;
      if (daysLeftInCurMonth < 0) daysLeftInCurMonth = 0;
      daysFromTodayToRamadan += daysLeftInCurMonth;

      // Add intermediate full months up to month 8 (each 30 days as requested)
      for (int m = curMonth + 1; m < 9; m++) {
        daysFromTodayToRamadan += 30;
      }
      // Plus 1 day to land on the 1st of Ramadan
      daysFromTodayToRamadan += 1;
    } else {
      // After Ramadan in the current Hijri year:
      int daysLeftInCurMonth = 30 - curDay;
      if (daysLeftInCurMonth < 0) daysLeftInCurMonth = 0;
      daysFromTodayToRamadan += daysLeftInCurMonth;
      for (int m = curMonth + 1; m <= 12; m++) {
        daysFromTodayToRamadan += 30;
      }
      // Add months 1 through 8 of next year:
      daysFromTodayToRamadan += (8 * 30) + 1;
    }

    // Account for target year difference (past or future years)
    int yearDiff = targetHijriYear - curYear;
    if (curMonth > 9) {
      yearDiff -= 1;
    }

    return todayG.add(Duration(days: daysFromTodayToRamadan + (yearDiff * 354)));
  }

  /// Converts a Hijri date (year, month, day) to Gregorian DateTime
  static DateTime hijriToGregorian(int hYear, int hMonth, int hDay) {
    if (hMonth == 9) {
      final ramadan1 = getRamadanStartDate(hYear);
      return ramadan1.add(Duration(days: hDay - 1));
    }

    final double totalDays = (hYear - 1) * 354.367068 + (hMonth - 1) * 29.530589 + (hDay - 1);
    final DateTime approxDate = DateTime(622, 7, 16).add(Duration(days: totalDays.round() - 2));

    for (int offset = -4; offset <= 4; offset++) {
      final DateTime candidate = approxDate.add(Duration(days: offset));
      final h = getHijriDate(candidate);
      if (h['year'] == hYear && h['month'] == hMonth && h['day'] == hDay) {
        return candidate;
      }
    }
    return approxDate;
  }

  /// Determines if a Hijri year is a leap year (355 days instead of 354)
  static bool isHijriLeapYear(int year) {
    const leapYears = [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29];
    return leapYears.contains((year - 1) % 30 + 1);
  }

  /// Gets the total number of days in a Hijri month (29 or 30 days)
  static int getDaysInHijriMonth(int hYear, int hMonth) {
    const standardDays = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    if (hMonth >= 1 && hMonth <= 12) {
      if (hMonth == 12 && isHijriLeapYear(hYear)) return 30;
      return standardDays[hMonth - 1];
    }
    return 30;
  }

  /// Returns organized daily deeds according to the day of week
  static List<Map<String, String>> getDeedsForDay([DateTime? date]) {
    final dt = date ?? DateTime.now();
    switch (dt.weekday) {
      case DateTime.friday: // الجمعة
        return [
          {
            'title': 'دعاء يوم الجمعة',
            'category': 'dailyPrayers',
            'desc': 'المأثور عن الإمام السجاد عليه السلام المستحب قراءته صبيحة الجمعة',
          },
          {
            'title': 'زيارة يوم الجمعة',
            'category': 'ziyaratsOfDays',
            'desc': 'زيارة صاحب العصر والزمان الإمام المهدي عجل الله تعالى فرجه الشريف',
          },
          {
            'title': 'دعاء الندبة',
            'category': 'generalPrayers',
            'desc': 'يستحب قراءته في الأعياد الأربعة ويوم الجمعة لطلب الفرج المبارك',
          },
          {
            'title': 'دعاء السمات',
            'category': 'generalPrayers',
            'desc': 'يستحب قراءته في الساعة الأخيرة من نهار يوم الجمعة',
          },
          {
            'title': 'تسبيح يوم الجمعة',
            'category': 'tasbeehat',
            'desc': 'تسبيح الله والحمد والصلاة على النبي وآله الطيبين الطاهرين',
          },
        ];

      case DateTime.saturday: // السبت
        return [
          {
            'title': 'دعاء يوم السبت',
            'category': 'dailyPrayers',
            'desc': 'المأثور عن الإمام السجاد عليه السلام',
          },
          {
            'title': 'زيارة يوم السبت',
            'category': 'ziyaratsOfDays',
            'desc': 'زيارة سيد المرسلين النبي الأكرم محمد صلى الله عليه وآله',
          },
          {
            'title': 'تسبيح يوم السبت',
            'category': 'tasbeehat',
            'desc': 'التسبيح المستحب ليوم السبت',
          },
        ];

      case DateTime.sunday: // الأحد
        return [
          {
            'title': 'دعاء يوم الأحد',
            'category': 'dailyPrayers',
            'desc': 'المأثور عن الإمام السجاد عليه السلام',
          },
          {
            'title': 'زيارة يوم الأحد',
            'category': 'ziyaratsOfDays',
            'desc': 'زيارة أمير المؤمنين علي وفاطمة الزهراء عليهما السلام',
          },
          {
            'title': 'تسبيح يوم الأحد',
            'category': 'tasbeehat',
            'desc': 'التسبيح المستحب ليوم الأحد',
          },
        ];

      case DateTime.monday: // الاثنين
        return [
          {
            'title': 'دعاء يوم الاثنين',
            'category': 'dailyPrayers',
            'desc': 'المأثور عن الإمام السجاد عليه السلام',
          },
          {
            'title': 'زيارة يوم الاثنين',
            'category': 'ziyaratsOfDays',
            'desc': 'زيارة الإمام الحسن المجتبى والإمام الحسين الشهيد عليهما السلام',
          },
          {
            'title': 'تسبيح يوم الاثنين',
            'category': 'tasbeehat',
            'desc': 'التسبيح المستحب ليوم الاثنين',
          },
        ];

      case DateTime.tuesday: // الثلاثاء
        return [
          {
            'title': 'دعاء يوم الثلاثاء',
            'category': 'dailyPrayers',
            'desc': 'المأثور عن الإمام السجاد عليه السلام',
          },
          {
            'title': 'زيارة يوم الثلاثاء',
            'category': 'ziyaratsOfDays',
            'desc': 'زيارة الأئمة زين العابدين والباقر والصادق عليهم السلام',
          },
          {
            'title': 'دعاء التوسل',
            'category': 'generalPrayers',
            'desc': 'المستحب قراءته مساء كل ثلاثاء لقضاء الحوائج',
          },
          {
            'title': 'تسبيح يوم الثلاثاء',
            'category': 'tasbeehat',
            'desc': 'التسبيح المستحب ليوم الثلاثاء',
          },
        ];

      case DateTime.wednesday: // الأربعاء
        return [
          {
            'title': 'دعاء يوم الأربعاء',
            'category': 'dailyPrayers',
            'desc': 'المأثور عن الإمام السجاد عليه السلام',
          },
          {
            'title': 'زيارة يوم الأربعاء',
            'category': 'ziyaratsOfDays',
            'desc': 'زيارة الأئمة الكاظم والرضا والجواد والهادي عليهم السلام',
          },
          {
            'title': 'تسبيح يوم الأربعاء',
            'category': 'tasbeehat',
            'desc': 'التسبيح المستحب ليوم الأربعاء',
          },
        ];

      case DateTime.thursday: // الخميس
        return [
          {
            'title': 'دعاء يوم الخميس',
            'category': 'dailyPrayers',
            'desc': 'المأثور عن الإمام السجاد عليه السلام',
          },
          {
            'title': 'زيارة يوم الخميس',
            'category': 'ziyaratsOfDays',
            'desc': 'زيارة الإمام الحسن العسكري عليه السلام',
          },
          {
            'title': 'دعاء كميل',
            'category': 'generalPrayers',
            'desc': 'دعاء أمير المؤمنين عليه السلام المستحب في ليلة الجمعة',
          },
          {
            'title': 'تسبيح يوم الخميس',
            'category': 'tasbeehat',
            'desc': 'التسبيح المستحب ليوم الخميس',
          },
        ];

      default:
        return [
          {
            'title': 'دعاء اليوم',
            'category': 'dailyPrayers',
            'desc': 'أدعية الأيام المأثورة',
          },
        ];
    }
  }
}
