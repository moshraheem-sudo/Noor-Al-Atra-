import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quran_chapter.dart';
import '../models/reciter.dart';
import 'quran_api_service.dart';
import 'quran_audio_download_service.dart';
import 'audio_player_service.dart';
import 'media_audio_handler.dart';

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

  List<AudioTrackInfo> _playlist = const [];

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
      if (track == null) return;
      if (_isLooping) {
        await playTrack(track);
      } else if (track.category == 'quran_surah') {
        if (_currentSurahId != null && _currentSurahId! < 114) {
          await playNextSurah();
        } else {
          await stop();
        }
      } else if (track.category != 'quran_verse') {
        if (canGoNext) {
          await nextTrack();
        } else {
          await stop();
        }
      }
    };
  }

  void _onServiceUpdate() {
    final track = _service.currentTrack;
    if (track != null && track.category != 'quran_surah') {
      _currentSurahId = null;
      _currentSurahName = null;
      _currentReciter = null;
      _currentStyle = null;
    }
    if (track != null && !_playlist.any((t) => t.url == track.url)) {
      _playlist = const [];
    }
    if (track == null) cancelSleepTimer();
    notifyListeners();
  }

  /// Play a specific track directly
  Future<void> playTrack(AudioTrackInfo track) async {
    await initializeMediaAudio();
    if (track.category != 'quran_surah' && track.category != 'quran_verse') {
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

  Future<void> playPlaylist(List<AudioTrackInfo> tracks, int index) async {
    if (index < 0 || index >= tracks.length) return;
    _playlist = List.unmodifiable(tracks);
    await playTrack(tracks[index]);
  }

  int get _playlistIndex => _playlist.indexWhere((track) => track.url == currentTrack?.url);
  bool get canGoNext => currentTrack?.category == 'quran_verse'
      ? (_service.currentAyahNum ?? 0) < (_service.totalAyahsInSurah ?? 0)
      : _currentSurahId != null ? _currentSurahId! < 114
      : _playlistIndex >= 0 && _playlistIndex < _playlist.length - 1;
  bool get canGoPrevious => currentTrack?.category == 'quran_verse'
      ? (_service.currentAyahNum ?? 0) > 1
      : _currentSurahId != null ? _currentSurahId! > 1 : _playlistIndex > 0;
  Future<void> nextTrack() async {
    if (!canGoNext) return;
    if (currentTrack?.category == 'quran_verse') { await _service.nextAyah(); }
    else if (_currentSurahId != null) { await playNextSurah(); }
    else { await playTrack(_playlist[_playlistIndex + 1]); }
  }
  Future<void> previousTrack() async {
    if (!canGoPrevious) return;
    if (currentTrack?.category == 'quran_verse') { await _service.previousAyah(); }
    else if (_currentSurahId != null) { await playPreviousSurah(); }
    else { await playTrack(_playlist[_playlistIndex - 1]); }
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
    _service.currentAyahNum = null;
    _service.totalAyahsInSurah = null;

    String audioUrl;
    if (localPath != null && await File(localPath).exists()) {
      audioUrl = localPath;
    } else {
      final server = (style != null && style.server.isNotEmpty)
          ? style.server
          : reciter.defaultServer;
      audioUrl = QuranApiService.getSurahAudioUrl(server, surahId);
    }

    final trackSubtitle = style != null
        ? '${reciter.name} • ${style.displayName}'
        : reciter.name;

    final track = AudioTrackInfo(
      title: 'سورة ${chapter.nameArabic}',
      subtitle: trackSubtitle,
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
    cancelSleepTimer();
    _playlist = const [];
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
      final nextId = _currentSurahId! + 1;
      final localPath = QuranAudioDownloadService().getLocalSurahPath(
        _currentReciter!.id,
        nextId,
        styleId: _currentStyle?.id,
      );
      await playSurah(
        surahId: nextId,
        reciter: _currentReciter!,
        style: _currentStyle,
        localPath: localPath,
      );
    }
  }

  Future<void> playPreviousSurah() async {
    if (_currentSurahId != null && _currentSurahId! > 1 && _currentReciter != null) {
      final prevId = _currentSurahId! - 1;
      final localPath = QuranAudioDownloadService().getLocalSurahPath(
        _currentReciter!.id,
        prevId,
        styleId: _currentStyle?.id,
      );
      await playSurah(
        surahId: prevId,
        reciter: _currentReciter!,
        style: _currentStyle,
        localPath: localPath,
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
