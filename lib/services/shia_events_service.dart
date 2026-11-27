import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hijri_event.dart';
import 'data_service.dart';

/// خدمة مزامنة ودمج أحداث ومناسبات أهل البيت (ع) المنتقاة
/// عبر واجهة تقويم أهل البيت (ع): https://theshia.org/api/v1/events
class ShiaEventsService {
  static const String apiUrl = 'https://theshia.org/api/v1/events?details=1';
  static const String _cacheKey = 'cached_theshia_events_v1';
  static const String _cacheTimestampKey = 'cached_theshia_events_time_v1';
  static const Duration _cacheTtl = Duration(days: 7);

  static final ShiaEventsService _instance = ShiaEventsService._internal();
  factory ShiaEventsService() => _instance;
  ShiaEventsService._internal();

  /// دمج الأحداث المخزنة محلياً فور تشغيل التطبيق دون انتظار الشبكة
  static void mergeStoredEvents(List<HijriEvent> targetList) {
    try {
      SharedPreferences.getInstance().then((prefs) {
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final parsed = parseEventsJson(cachedJson);
          if (parsed.isNotEmpty) {
            _mergeInto(targetList, parsed);
          }
        }
      }).catchError((e) {
        debugPrint('[ShiaEventsService] Error reading cached events: $e');
      });
    } catch (e) {
      debugPrint('[ShiaEventsService] Exception: $e');
    }
  }

  /// مزامنة المناسبات من API theshia.org مع احترام قيود الطلبات والتخزين المؤقت
  static Future<List<HijriEvent>> syncRemoteEvents({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt(_cacheTimestampKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (!force && (nowMs - lastSyncMs < _cacheTtl.inMilliseconds)) {
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final events = parseEventsJson(cachedJson);
          if (events.isNotEmpty) {
            _mergeInto(DataService().events, events);
            return events;
          }
        }
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'NoorAlAtra/1.0 (Islamic Calendar Engine)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        final events = parseEventsJson(body);
        if (events.isNotEmpty) {
          await prefs.setString(_cacheKey, body);
          await prefs.setInt(_cacheTimestampKey, nowMs);
          _mergeInto(DataService().events, events);
          debugPrint('[ShiaEventsService] Successfully synced ${events.length} Shia events from theshia.org');
          return events;
        }
      } else {
        debugPrint('[ShiaEventsService] Server responded with code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ShiaEventsService] Sync failed (falling back to cache/bundled): $e');
    }
    return [];
  }

  /// تحليل الـ JSON وتحويله إلى كائنات HijriEvent
  static List<HijriEvent> parseEventsJson(String jsonString) {
    final List<HijriEvent> results = [];
    try {
      final decoded = json.decode(jsonString);
      final rawList = decoded is Map ? (decoded['events'] ?? decoded['data']) : decoded;
      if (rawList is! List) return results;

      for (final item in rawList) {
        if (item is! Map<String, dynamic>) continue;

        final m = item['hijriMonth'] as int?;
        final d = item['hijriDay'] as int?;
        if (m == null || d == null || m < 1 || m > 12 || d < 1 || d > 30) continue;

        final titleMap = item['title'];
        String name = '';
        if (titleMap is Map) {
          name = (titleMap['ar'] ?? titleMap['en'] ?? '').toString().trim();
        } else if (titleMap is String) {
          name = titleMap.trim();
        }

        if (name.isEmpty) continue;

        final type = (item['type'] ?? '').toString().toLowerCase();
        final isMartyrdom = type == 'martyrdom' ||
            type == 'death' ||
            type == 'mourning' ||
            name.contains('استشهاد') ||
            name.contains('وفاة') ||
            name.contains('مقتل') ||
            name.contains('عاشوراء') ||
            name.contains('تاسوعاء') ||
            name.contains('أربعين') ||
            name.contains('سبي');

        final year = item['hijriYear'] is int ? item['hijriYear'] as int : null;

        results.add(HijriEvent(
          day: d,
          month: m,
          name: name,
          isMartyrdom: isMartyrdom,
          year: year,
        ));
      }
    } catch (e) {
      debugPrint('[ShiaEventsService] Parse error: $e');
    }
    return results;
  }

  /// دمج ذكي يمنع تكرار المناسبات في نفس اليوم
  static void _mergeInto(List<HijriEvent> currentList, List<HijriEvent> incoming) {
    for (final newEv in incoming) {
      final exists = currentList.any((existing) {
        if (existing.month != newEv.month || existing.day != newEv.day) return false;

        // التحقق من تشابه الكلمات المفتاحية لمنع التكرار
        final n1 = _clean(existing.name);
        final n2 = _clean(newEv.name);
        if (n1 == n2) return true;

        if ((n1.contains('علي') && n2.contains('علي')) ||
            (n1.contains('فاطم') && n2.contains('فاطم')) ||
            (n1.contains('حسين') && n2.contains('حسين')) ||
            (n1.contains('حسن') && n2.contains('حسن')) ||
            (n1.contains('عباس') && n2.contains('عباس')) ||
            (n1.contains('زينب') && n2.contains('زينب')) ||
            (n1.contains('صادق') && n2.contains('صادق')) ||
            (n1.contains('كاظم') && n2.contains('كاظم')) ||
            (n1.contains('رضا') && n2.contains('رضا')) ||
            (n1.contains('جواد') && n2.contains('جواد')) ||
            (n1.contains('هادي') && n2.contains('هادي')) ||
            (n1.contains('عسكري') && n2.contains('عسكري')) ||
            (n1.contains('مهدي') && n2.contains('مهدي')) ||
            (n1.contains('غدير') && n2.contains('غدير')) ||
            (n1.contains('عاشوراء') && n2.contains('عاشوراء')) ||
            (n1.contains('مبعث') && n2.contains('مبعث')) ||
            (n1.contains('فطر') && n2.contains('فطر')) ||
            (n1.contains('اضحى') && n2.contains('اضحى'))) {
          return true;
        }

        return false;
      });

      if (!exists) {
        currentList.add(newEv);
      }
    }

    // فرز القائمة المدمجة بحسب الشهر واليوم
    currentList.sort((a, b) {
      final mc = a.month.compareTo(b.month);
      if (mc != 0) return mc;
      return a.day.compareTo(b.day);
    });
  }

  static String _clean(String s) {
    return s
        .replaceAll(RegExp(r'[\u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u0640]'), '')
        .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u0649\u064a]'), 'ي')
        .replaceAll('(ع)', '')
        .replaceAll('(عج)', '')
        .replaceAll('(ص)', '')
        .replaceAll('عليه السلام', '')
        .replaceAll('عليها السلام', '')
        .replaceAll('عليهم السلام', '')
        .trim();
  }
}
