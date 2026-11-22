import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/khatma_model.dart';

class KhatmaRepository extends ChangeNotifier {
  static final KhatmaRepository _instance = KhatmaRepository._internal();
  factory KhatmaRepository() => _instance;
  KhatmaRepository._internal() {
    _loadFromPrefs();
  }

  bool _isNotificationScheduled = false;

  @override
  void notifyListeners() {
    final binding = WidgetsBinding.instance;
    final isBuilding = binding.buildOwner?.debugBuilding ?? false;
    final isCallbackPhase = binding.schedulerPhase != SchedulerPhase.idle;

    if (isBuilding || isCallbackPhase) {
      if (!_isNotificationScheduled) {
        _isNotificationScheduled = true;
        binding.addPostFrameCallback((_) {
          _isNotificationScheduled = false;
          if (hasListeners) {
            super.notifyListeners();
          }
        });
      }
    } else {
      super.notifyListeners();
    }
  }

  static const String _khatmaStorageKey = 'khatma_progress_v2';
  SharedPreferences? _prefs;
  final Map<int, JuzProgress> _progressMap = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> _loadFromPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final jsonStr = _prefs?.getString(_khatmaStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        decoded.forEach((key, val) {
          final jNum = int.tryParse(key);
          if (jNum != null && val is Map<String, dynamic>) {
            _progressMap[jNum] = JuzProgress.fromJson(val);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading Khatma progress: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final Map<String, dynamic> rawMap = {};
      _progressMap.forEach((key, val) {
        rawMap['$key'] = val.toJson();
      });
      await _prefs?.setString(_khatmaStorageKey, json.encode(rawMap));
    } catch (e) {
      debugPrint('Error saving Khatma progress: $e');
    }
  }

  JuzProgress getJuzProgress(int juzNumber) {
    if (_progressMap.containsKey(juzNumber)) {
      return _progressMap[juzNumber]!;
    }
    return JuzProgress(juzNumber: juzNumber);
  }

  List<JuzProgress> getAllProgress() {
    return List.generate(30, (i) => getJuzProgress(i + 1));
  }

  int get completedJuzCount {
    return _progressMap.values.where((p) => p.isCompleted).length;
  }

  double get overallProgressRatio {
    double totalProgress = 0.0;
    for (int j = 1; j <= 30; j++) {
      totalProgress += getJuzProgress(j).progressRatio;
    }
    return (totalProgress / 30.0).clamp(0.0, 1.0);
  }

  int get overallProgressPercent => (overallProgressRatio * 100).round();

  /// Checks if a given position is at or past the end of a specific Juz
  bool _isJuzFinished(int juzNumber, int surahId, int ayahNumber) {
    if (juzNumber < 30) {
      final nextJuz = JuzInfo.allAjza[juzNumber];
      if (surahId > nextJuz.startSurahId) return true;
      if (surahId == nextJuz.startSurahId && ayahNumber >= nextJuz.startAyah) return true;
      return false;
    } else {
      return surahId == 114 && ayahNumber >= 6;
    }
  }

  /// Updates user reading progress when reading any page in the Quran
  Future<void> updateReadingProgress({
    required int page,
    required int surahId,
    required String surahName,
    int? ayahNumber,
  }) async {
    final juzInfo = JuzInfo.getJuzForPage(page);
    final ayah = ayahNumber ?? 1;
    final isFinished = _isJuzFinished(juzInfo.juzNumber, surahId, ayah);

    final current = getJuzProgress(juzInfo.juzNumber);
    final newProgress = JuzProgress(
      juzNumber: juzInfo.juzNumber,
      lastReadPage: page,
      lastReadSurahId: surahId,
      lastReadSurahName: surahName,
      lastReadAyah: ayah,
      isCompleted: isFinished ? true : current.isCompleted,
      updatedAt: DateTime.now(),
    );

    _progressMap[juzInfo.juzNumber] = newProgress;
    notifyListeners();
    await _saveToPrefs();
  }

  /// Updates user reading progress by exact Ayah and Surah
  Future<void> updateReadingProgressByAyah({
    required int surahId,
    required String surahName,
    required int ayahNumber,
    int? pageNumber,
  }) async {
    final computedPage = pageNumber ?? JuzInfo.getPageForSurahAndAyah(surahId, ayahNumber);
    final computedJuz = JuzInfo.getJuzNumberForAyah(surahId, ayahNumber);
    final isFinished = _isJuzFinished(computedJuz, surahId, ayahNumber);

    final current = getJuzProgress(computedJuz);
    final newProgress = JuzProgress(
      juzNumber: computedJuz,
      lastReadPage: computedPage,
      lastReadSurahId: surahId,
      lastReadSurahName: surahName,
      lastReadAyah: ayahNumber,
      isCompleted: isFinished ? true : current.isCompleted,
      updatedAt: DateTime.now(),
    );

    _progressMap[computedJuz] = newProgress;

    // Automatically mark previous in-progress Ajza as completed when advancing to higher Juz
    for (int j = 1; j < computedJuz; j++) {
      final prev = getJuzProgress(j);
      if (!prev.isCompleted && prev.status == JuzStatus.inProgress) {
        _progressMap[j] = JuzProgress(
          juzNumber: j,
          lastReadPage: JuzInfo.allAjza[j - 1].endPage,
          isCompleted: true,
          updatedAt: DateTime.now(),
        );
      }
    }

    notifyListeners();
    await _saveToPrefs();
  }

  /// Manually mark a specific Juz as completed
  Future<void> markJuzCompleted(int juzNumber) async {
    final juzInfo = JuzInfo.allAjza[juzNumber - 1];
    _progressMap[juzNumber] = JuzProgress(
      juzNumber: juzNumber,
      lastReadPage: juzInfo.endPage,
      isCompleted: true,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveToPrefs();
  }

  /// Reset progress of a single Juz
  Future<void> resetJuz(int juzNumber) async {
    _progressMap.remove(juzNumber);
    notifyListeners();
    await _saveToPrefs();
  }

  /// Reset the entire Khatma to start from the beginning
  Future<void> resetAll() async {
    _progressMap.clear();
    notifyListeners();
    await _saveToPrefs();
  }
}
