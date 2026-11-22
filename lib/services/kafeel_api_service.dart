import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/prayer_times.dart';
import '../models/city_location.dart';
import 'hijri_date_service.dart';
import 'settings_controller.dart';

class KafeelApiService {
  static const String kafeelBaseUrl = 'https://hq.alkafeel.net/Api/init/init.php';

  /// Fetches prayer times from AlKafeel Official API (العتبة العباسية المقدسة / مركز الكفيل),
  /// and utilizes high-precision Shia Ja'afari astronomical engine as offline/dynamic provider.
  static Future<PrayerTimesModel> getPrayerTimes(CityLocation city, {DateTime? targetDate}) async {
    final date = targetDate ?? DateTime.now();
    final settings = SettingsController();
    final calcMethod = settings.calculationMethod;
    final midnightMethod = settings.midnightMethod;

    // 1. Format Timezone (e.g. +3, +3.5, -4)
    String tzParam = '+3';
    double tzHours = 3.0;
    if (city.timezone.isNotEmpty) {
      String cleanTz = city.timezone.trim();
      if (cleanTz.startsWith('+') || cleanTz.startsWith('-')) {
        tzParam = cleanTz.split(':').first;
      } else {
        tzParam = '+$cleanTz'.split(':').first;
      }
      tzHours = double.tryParse(tzParam) ?? 3.0;
    }

    // 2. If 'kafeel' method is active and online, try fetching official AlKafeel API
    if (calcMethod == 'kafeel') {
      try {
        final uri = Uri.parse(kafeelBaseUrl).replace(queryParameters: {
          'v': 'jsonPrayerTimes',
          'timezone': tzParam,
          'lati': city.latitude.toString(),
          'long': city.longitude.toString(),
        });

        debugPrint('Fetching prayer times from AlKafeel: $uri');

        final response = await http.get(
          uri,
          headers: {
            'User-Agent': 'HaqybatAlMomen/1.0 (Android; Mobile)',
            'Accept': 'application/json, text/plain, */*',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 && response.body.trim().isNotEmpty && response.body.trim().startsWith('{')) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            final fajr = data['fajir'] ?? data['fajr'] ?? data['Fajr'] ?? '04:27';
            final sunrise = data['sunrise'] ?? data['shurooq'] ?? data['Sunrise'] ?? '05:49';
            final dhuhr = data['doher'] ?? data['dhuhr'] ?? data['Dhuhr'] ?? '11:49';
            final sunset = data['sunset'] ?? data['ghuroob'] ?? data['Sunset'] ?? '17:47';
            final maghrib = data['maghrib'] ?? data['Maghrib'] ?? '18:02';

            final imsak = data['imsak'] ?? data['Imsak'] ?? _subtractMinutes(fajr, 12);
            final asr = data['asr'] ?? data['Asr'] ?? _addMinutes(dhuhr, 203);
            final isha = data['isha'] ?? data['Isha'] ?? _addMinutes(maghrib, 47);
            
            final midnight = midnightMethod == 'sunrise'
                ? _calculateMidnightToSunrise(sunset, sunrise)
                : _calculateMidnightToFajr(sunset, fajr);

            final rawHijriDate = data['date'] ?? data['hijriDate'] ?? '';
            final formattedHijri = _formatAlKafeelHijriDate(rawHijriDate);

            _trySyncHijriFromKafeel(rawHijriDate);

            return _applyUserOffsets(
              PrayerTimesModel(
                imsak: imsak,
                fajr: fajr,
                sunrise: sunrise,
                dhuhr: dhuhr,
                asr: asr,
                sunset: sunset,
                maghrib: maghrib,
                isha: isha,
                midnight: midnight,
                dateGregorian: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                dateHijri: formattedHijri.isNotEmpty
                    ? formattedHijri
                    : (HijriDateService.getHijriDate(date)['shortFormatted'] as String? ?? ''),
                source: 'مركز الكفيل للثقافة والإعلام (العتبة العباسية المقدسة)',
              ),
              settings,
            );
          }
        }
      } catch (e) {
        debugPrint('AlKafeel API fetch error or timeout: $e. Using high-precision Jaafari engine.');
      }
    }

    // 3. High-Precision Shia Ja'afari Astronomical Calculation Engine
    final calculated = calculateJaafariPrayerTimes(
      date: date,
      latitude: city.latitude,
      longitude: city.longitude,
      timezone: tzHours,
      calcMethod: calcMethod,
      midnightMethod: midnightMethod,
    );

    return _applyUserOffsets(calculated, settings);
  }

  /// High-precision Shia Ja'afari Astronomical Solar Engine (مركز الكفيل / فقه أهل البيت ع)
  static PrayerTimesModel calculateJaafariPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required double timezone,
    required String calcMethod,
    required String midnightMethod,
  }) {
    // Determine angles according to selected Ja'afari method
    double fajrAngle = 18.0;   // Sistani / Alkafeel (Iraq standard)
    double maghribAngle = 4.3; // Eastern redness disappearance (ذهاب الحمرة المشرقية)
    String sourceName = 'حساب فلكي جعفري (مركز الكفيل / السيد السيستاني)';

    if (calcMethod == 'tehran') {
      fajrAngle = 17.7;
      maghribAngle = 4.5;
      sourceName = 'حساب فلكي جعفري (جامعة طهران)';
    } else if (calcMethod == 'lewa_qom') {
      fajrAngle = 16.0;
      maghribAngle = 4.0;
      sourceName = 'حساب فلكي جعفري (معهد ليفا، قم)';
    }

    final d = _julianDay(date.year, date.month, date.day) - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final dd = _arcsin(_sin(e) * _sin(l));
    final ra = _fixHour(_arctan2(_cos(e) * _sin(l), _cos(l)) / 15.0);
    final eqt = q / 15.0 - ra;

    // True Solar Noon (الزوال الفلكي الشرعي لوقت صلاة الظهر)
    final solarNoon = _fixHour(12.0 + timezone - longitude / 15.0 - eqt);
    final dhuhrHours = solarNoon;

    // Sunrise & Sunset (-0.8333 degrees for atmospheric refraction and sun radius)
    const sunAlt = -0.8333;
    final haSun = _hourAngle(sunAlt, latitude, dd);
    final sunriseHours = _fixHour(solarNoon - haSun);
    final sunsetHours = _fixHour(solarNoon + haSun);

    // Fajr (Dawn at 18 degrees standard for Iraq / Sistani / Al-Kafeel)
    final haFajr = _hourAngle(-fajrAngle, latitude, dd);
    final fajrHours = _fixHour(solarNoon - haFajr);

    // Maghrib (ذهاب الحمرة المشرقية المعتمدة في تقويم العتبات المقدسة ومكتب السيد السيستاني)
    final maghribHours = (calcMethod == 'tehran')
        ? _fixHour(solarNoon + _hourAngle(-maghribAngle, latitude, dd))
        : _fixHour(sunsetHours + (15.0 / 60.0));

    // Asr (وقت صلاة العصر عند بلوغ الظل مثل الشاخص فلكياً)
    final noonAlt = 90.0 - (latitude - dd).abs();
    final noonShadow = 1.0 / math.tan(noonAlt * math.pi / 180.0);
    final asrAlt = math.atan(1.0 / (noonShadow + 1.0)) * 180.0 / math.pi;
    final haAsr = _hourAngle(asrAlt, latitude, dd);
    final asrHours = _fixHour(solarNoon + haAsr);

    // Isha (فضيلة صلاة العشاء بعد غياب الشفق المعتمد بـ 48 دقيقة بعد المغرب)
    final ishaHours = (calcMethod == 'tehran')
        ? _fixHour(solarNoon + _hourAngle(-14.0, latitude, dd))
        : _fixHour(maghribHours + (48.0 / 60.0));

    // Midnight calculation (نصف الليل الشرعي: منتصف ما بين الغروب وطلوع الفجر)
    double midnightHours;
    if (midnightMethod == 'sunrise') {
      final nightDuration = (sunriseHours + 24.0) - sunsetHours;
      midnightHours = (sunsetHours + nightDuration / 2.0) % 24.0;
    } else {
      final nightDuration = (fajrHours + 24.0) - sunsetHours;
      midnightHours = (sunsetHours + nightDuration / 2.0) % 24.0;
    }

    final fajrStr = _hoursToTimeStr(fajrHours);
    final sunriseStr = _hoursToTimeStr(sunriseHours);
    final dhuhrStr = _hoursToTimeStr(dhuhrHours);
    final asrStr = _hoursToTimeStr(asrHours);
    final sunsetStr = _hoursToTimeStr(sunsetHours);
    final maghribStr = _hoursToTimeStr(maghribHours);
    final ishaStr = _hoursToTimeStr(ishaHours);
    final midnightStr = _hoursToTimeStr(midnightHours);
    final imsakStr = _subtractMinutes(fajrStr, 12);

    return PrayerTimesModel(
      imsak: imsakStr,
      fajr: fajrStr,
      sunrise: sunriseStr,
      dhuhr: dhuhrStr,
      asr: asrStr,
      sunset: sunsetStr,
      maghrib: maghribStr,
      isha: ishaStr,
      midnight: midnightStr,
      dateGregorian: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      dateHijri: HijriDateService.getHijriDate(date)['shortFormatted'] as String? ?? '',
      source: sourceName,
    );
  }

  static PrayerTimesModel _applyUserOffsets(PrayerTimesModel model, SettingsController settings) {
    final offsets = settings.prayerOffsets;
    return PrayerTimesModel(
      imsak: _addMinutes(model.imsak, offsets['fajr'] ?? 0),
      fajr: _addMinutes(model.fajr, offsets['fajr'] ?? 0),
      sunrise: _addMinutes(model.sunrise, offsets['sunrise'] ?? 0),
      dhuhr: _addMinutes(model.dhuhr, offsets['dhuhr'] ?? 0),
      asr: _addMinutes(model.asr, offsets['asr'] ?? 0),
      sunset: _addMinutes(model.sunset, offsets['sunset'] ?? 0),
      maghrib: _addMinutes(model.maghrib, offsets['maghrib'] ?? 0),
      isha: _addMinutes(model.isha, offsets['isha'] ?? 0),
      midnight: _addMinutes(model.midnight, offsets['midnight'] ?? 0),
      dateGregorian: model.dateGregorian,
      dateHijri: model.dateHijri,
      source: model.source,
    );
  }

  static double _julianDay(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() + (30.6001 * (month + 1)).floor() + day + b - 1524.5;
  }

  static double _hourAngle(double alt, double lat, double decl) {
    final cosHa = (_sin(alt) - _sin(lat) * _sin(decl)) / (_cos(lat) * _cos(decl));
    if (cosHa > 1.0) return 0.0;
    if (cosHa < -1.0) return 12.0;
    return _arccos(cosHa) / 15.0;
  }

  static double _sin(double d) => math.sin(d * math.pi / 180.0);
  static double _cos(double d) => math.cos(d * math.pi / 180.0);
  static double _arcsin(double x) => math.asin(x.clamp(-1.0, 1.0)) * 180.0 / math.pi;
  static double _arccos(double x) => math.acos(x.clamp(-1.0, 1.0)) * 180.0 / math.pi;
  static double _arctan2(double y, double x) => math.atan2(y, x) * 180.0 / math.pi;
  static double _fixAngle(double a) => (a % 360.0 + 360.0) % 360.0;
  static double _fixHour(double h) => (h % 24.0 + 24.0) % 24.0;

  static String _hoursToTimeStr(double hours) {
    int totalMinutes = (hours * 60.0).round() % (24 * 60);
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _calculateMidnightToFajr(String sunsetStr, String fajrStr) {
    try {
      final sParts = sunsetStr.split(':');
      final fParts = fajrStr.split(':');
      if (sParts.length >= 2 && fParts.length >= 2) {
        int sH = int.parse(sParts[0].trim());
        int sM = int.parse(sParts[1].trim());
        int fH = int.parse(fParts[0].trim());
        int fM = int.parse(fParts[1].trim());

        int sTotal = sH * 60 + sM;
        int fTotal = fH * 60 + fM + (24 * 60);

        int midTotal = ((sTotal + fTotal) ~/ 2) % (24 * 60);
        final mH = (midTotal ~/ 60).toString().padLeft(2, '0');
        final mM = (midTotal % 60).toString().padLeft(2, '0');
        return '$mH:$mM';
      }
    } catch (_) {}
    return '23:07';
  }

  static String _calculateMidnightToSunrise(String sunsetStr, String sunriseStr) {
    try {
      final sParts = sunsetStr.split(':');
      final rParts = sunriseStr.split(':');
      if (sParts.length >= 2 && rParts.length >= 2) {
        int sH = int.parse(sParts[0].trim());
        int sM = int.parse(sParts[1].trim());
        int rH = int.parse(rParts[0].trim());
        int rM = int.parse(rParts[1].trim());

        int sTotal = sH * 60 + sM;
        int rTotal = rH * 60 + rM + (24 * 60);

        int midTotal = ((sTotal + rTotal) ~/ 2) % (24 * 60);
        final mH = (midTotal ~/ 60).toString().padLeft(2, '0');
        final mM = (midTotal % 60).toString().padLeft(2, '0');
        return '$mH:$mM';
      }
    } catch (_) {}
    return '23:48';
  }

  static String _subtractMinutes(String timeStr, int minutes) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0].trim());
        int m = int.parse(parts[1].trim());
        int total = h * 60 + m - minutes;
        if (total < 0) total += 24 * 60;
        final newH = (total ~/ 60).toString().padLeft(2, '0');
        final newM = (total % 60).toString().padLeft(2, '0');
        return '$newH:$newM';
      }
    } catch (_) {}
    return timeStr;
  }

  static String _addMinutes(String timeStr, int minutes) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0].trim());
        int m = int.parse(parts[1].trim());
        int total = (h * 60 + m + minutes) % (24 * 60);
        if (total < 0) total += 24 * 60;
        final newH = (total ~/ 60).toString().padLeft(2, '0');
        final newM = (total % 60).toString().padLeft(2, '0');
        return '$newH:$newM';
      }
    } catch (_) {}
    return timeStr;
  }

  static String _formatAlKafeelHijriDate(String rawDate) {
    try {
      final parts = rawDate.split('/');
      if (parts.length >= 3) {
        final year = int.tryParse(parts[0]) ?? 1448;
        final month = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;

        const months = [
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
        final monthName = (month >= 1 && month <= 12) ? months[month - 1] : '';
        return '$day $monthName $year هـ';
      }
    } catch (_) {}
    return rawDate.isNotEmpty ? '$rawDate هـ' : '';
  }

  static void _trySyncHijriFromKafeel(String rawDate) {
    try {
      final parts = rawDate.split('/');
      if (parts.length >= 3) {
        final day = int.tryParse(parts[2]);
        if (day != null && day >= 1 && day <= 30) {
          HijriDateService.applyRemoteHijriDay(day);
        }
      }
    } catch (_) {}
  }
}

