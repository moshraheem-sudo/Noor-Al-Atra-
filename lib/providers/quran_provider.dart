import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/quran_bookmark.dart';
import '../models/quran_chapter.dart';
import '../models/reciter.dart';
import '../services/quran_api_service.dart';
import '../services/storage_service.dart';

class QuranProvider extends ChangeNotifier {
  int _lastReadSurah = 1;
  int _lastReadAyah = 1;
  double _fontSize = 20.0;
  List<VerseItem> _currentVerses = [];
  bool _isLoadingVerses = false;
  ReciterItem _selectedReciter = ReciterItem.popularReciters[0];
  List<ReciterStyle> _reciterStyles = [];
  int _selectedStyleIndex = 0;
  List<QuranBookmark> _bookmarks = [];
  String _readingMode = 'uthmani'; // 'classic' or 'uthmani'

  int get lastReadSurah => _lastReadSurah;
  int get lastReadAyah => _lastReadAyah;
  double get fontSize => _fontSize;
  List<VerseItem> get currentVerses => _currentVerses;
  bool get isLoadingVerses => _isLoadingVerses;
  ReciterItem get selectedReciter => _selectedReciter;
  List<ReciterStyle> get reciterStyles => _reciterStyles;
  int get selectedStyleIndex => _selectedStyleIndex;
  List<QuranBookmark> get bookmarks => List.unmodifiable(_bookmarks);
  String get readingMode => _readingMode;
  bool get isUthmanicMode => true;
  ReciterStyle? get currentStyle =>
      _reciterStyles.isNotEmpty && _selectedStyleIndex < _reciterStyles.length
          ? _reciterStyles[_selectedStyleIndex]
          : null;

  QuranProvider() {
    _init();
  }

  void _init() {
    _lastReadSurah = StorageService().getLastReadSurah();
    _lastReadAyah = StorageService().getLastReadAyah();
    _fontSize = StorageService().getFontSize();
    _readingMode = 'uthmani';
    _loadBookmarks();
    loadReciterStyles(_selectedReciter.id);
    // Background download and preload of all 114 Surahs
    QuranApiService.preloadAllSurahsInBackground();
  }

  void _loadBookmarks() {
    try {
      final rawList = StorageService().getQuranBookmarks();
      _bookmarks = rawList
          .map((s) => QuranBookmark.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      _bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final rawList = _bookmarks.map((b) => jsonEncode(b.toJson())).toList();
      await StorageService().setQuranBookmarks(rawList);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  bool isAyahBookmarked(int surahId, int ayahNum) {
    return _bookmarks.any((b) => b.surahId == surahId && b.ayahNumber == ayahNum);
  }

  /// Toggles bookmark for an ayah. Returns true if added, false if removed.
  Future<bool> toggleBookmark({
    required int surahId,
    required String surahName,
    required int ayahNum,
    int? pageNumber,
    required String verseText,
  }) async {
    final existingIndex = _bookmarks.indexWhere((b) => b.surahId == surahId && b.ayahNumber == ayahNum);
    bool added = false;
    if (existingIndex >= 0) {
      _bookmarks.removeAt(existingIndex);
      added = false;
    } else {
      final newBookmark = QuranBookmark(
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNum,
        pageNumber: pageNumber ?? 1,
        ayahText: verseText,
        createdAt: DateTime.now(),
      );
      _bookmarks.insert(0, newBookmark);
      added = true;
    }

    _lastReadSurah = surahId;
    _lastReadAyah = ayahNum;
    await StorageService().setLastRead(surahId, ayahNum);

    await _saveBookmarks();
    notifyListeners();
    return added;
  }

  Future<void> removeBookmark(int surahId, int ayahNum) async {
    _bookmarks.removeWhere((b) => b.surahId == surahId && b.ayahNumber == ayahNum);
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await StorageService().setFontSize(size);
    notifyListeners();
  }

  Future<void> setReadingMode(String mode) async {
    _readingMode = 'uthmani';
    await StorageService().setQuranReadingMode('uthmani');
    notifyListeners();
  }

  Future<void> setLastRead(int surah, int ayah) async {
    _lastReadSurah = surah;
    _lastReadAyah = ayah;
    await StorageService().setLastRead(surah, ayah);
    notifyListeners();
  }

  Future<void> loadVerses(int chapterNumber) async {
    // 1. Check if verses are already in memory for instant display (no loading spinner)
    final cached = QuranApiService.getCachedVerses(chapterNumber);
    if (cached != null && cached.isNotEmpty) {
      _currentVerses = cached;
      _isLoadingVerses = false;
      notifyListeners();
      return;
    }

    _isLoadingVerses = true;
    _currentVerses = [];
    notifyListeners();

    _currentVerses = await QuranApiService.getVerses(chapterNumber);
    _isLoadingVerses = false;
    notifyListeners();
  }

  Future<void> selectReciter(ReciterItem reciter) async {
    _selectedReciter = reciter;
    _selectedStyleIndex = 0;
    notifyListeners();
    await loadReciterStyles(reciter.id);
  }

  Future<void> loadReciterStyles(int reciterId) async {
    _reciterStyles = await QuranApiService.getReciterStyles(reciterId);
    if (_reciterStyles.isEmpty) {
      String fallbackServer = 'https://server7.mp3quran.net/basit/';
      if (reciterId == 108) fallbackServer = 'https://server8.mp3quran.net/afs/';
      if (reciterId == 104) fallbackServer = 'https://server12.mp3quran.net/maher/';
      if (reciterId == 112) fallbackServer = 'https://server10.mp3quran.net/minsh/';
      if (reciterId == 118) fallbackServer = 'https://server13.mp3quran.net/husr/';
      if (reciterId == 30) fallbackServer = 'https://server7.mp3quran.net/s_gmd/';
      if (reciterId == 81) fallbackServer = 'https://server8.mp3quran.net/frs_a/';
      if (reciterId == 125) fallbackServer = 'https://server8.mp3quran.net/mustafa/';
      if (reciterId == 13) fallbackServer = 'https://server11.mp3quran.net/shatri/';
      if (reciterId == 150) fallbackServer = 'https://server14.mp3quran.net/tammar/';
      if (reciterId == 151) fallbackServer = 'https://server16.mp3quran.net/a_kadhimi/';

      // Default fallback style
      _reciterStyles = [
        ReciterStyle(
          id: 1,
          name: 'المصحف المرتل',
          server: fallbackServer,
          surahList: List.generate(114, (i) => i + 1).join(','),
        )
      ];
    }
    _selectedStyleIndex = 0;
    notifyListeners();
  }

  void selectStyle(int index) {
    if (index >= 0 && index < _reciterStyles.length) {
      _selectedStyleIndex = index;
      notifyListeners();
    }
  }
}
