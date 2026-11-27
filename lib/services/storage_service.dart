import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city_location.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Theme
  String getThemeMode() => _prefs?.getString('theme_mode') ?? 'system';
  Future<void> setThemeMode(String mode) async => await _prefs?.setString('theme_mode', mode);

  // Prayer City
  String getSelectedCityId() => _prefs?.getString('selected_city_id') ?? 'karbala';
  Future<void> setSelectedCityId(String id) async => await _prefs?.setString('selected_city_id', id);

  Future<void> saveSelectedCity(CityLocation city) async {
    await _prefs?.setString('selected_city_id', city.id);
    await _prefs?.setString('saved_city_json', json.encode(city.toJson()));
    await saveGpsCity(city);
    await addRecentCity(city);
  }

  // Saved GPS Cities (Offline system cache - only cities determined via GPS)
  List<CityLocation> getSavedGpsCities() {
    final list = _prefs?.getStringList('saved_gps_cities_cache') ?? [];
    final cities = list.map((item) {
      try {
        return CityLocation.fromJson(json.decode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<CityLocation>().toList();

    // If cache is empty, check if we have an active saved city
    if (cities.isEmpty) {
      final active = getSavedCity();
      if (active != null) {
        cities.add(active);
        saveGpsCity(active);
      }
    }
    return cities;
  }

  Future<void> saveGpsCity(CityLocation city) async {
    final existing = getSavedGpsCities();
    existing.removeWhere((c) =>
        c.id == city.id ||
        (c.nameAr == city.nameAr &&
            (c.latitude - city.latitude).abs() < 0.05 &&
            (c.longitude - city.longitude).abs() < 0.05));
    existing.insert(0, city);
    final serialized = existing.map((c) => json.encode(c.toJson())).toList();
    await _prefs?.setStringList('saved_gps_cities_cache', serialized);
  }

  Future<void> removeGpsCity(String cityId) async {
    final existing = getSavedGpsCities();
    existing.removeWhere((c) => c.id == cityId);
    final serialized = existing.map((c) => json.encode(c.toJson())).toList();
    await _prefs?.setStringList('saved_gps_cities_cache', serialized);
  }

  CityLocation? getSavedCity() {
    final str = _prefs?.getString('saved_city_json');
    if (str != null && str.isNotEmpty) {
      try {
        final map = json.decode(str) as Map<String, dynamic>;
        return CityLocation.fromJson(map);
      } catch (_) {}
    }
    return null;
  }

  // Recent Cities History
  List<CityLocation> getRecentCities() {
    final list = _prefs?.getStringList('recent_cities_history') ?? [];
    return list.map((item) {
      try {
        return CityLocation.fromJson(json.decode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<CityLocation>().toList();
  }

  Future<void> addRecentCity(CityLocation city) async {
    final existing = getRecentCities();
    existing.removeWhere((c) => c.id == city.id || (c.nameAr == city.nameAr && c.province == city.province));
    existing.insert(0, city);
    if (existing.length > 10) {
      existing.removeLast();
    }
    final serialized = existing.map((c) => json.encode(c.toJson())).toList();
    await _prefs?.setStringList('recent_cities_history', serialized);
  }

  // Favorites
  List<String> getFavorites() => _prefs?.getStringList('favorite_items') ?? [];
  Future<void> toggleFavorite(String itemTitle) async {
    final list = getFavorites();
    if (list.contains(itemTitle)) {
      list.remove(itemTitle);
    } else {
      list.add(itemTitle);
    }
    await _prefs?.setStringList('favorite_items', list);
  }
  bool isFavorite(String itemTitle) => getFavorites().contains(itemTitle);

  // Last Read Quran
  int getLastReadSurah() => _prefs?.getInt('last_read_surah') ?? 1;
  int getLastReadAyah() => _prefs?.getInt('last_read_ayah') ?? 1;
  Future<void> setLastRead(int surah, int ayah) async {
    await _prefs?.setInt('last_read_surah', surah);
    await _prefs?.setInt('last_read_ayah', ayah);
  }

  // Quran Saved Bookmarks
  List<String> getQuranBookmarks() => _prefs?.getStringList('quran_saved_bookmarks') ?? [];
  Future<void> setQuranBookmarks(List<String> bookmarks) async {
    await _prefs?.setStringList('quran_saved_bookmarks', bookmarks);
  }

  // Khatma Progress
  int getKhatmaCurrentPage() => _prefs?.getInt('khatma_current_page') ?? 1;
  Future<void> setKhatmaCurrentPage(int page) async => await _prefs?.setInt('khatma_current_page', page);

  // Font Size
  double getFontSize() => _prefs?.getDouble('reader_font_size') ?? 20.0;
  Future<void> setFontSize(double size) async => await _prefs?.setDouble('reader_font_size', size);

  // Free Tasbeeh
  int getFreeTasbeehCount() => _prefs?.getInt('free_tasbeeh_count') ?? 0;
  Future<void> setFreeTasbeehCount(int count) async => await _prefs?.setInt('free_tasbeeh_count', count);

  // Quran Reading Mode ('classic' or 'uthmani')
  String getQuranReadingMode() => _prefs?.getString('quran_reading_mode') ?? 'uthmani';
  Future<void> setQuranReadingMode(String mode) async => await _prefs?.setString('quran_reading_mode', mode);

  // Favorite Reciters
  List<int> getFavoriteReciterIds() {
    final raw = _prefs?.getStringList('favorite_reciter_ids');
    if (raw == null) return [];
    return raw.map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  Future<void> setFavoriteReciterIds(List<int> ids) async {
    await _prefs?.setStringList(
      'favorite_reciter_ids',
      ids.map((e) => e.toString()).toList(),
    );
  }

  // Favorite Surahs inside Reciter Styles (reciterId + styleId + styleName + surahId + surahName)
  List<Map<String, dynamic>> getReciterSurahFavorites() {
    final raw = _prefs?.getStringList('reciter_surah_favorites') ?? [];
    final List<Map<String, dynamic>> result = [];
    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          result.add(decoded);
        }
      } catch (_) {}
    }
    return result;
  }

  Future<bool> toggleReciterSurahFavorite({
    required int reciterId,
    required String reciterName,
    required int styleId,
    required String styleName,
    required int surahId,
    required String surahName,
  }) async {
    final list = getReciterSurahFavorites();
    final idx = list.indexWhere((e) =>
        e['reciterId'] == reciterId &&
        e['styleId'] == styleId &&
        e['surahId'] == surahId);
    bool added;
    if (idx >= 0) {
      list.removeAt(idx);
      added = false;
    } else {
      list.insert(0, {
        'reciterId': reciterId,
        'reciterName': reciterName,
        'styleId': styleId,
        'styleName': styleName,
        'surahId': surahId,
        'surahName': surahName,
      });
      added = true;
    }
    await _prefs?.setStringList(
      'reciter_surah_favorites',
      list.map((e) => jsonEncode(e)).toList(),
    );
    return added;
  }

}
