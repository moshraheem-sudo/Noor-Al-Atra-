import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/quran_chapter.dart';
import '../models/tafseer_model.dart';
import '../services/storage_service.dart';

class TafseerRepository {
  static final TafseerRepository _instance = TafseerRepository._internal();
  factory TafseerRepository() => _instance;
  TafseerRepository._internal();

  final Map<TafseerType, Database> _databases = {};
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  // In-memory cache for surah entries to make tab switching and scrolling instantaneous
  final Map<String, List<TafseerEntry>> _surahEntriesCache = {};

  bool get isInitialized => _isInitialized;

  /// تهيئة قواعد البيانات وفحص ما هو محمل محلياً
  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      final databasesPath = await getDatabasesPath();
      await Directory(databasesPath).create(recursive: true);

      for (final type in TafseerType.values) {
        await ensureDatabase(type);
      }

      await StorageService().init();
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e, st) {
      debugPrint('Error initializing TafseerRepository: $e\n$st');
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
    }
  }

  /// التحقق مما إذا كان التفسير محملاً ومتاحاً بدون إنترنت
  Future<bool> isDownloaded(TafseerType type) async {
    final databasesPath = await getDatabasesPath();
    final file = File(p.join(databasesPath, type.dbFileName));
    if (await file.exists()) {
      return (await file.length()) > 1000000;
    }
    return false;
  }

  /// التحقق مما إذا كان التفسير مفتوحاً حالياً في الذاكرة
  bool isLoaded(TafseerType type) {
    return _databases.containsKey(type) && _databases[type]!.isOpen;
  }

  /// التأكد من فتح قاعدة البيانات المحلية إن كانت موجودة
  Future<Database?> ensureDatabase(TafseerType type) async {
    if (_databases.containsKey(type) && _databases[type]!.isOpen) {
      return _databases[type]!;
    }
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, type.dbFileName);
    final file = File(dbPath);
    if (!await file.exists() || (await file.length()) < 1000000) {
      return null;
    }

    try {
      final db = await openDatabase(
        dbPath,
        readOnly: true,
        singleInstance: true,
      );
      _databases[type] = db;
      return db;
    } catch (e) {
      debugPrint('Error opening database for ${type.displayName}: $e');
      return null;
    }
  }

  /// تنزيل قاعدة بيانات التفسير اختيارياً مع شريط التقدم وفك الضغط
  Future<bool> downloadTafseer(
    TafseerType type, {
    void Function(double progress, int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(type.downloadUrl));
      request.headers['User-Agent'] = 'NoorAlAtra/1.0';
      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode != 200) {
        throw HttpException('Download failed with status ${streamedResponse.statusCode}');
      }

      final total = streamedResponse.contentLength ?? type.approxCompressedBytes;
      int received = 0;
      final bytesBuilder = BytesBuilder(copy: false);

      await for (final chunk in streamedResponse.stream) {
        bytesBuilder.add(chunk);
        received += chunk.length;
        if (onProgress != null && total > 0) {
          onProgress((received / total).clamp(0.0, 1.0), received, total);
        }
      }

      final compressedBytes = bytesBuilder.takeBytes();
      // فك الضغط التلقائي السريع باستخدام GZipCodec
      final decompressedBytes = gzip.decode(compressedBytes);

      final databasesPath = await getDatabasesPath();
      await Directory(databasesPath).create(recursive: true);
      final dbPath = p.join(databasesPath, type.dbFileName);
      final targetFile = File(dbPath);
      await targetFile.writeAsBytes(decompressedBytes, flush: true);

      // فتح قاعدة البيانات
      final db = await openDatabase(
        dbPath,
        readOnly: true,
        singleInstance: true,
      );
      _databases[type] = db;
      _surahEntriesCache.removeWhere((k, _) => k.startsWith(type.id));
      return true;
    } catch (e) {
      debugPrint('Error downloading tafseer ${type.displayName}: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// حذف ملف التفسير محلياً لتوفير مساحة التخزين في الهاتف
  Future<void> deleteTafseer(TafseerType type) async {
    if (_databases.containsKey(type)) {
      try {
        await _databases[type]!.close();
      } catch (_) {}
      _databases.remove(type);
    }
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, type.dbFileName);
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
    _surahEntriesCache.removeWhere((k, _) => k.startsWith(type.id));
  }

  /// جلب تفسير آية محددة
  Future<TafseerEntry?> getTafseerForAyah(TafseerType type, int surahNumber, int ayahNumber) async {
    await init();
    final db = await ensureDatabase(type);
    if (db == null) return null;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT c.content_id, c.content, MIN(m.ayah_number) AS start_ayah, MAX(m.ayah_number) AS end_ayah
      FROM ayah_mapping m
      JOIN content c ON c.content_id = m.content_id
      WHERE m.surah_number = ? AND m.content_id = (
        SELECT content_id FROM ayah_mapping WHERE surah_number = ? AND ayah_number = ? LIMIT 1
      )
      GROUP BY c.content_id
    ''', [surahNumber, surahNumber, ayahNumber]);

    if (results.isEmpty) return null;

    final row = results.first;
    final ch = QuranChapter.getChapterById(surahNumber);
    return TafseerEntry(
      contentId: (row['content_id'] as num).toInt(),
      type: type,
      surahNumber: surahNumber,
      startAyah: (row['start_ayah'] as num).toInt(),
      endAyah: (row['end_ayah'] as num).toInt(),
      content: row['content'] as String,
      surahName: ch?.nameArabic ?? 'سورة $surahNumber',
    );
  }

  /// جلب كافة وحدات التفسير لسورة كاملة مرتبة حسب تسلسل الآيات
  Future<List<TafseerEntry>> getTafseerEntriesForSurah(TafseerType type, int surahNumber) async {
    await init();
    final cacheKey = '${type.id}_$surahNumber';
    if (_surahEntriesCache.containsKey(cacheKey)) {
      return _surahEntriesCache[cacheKey]!;
    }

    final db = await ensureDatabase(type);
    if (db == null) return [];

    final ch = QuranChapter.getChapterById(surahNumber);
    final surahName = ch?.nameArabic ?? 'سورة $surahNumber';

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT c.content_id, c.content, MIN(m.ayah_number) AS start_ayah, MAX(m.ayah_number) AS end_ayah
      FROM ayah_mapping m
      JOIN content c ON c.content_id = m.content_id
      WHERE m.surah_number = ?
      GROUP BY c.content_id
      ORDER BY MIN(m.ayah_number) ASC
    ''', [surahNumber]);

    final entries = results.map((row) {
      return TafseerEntry(
        contentId: (row['content_id'] as num).toInt(),
        type: type,
        surahNumber: surahNumber,
        startAyah: (row['start_ayah'] as num).toInt(),
        endAyah: (row['end_ayah'] as num).toInt(),
        content: row['content'] as String,
        surahName: surahName,
      );
    }).toList();

    _surahEntriesCache[cacheKey] = entries;
    return entries;
  }

  /// جلب مقدمة التفسير الأصلية
  Future<String?> getMuqadimah(TafseerType type) async {
    await init();
    final db = await ensureDatabase(type);
    if (db == null) return null;

    final List<Map<String, dynamic>> res = await db.rawQuery('SELECT content FROM muqadimah LIMIT 1');
    if (res.isNotEmpty) {
      return res.first['content'] as String?;
    }
    return null;
  }

  /// البحث داخل نصوص التفسير
  Future<List<TafseerSearchResult>> searchTafseer(
    TafseerType type,
    String query, {
    int limit = 60,
  }) async {
    await init();
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final db = await ensureDatabase(type);
    if (db == null) return [];

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT c.content_id, m.surah_number, MIN(m.ayah_number) AS start_ayah, MAX(m.ayah_number) AS end_ayah, c.content
      FROM content c
      JOIN ayah_mapping m ON m.content_id = c.content_id
      WHERE c.content LIKE ?
      GROUP BY c.content_id, m.surah_number
      ORDER BY m.surah_number ASC, MIN(m.ayah_number) ASC
      LIMIT ?
    ''', ['%$cleanQuery%', limit]);

    return results.map((row) {
      final surahNum = (row['surah_number'] as num).toInt();
      final ch = QuranChapter.getChapterById(surahNum);
      final rawContent = row['content'] as String;

      final snippet = _createSnippet(rawContent, cleanQuery);

      return TafseerSearchResult(
        type: type,
        contentId: (row['content_id'] as num).toInt(),
        surahNumber: surahNum,
        startAyah: (row['start_ayah'] as num).toInt(),
        endAyah: (row['end_ayah'] as num).toInt(),
        surahName: ch?.nameArabic ?? 'سورة $surahNum',
        snippet: snippet,
        matchedText: cleanQuery,
      );
    }).toList();
  }

  String _createSnippet(String text, String query) {
    final cleanText = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    final idx = cleanText.indexOf(query);
    if (idx == -1) {
      return cleanText.length > 140 ? '${cleanText.substring(0, 140)}...' : cleanText;
    }

    final start = (idx - 50).clamp(0, cleanText.length);
    final end = (idx + query.length + 70).clamp(0, cleanText.length);
    final prefix = start > 0 ? '...' : '';
    final suffix = end < cleanText.length ? '...' : '';
    return '$prefix${cleanText.substring(start, end)}$suffix';
  }

  /// مقارنة بين التفسيرين للآية نفسها
  Future<Map<TafseerType, TafseerEntry?>> getComparisonForAyah(int surahNumber, int ayahNumber) async {
    await init();
    final results = await Future.wait([
      getTafseerForAyah(TafseerType.almizan, surahNumber, ayahNumber),
      getTafseerForAyah(TafseerType.safi, surahNumber, ayahNumber),
    ]);

    return {
      TafseerType.almizan: results[0],
      TafseerType.safi: results[1],
    };
  }

  // ==========================================
  // المفضلة (Tafseer Favorites)
  // ==========================================

  List<TafseerFavorite> getFavorites() {
    final list = StorageService().getTafseerFavoritesRaw();
    return list.map((item) {
      try {
        return TafseerFavorite.fromJson(json.decode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<TafseerFavorite>().toList();
  }

  bool isFavorite(TafseerType type, int surahNumber, int ayahNumber) {
    final key = '${type.id}_${surahNumber}_$ayahNumber';
    final favs = getFavorites();
    return favs.any((f) => f.id == key || (f.type == type && f.surahNumber == surahNumber && f.containsAyah(ayahNumber)));
  }

  Future<bool> toggleFavorite({
    required TafseerType type,
    required int surahNumber,
    required int ayahNumber,
    required int startAyah,
    required int endAyah,
    required String surahName,
    required String fullContent,
  }) async {
    final key = '${type.id}_${surahNumber}_$ayahNumber';
    final favs = getFavorites();
    final existsIdx = favs.indexWhere((f) => f.id == key || (f.type == type && f.surahNumber == surahNumber && f.containsAyah(ayahNumber)));

    bool added = false;
    if (existsIdx != -1) {
      favs.removeAt(existsIdx);
      added = false;
    } else {
      final snippet = fullContent.length > 150 ? '${fullContent.substring(0, 150).replaceAll('\n', ' ')}...' : fullContent;
      favs.insert(
        0,
        TafseerFavorite(
          id: key,
          type: type,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          startAyah: startAyah,
          endAyah: endAyah,
          surahName: surahName,
          snippet: snippet,
          savedAt: DateTime.now(),
        ),
      );
      added = true;
    }

    final rawList = favs.map((f) => json.encode(f.toJson())).toList();
    await StorageService().setTafseerFavoritesRaw(rawList);
    return added;
  }

  // ==========================================
  // موضع القراءة وحجم الخط
  // ==========================================

  Future<void> saveLastReadingPosition({
    required TafseerType type,
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
  }) async {
    final pos = TafseerReadingPosition(
      type: type,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      updatedAt: DateTime.now(),
    );
    await StorageService().setTafseerLastPositionRaw(json.encode(pos.toJson()));
  }

  TafseerReadingPosition? getLastReadingPosition() {
    final raw = StorageService().getTafseerLastPositionRaw();
    if (raw == null || raw.isEmpty) return null;
    try {
      return TafseerReadingPosition.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  double getFontSize() {
    return StorageService().getTafseerFontSize();
  }

  Future<void> setFontSize(double size) async {
    await StorageService().setTafseerFontSize(size);
  }
}

extension TafseerEntryExtension on TafseerFavorite {
  bool containsAyah(int ayah) => ayah >= startAyah && ayah <= endAyah;
}
