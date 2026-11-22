import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/khatma_model.dart';
import '../models/quran_chapter.dart';
import '../models/reciter.dart';

class QuranSearchResult {
  final int surahId;
  final String surahName;
  final int ayahNumber;
  final String textUthmani;
  final String cleanText;
  final int juzNumber;

  const QuranSearchResult({
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.textUthmani,
    required this.cleanText,
    required this.juzNumber,
  });
}

class QuranApiService {
  static const String quranBaseUrl = 'https://api.quran.com/api/v4';
  static const String mp3QuranBaseUrl = 'https://www.mp3quran.net/api/v3';

  // In-memory cache for instant 0ms access without any loading delay
  static final Map<int, List<VerseItem>> _memoryCache = {};
  static Future<void>? _preloadFuture;

  /// Arabic text normalization for flexible search
  static String normalizeArabic(String text) {
    return text
        // Remove Tatweel (ـ) and all Arabic Tashkeel / Harakat and Quranic marks
        .replaceAll(RegExp(r'[\u0640\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED]'), '')
        // Normalize Alef variations (أ, إ, آ, ٱ, ءَا) -> ا
        .replaceAll(RegExp(r'[أإآٱءَا]'), 'ا')
        // Normalize Ya / Alif Maqsura (ى, ئ, ي, ى) -> ي
        .replaceAll(RegExp(r'[ىيئ]'), 'ي')
        // Normalize Ta Marbuta (ة) -> ه
        .replaceAll('ة', 'ه')
        // Normalize Waw with Hamza (ؤ) -> و
        .replaceAll('ؤ', 'و')
        // Remove standalone Hamza
        .replaceAll('ء', '')
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Search all verses in the Quran for a matching text query
  static Future<List<QuranSearchResult>> searchVerses(String query) async {
    final cleanQuery = normalizeArabic(query);
    if (cleanQuery.isEmpty) return [];

    // Ensure all 114 surahs are fully loaded into _memoryCache
    if (_memoryCache.length < 114) {
      await preloadAllSurahsInBackground();
    }

    final List<QuranSearchResult> results = [];

    for (final chapter in QuranChapter.allChapters) {
      final verses = _memoryCache[chapter.id];
      if (verses == null || verses.isEmpty) continue;

      for (final v in verses) {
        final normText = normalizeArabic(v.textUthmani);
        if (normText.contains(cleanQuery)) {
          final ayahNum = int.tryParse(v.verseKey.split(':').last) ?? 1;
          final juz = JuzInfo.getJuzNumberForAyah(chapter.id, ayahNum);
          results.add(
            QuranSearchResult(
              surahId: chapter.id,
              surahName: chapter.nameArabic,
              ayahNumber: ayahNum,
              textUthmani: v.textUthmani,
              cleanText: normText,
              juzNumber: juz,
            ),
          );
          if (results.length >= 150) break;
        }
      }
      if (results.length >= 150) break;
    }

    return results;
  }

  /// Check if verses are currently available in memory
  static List<VerseItem>? getCachedVerses(int chapterNumber) {
    if (_memoryCache.containsKey(chapterNumber) && _memoryCache[chapterNumber]!.isNotEmpty) {
      return _memoryCache[chapterNumber];
    }
    return null;
  }

  /// Get local cache directory for surahs
  static Future<Directory?> _getCacheDir() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final surahsDir = Directory('${docs.path}/quran_surahs');
      if (!await surahsDir.exists()) {
        await surahsDir.create(recursive: true);
      }
      return surahsDir;
    } catch (e) {
      print('Error getting cache dir: $e');
      return null;
    }
  }

  /// Automatically preload all 114 Surahs in the background (returns existing future if in progress)
  static Future<void> preloadAllSurahsInBackground() {
    if (_memoryCache.length >= 114) return Future.value();
    _preloadFuture ??= _doPreload();
    return _preloadFuture!;
  }

  static Future<void> _doPreload() async {
    try {
      // 1. First attempt to load bundled asset which contains all 114 surahs
      try {
        final jsonStr = await rootBundle.loadString('assets/data/quran_uthmani.json');
        final Map<String, dynamic> allData = json.decode(jsonStr);
        allData.forEach((key, val) {
          final chId = int.tryParse(key);
          if (chId != null && val is List) {
            _memoryCache[chId] = val.map((v) => VerseItem.fromJson(v as Map<String, dynamic>)).toList();
          }
        });
        if (_memoryCache.length >= 114) {
          print('Successfully preloaded all 114 Surahs from offline bundle!');
          return;
        }
      } catch (e) {
        print('Asset bundle preload notice: $e');
      }

      // 2. Check local disk cache for missing chapters
      final dir = await _getCacheDir();
      if (dir != null) {
        for (int i = 1; i <= 114; i++) {
          if (_memoryCache.containsKey(i) && _memoryCache[i]!.isNotEmpty) continue;
          final file = File('${dir.path}/surah_$i.json');
          if (await file.exists()) {
            try {
              final content = await file.readAsString();
              final list = json.decode(content) as List<dynamic>;
              _memoryCache[i] = list.map((v) => VerseItem.fromJson(v as Map<String, dynamic>)).toList();
            } catch (_) {}
          }
        }

        // 3. For any missing surahs, fetch and cache in background
        for (int i = 1; i <= 114; i++) {
          if (!_memoryCache.containsKey(i) || _memoryCache[i]!.isEmpty) {
            await _fetchAndCacheFromNetwork(i, dir);
          }
        }
      }
    } catch (e) {
      print('Quran preload error: $e');
    }
  }

  static Future<List<VerseItem>> _fetchAndCacheFromNetwork(int chapterNumber, Directory? dir) async {
    try {
      final uri = Uri.parse('$quranBaseUrl/quran/verses/uthmani?chapter_number=$chapterNumber');
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NoorAlAtra/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['verses'] as List<dynamic>? ?? []);
        final verses = list.map((v) => VerseItem.fromJson(v as Map<String, dynamic>)).toList();
        if (verses.isNotEmpty) {
          _memoryCache[chapterNumber] = verses;
          if (dir != null) {
            try {
              final file = File('${dir.path}/surah_$chapterNumber.json');
              final rawList = verses.map((v) => {
                'id': v.id,
                'verse_key': v.verseKey,
                'text_uthmani': v.textUthmani,
              }).toList();
              await file.writeAsString(json.encode(rawList));
            } catch (_) {}
          }
          return verses;
        }
      }
    } catch (e) {
      print('Network fetch failed for surah $chapterNumber: $e');
    }
    return [];
  }

  /// Fetches Uthmani Arabic verses for a specific chapter (Instant from cache, or downloads)
  static Future<List<VerseItem>> getVerses(int chapterNumber) async {
    // 1. Instant return if in memory cache
    if (_memoryCache.containsKey(chapterNumber) && _memoryCache[chapterNumber]!.isNotEmpty) {
      return _memoryCache[chapterNumber]!;
    }

    // 2. Try loading from bundled offline asset
    try {
      final jsonStr = await rootBundle.loadString('assets/data/quran_uthmani.json');
      final Map<String, dynamic> allData = json.decode(jsonStr);
      final surahData = allData['$chapterNumber'] as List<dynamic>?;
      if (surahData != null && surahData.isNotEmpty) {
        final verses = surahData.map((v) => VerseItem.fromJson(v as Map<String, dynamic>)).toList();
        _memoryCache[chapterNumber] = verses;
        return verses;
      }
    } catch (_) {}

    // 3. Try reading from disk cache
    Directory? dir;
    try {
      dir = await _getCacheDir();
      if (dir != null) {
        final file = File('${dir.path}/surah_$chapterNumber.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          final list = json.decode(content) as List<dynamic>;
          final verses = list.map((v) => VerseItem.fromJson(v as Map<String, dynamic>)).toList();
          if (verses.isNotEmpty) {
            _memoryCache[chapterNumber] = verses;
            return verses;
          }
        }
      }
    } catch (e) {
      print('Error checking disk cache for $chapterNumber: $e');
    }

    // 4. Download from network and cache
    return await _fetchAndCacheFromNetwork(chapterNumber, dir);
  }

  /// Fetches reciter details & audio servers from mp3quran
  static Future<List<ReciterStyle>> getReciterStyles(int reciterId) async {
    try {
      final uri = Uri.parse('$mp3QuranBaseUrl/reciters?language=ar&reciter=$reciterId');
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NoorAlAtra/1.0'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reciters = data['reciters'] as List<dynamic>? ?? [];
        if (reciters.isNotEmpty) {
          final first = reciters[0] as Map<String, dynamic>;
          final moshafList = first['moshaf'] as List<dynamic>? ?? [];
          return moshafList.map((m) => ReciterStyle.fromJson(m as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('Error fetching reciter styles: $e');
    }
    return [];
  }

  /// Generates the audio URL for an ayah from EveryAyah CDN
  static String getAyahAudioUrl({required int surah, required int ayah, String reciter = 'Alafasy_128kbps'}) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciter/$s$a.mp3';
  }

  /// Generates the audio URL for a full surah from mp3quran server
  static String getSurahAudioUrl(String server, int surah) {
    final s = surah.toString().padLeft(3, '0');
    final cleanServer = server.endsWith('/') ? server : '$server/';
    return '$cleanServer$s.mp3';
  }
}

