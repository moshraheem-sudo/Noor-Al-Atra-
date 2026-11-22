import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/person.dart';
import '../models/hijri_event.dart';
import '../models/worship_item.dart';
import '../models/worship_audio.dart';
import '../models/city_location.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Person> people = [];
  List<HijriEvent> events = [];
  Map<String, List<WorshipItem>> worshipData = {};
  List<WorshipAudioItem> worshipAudios = [];
  List<CityLocation> cities = [];
  bool isInitialized = false;

  Future<void> init() async {
    if (isInitialized) return;

    try {
      // 1. AhlulBayt & Events
      final ahlalbaytStr = await rootBundle.loadString('assets/data/ahlalbayt_data.json');
      final ahlalbaytJson = json.decode(ahlalbaytStr) as Map<String, dynamic>;
      people = (ahlalbaytJson['people'] as List<dynamic>? ?? [])
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
      events = (ahlalbaytJson['events'] as List<dynamic>? ?? [])
          .map((e) => HijriEvent.fromJson(e as Map<String, dynamic>))
          .toList();

      // 2. Worship Audios
      final audiosStr = await rootBundle.loadString('assets/data/worship_audios.json');
      final audiosJson = json.decode(audiosStr) as List<dynamic>;
      worshipAudios = audiosJson
          .map((e) => WorshipAudioItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // 3. Cities
      final citiesStr = await rootBundle.loadString('assets/data/cities_data.json');
      final citiesJson = json.decode(citiesStr) as List<dynamic>;
      cities = citiesJson
          .map((e) => CityLocation.fromJson(e as Map<String, dynamic>))
          .toList();

      // 4. Worship Data (Texts)
      final worshipStr = await rootBundle.loadString('assets/data/worship_data.json');
      final worshipJson = json.decode(worshipStr) as Map<String, dynamic>;
      worshipData = {};
      worshipJson.forEach((key, value) {
        if (value is List) {
          worshipData[key] = value.map((item) {
            final map = item as Map<String, dynamic>;
            return WorshipItem.fromJson(map, categoryKey: key);
          }).toList();
        }
      });

      isInitialized = true;
    } catch (e) {
      // fallback if file loading fails
      print('Error loading assets data: $e');
    }
  }

  List<WorshipItem> getItemsByCategory(String categoryKey) {
    return worshipData[categoryKey] ?? [];
  }

  List<WorshipItem> searchWorship(String query) {
    if (query.trim().isEmpty) return [];
    final cleanQuery = _normalizeArabic(query);
    final results = <WorshipItem>[];

    worshipData.forEach((key, list) {
      for (final item in list) {
        if (_normalizeArabic(item.title).contains(cleanQuery) ||
            _normalizeArabic(item.text).contains(cleanQuery)) {
          results.add(item);
        }
      }
    });

    return results;
  }

  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u0640]'), '')
        .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u0649\u064a]'), 'ي')
        .trim();
  }
}
