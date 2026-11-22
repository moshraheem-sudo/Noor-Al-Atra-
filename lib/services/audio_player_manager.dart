import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quran_chapter.dart';
import '../models/reciter.dart';
import 'quran_api_service.dart';
import 'audio_player_service.dart';

class AudioPlayerManager extends ChangeNotifier {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  AudioPlayerManager._internal() {
    _init();
  }

  final AudioPlayerService _service = AudioPlayerService();

  // State
  bool _isLooping = false;
  int? _currentSurahId;
  String? _currentSurahName;
  ReciterItem? _currentReciter;
  ReciterStyle? _currentStyle;

  // Sleep timer
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;
  DateTime? _sleepTimerEndTime;

  // Getters forwarded to / backed by AudioPlayerService
  AudioTrackInfo? get currentTrack => _service.currentTrack;
  PlayerState get playerState => _service.playerState;
  bool get isPlaying => _service.isPlaying;
  Duration get duration => _service.duration;
  Duration get position => _service.position;
  bool get isLooping => _isLooping;
  int? get currentSurahId => _currentSurahId;
  String? get currentSurahName => _currentSurahName;
  ReciterItem? get currentReciter => _currentReciter;
  ReciterStyle? get currentStyle => _currentStyle;
  int? get sleepTimerMinutes => _sleepTimerMinutes;

  int? get remainingSleepSeconds {
    if (_sleepTimerEndTime == null) return null;
    final diff = _sleepTimerEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void _init() {
    _service.addListener(_onServiceUpdate);

    _service.onTrackCompleted = () async {
      final track = currentTrack;
      if (track != null && track.category == 'quran_surah') {
        if (_isLooping) {
          await playTrack(track);
        } else if (_currentSurahId != null && _currentSurahId! < 114) {
          await playNextSurah();
        } else {
          await stop();
        }
      }
    };
  }

  void _onServiceUpdate() {
    notifyListeners();
  }

  /// Play a specific track directly
  Future<void> playTrack(AudioTrackInfo track) async {
    if (track.category != 'quran_surah') {
      _currentSurahId = null;
      _currentSurahName = null;
      _currentReciter = null;
      _currentStyle = null;
      _service.currentSurahId = null;
      _service.currentAyahNum = null;
      _service.totalAyahsInSurah = null;
      _service.currentReciterName = null;
      _service.currentReciterPath = null;
      _service.isContinuousQuranPlayback = false;
    }
    notifyListeners();
    try {
      await _service.playTrack(track);
    } catch (e) {
      debugPrint('AudioPlayerManager playTrack error: $e');
    }
  }

  /// Play a full Surah for a specific reciter
  Future<void> playSurah({
    required int surahId,
    required ReciterItem reciter,
    ReciterStyle? style,
    String? localPath,
  }) async {
    final chapter = QuranChapter.allChapters.firstWhere(
      (c) => c.id == surahId,
      orElse: () => QuranChapter(id: surahId, nameArabic: 'سورة $surahId', nameSimple: '', revelationPlace: '', versesCount: 0),
    );

    _currentSurahId = surahId;
    _currentSurahName = 'سورة ${chapter.nameArabic}';
    _currentReciter = reciter;
    _currentStyle = style;

    // Halt any ongoing verse recitation
    _service.isContinuousQuranPlayback = false;

    String audioUrl;
    if (localPath != null && await File(localPath).exists()) {
      audioUrl = localPath;
    } else {
      final server = (style != null && style.server.isNotEmpty)
          ? style.server
          : reciter.defaultServer;
      audioUrl = QuranApiService.getSurahAudioUrl(server, surahId);
    }

    final track = AudioTrackInfo(
      title: 'سورة ${chapter.nameArabic}',
      subtitle: reciter.name,
      url: audioUrl,
      category: 'quran_surah',
    );

    await playTrack(track);

    _service.currentSurahId = surahId;
    _service.currentReciterName = reciter.name;
    _service.currentReciterPath = reciter.everyAyahFolder;
    notifyListeners();
  }

  /// Toggle Play / Pause
  Future<void> togglePlayPause() async {
    await _service.togglePlayPause();
    notifyListeners();
  }

  Future<void> pause() async {
    await _service.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _service.resume();
    notifyListeners();
  }

  Future<void> stop() async {
    await _service.stop();
    _currentSurahId = null;
    _currentSurahName = null;
    _currentReciter = null;
    _currentStyle = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _service.seek(position);
  }

  Future<void> forward10() async {
    final newPos = _service.position + const Duration(seconds: 10);
    if (newPos > _service.duration) {
      await _service.seek(_service.duration);
    } else {
      await _service.seek(newPos);
    }
  }

  Future<void> replay10() async {
    final newPos = _service.position - const Duration(seconds: 10);
    if (newPos < Duration.zero) {
      await _service.seek(Duration.zero);
    } else {
      await _service.seek(newPos);
    }
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  Future<void> playNextSurah() async {
    if (_currentSurahId != null && _currentSurahId! < 114 && _currentReciter != null) {
      await playSurah(
        surahId: _currentSurahId! + 1,
        reciter: _currentReciter!,
        style: _currentStyle,
      );
    }
  }

  Future<void> playPreviousSurah() async {
    if (_currentSurahId != null && _currentSurahId! > 1 && _currentReciter != null) {
      await playSurah(
        surahId: _currentSurahId! - 1,
        reciter: _currentReciter!,
        style: _currentStyle,
      );
    }
  }

  // --- Sleep Timer ---
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
    notifyListeners();

    _sleepTimer = Timer(Duration(minutes: minutes), () async {
      await pause();
      _sleepTimer = null;
      _sleepTimerMinutes = null;
      _sleepTimerEndTime = null;
      notifyListeners();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerMinutes = null;
    _sleepTimerEndTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _sleepTimer?.cancel();
    super.dispose();
  }
}
