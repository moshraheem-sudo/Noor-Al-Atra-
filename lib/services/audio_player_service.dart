import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioTrackInfo {
  final String title;
  final String subtitle;
  final String url;
  final String? category;

  AudioTrackInfo({
    required this.title,
    required this.subtitle,
    required this.url,
    this.category,
  });
}

class PlayingAyahInfo {
  final int surah;
  final int number;

  const PlayingAyahInfo({required this.surah, required this.number});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingAyahInfo &&
          runtimeType == other.runtimeType &&
          surah == other.surah &&
          number == other.number;

  @override
  int get hashCode => surah.hashCode ^ number.hashCode;
}

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  AudioTrackInfo? _currentTrack;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Quran recitation state
  int? currentSurahId;
  int? currentAyahNum;
  int? totalAyahsInSurah;
  String? currentReciterPath;
  String? currentReciterName;
  bool isContinuousQuranPlayback = false;
  bool _isTransitioningTrack = false;
  int _playGeneration = 0;
  bool get isLoading => _isTransitioningTrack;

  AudioTrackInfo? get currentTrack => _currentTrack;
  PlayerState get playerState => _playerState;
  bool get isPlaying =>
      _playerState == PlayerState.playing ||
      (_isTransitioningTrack && isContinuousQuranPlayback);

  PlayingAyahInfo? get currentPlayingAyah {
    if (currentSurahId != null && currentAyahNum != null) {
      return PlayingAyahInfo(surah: currentSurahId!, number: currentAyahNum!);
    }
    return null;
  }

  Duration get duration => _duration;
  Duration get position => _position;
  VoidCallback? onTrackCompleted;
  void Function(int surahId, int ayahNum)? onAyahChanged;
  void Function(int nextSurahId)? onSurahCompleted;

  StreamSubscription? _stateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  void _init() {
    try {
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
      _player.setReleaseMode(ReleaseMode.stop).catchError((e) {
        debugPrint('setReleaseMode error: $e');
      });
    } catch (e) {
      debugPrint('AudioPlayer init error: $e');
    }

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    }, onError: (e) {
      debugPrint('onPlayerStateChanged error: $e');
    });

    _durationSub = _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    }, onError: (e) {
      debugPrint('onDurationChanged error: $e');
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    }, onError: (e) {
      debugPrint('onPositionChanged error: $e');
    });

    _completeSub = _player.onPlayerComplete.listen((_) async {
      _playerState = PlayerState.completed;
      _position = Duration.zero;
      notifyListeners();
      onTrackCompleted?.call();

      await _handleTrackCompletion();
    }, onError: (e) {
      debugPrint('onPlayerComplete error: $e');
    });
  }

  Future<void> _handleTrackCompletion() async {
    // Automatic continuous Quran progression
    if (isContinuousQuranPlayback &&
        currentSurahId != null &&
        currentAyahNum != null &&
        totalAyahsInSurah != null &&
        currentReciterPath != null) {
      
      final currentSurah = currentSurahId!;
      final currentAyah = currentAyahNum!;
      final totalAyahs = totalAyahsInSurah!;
      final reciterPath = currentReciterPath!;
      final reciterName = currentReciterName ?? 'القارئ';

      if (currentAyah < totalAyahs) {
        // Play next ayah in current surah
        final nextAyahNum = currentAyah + 1;
        await _playAyahWithRetry(
          surahId: currentSurah,
          ayahNum: nextAyahNum,
          totalAyahs: totalAyahs,
          reciterPath: reciterPath,
          reciterName: reciterName,
          continuous: true,
        );
      } else {
        // Current Surah finished! Advance to next surah
        if (currentSurah < 114) {
          final nextSurahId = currentSurah + 1;
          onSurahCompleted?.call(nextSurahId);
        } else {
          stopQuranRecitation();
        }
      }
    }
  }

  Future<void> _playAyahWithRetry({
    required int surahId,
    required int ayahNum,
    required int totalAyahs,
    required String reciterPath,
    required String reciterName,
    required bool continuous,
    int retryCount = 0,
  }) async {
    if (!isContinuousQuranPlayback && continuous == false) return;

    try {
      await playQuranAyah(
        surahId: surahId,
        ayahNum: ayahNum,
        totalAyahs: totalAyahs,
        reciterPath: reciterPath,
        reciterName: reciterName,
        continuous: continuous,
      );
    } catch (e) {
      debugPrint('Error playing ayah $surahId:$ayahNum (attempt $retryCount): $e');
      if (retryCount < 2 && isContinuousQuranPlayback) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _playAyahWithRetry(
          surahId: surahId,
          ayahNum: ayahNum,
          totalAyahs: totalAyahs,
          reciterPath: reciterPath,
          reciterName: reciterName,
          continuous: continuous,
          retryCount: retryCount + 1,
        );
      } else if (isContinuousQuranPlayback && ayahNum < totalAyahs) {
        // Skip ahead to the next verse if current one is unreachable
        debugPrint('Skipping to next ayah due to repeated network error...');
        await _playAyahWithRetry(
          surahId: surahId,
          ayahNum: ayahNum + 1,
          totalAyahs: totalAyahs,
          reciterPath: reciterPath,
          reciterName: reciterName,
          continuous: continuous,
          retryCount: 0,
        );
      }
    }
  }

  /// Returns the local directory for per-ayah offline MP3 files for a reciter & surah.
  static Future<Directory> getAyahAudioDir(String reciterPath, int surahId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final safeFolder = reciterPath.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final s = surahId.toString().padLeft(3, '0');
    return Directory('${docDir.path}/quran_audio/ayahs/$safeFolder/$s');
  }

  /// Checks if an individual ayah MP3 is downloaded locally for offline playback.
  static Future<String?> findLocalAyahAudioPath(
    String reciterPath,
    int surahId,
    int ayahNum,
  ) async {
    try {
      final dir = await getAyahAudioDir(reciterPath, surahId);
      final a = ayahNum.toString().padLeft(3, '0');
      final file = File('${dir.path}/$a.mp3');
      if (await file.exists() && await file.length() > 1024) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Start playing an Ayah from local offline storage if available, otherwise EveryAyah URL:
  /// https://everyayah.com/data/{reciter_path}/{surah_3_digits}{ayah_3_digits}.mp3
  Future<void> playQuranAyah({
    required int surahId,
    required int ayahNum,
    required int totalAyahs,
    required String reciterPath,
    String reciterName = 'القارئ',
    bool continuous = true,
  }) async {
    isContinuousQuranPlayback = continuous;
    currentSurahId = surahId;
    currentAyahNum = ayahNum;
    totalAyahsInSurah = totalAyahs;
    currentReciterPath = reciterPath;
    currentReciterName = reciterName;

    final s = surahId.toString().padLeft(3, '0');
    final a = ayahNum.toString().padLeft(3, '0');
    final localPath = await findLocalAyahAudioPath(reciterPath, surahId, ayahNum);
    final sourceUrl = localPath ?? 'https://everyayah.com/data/$reciterPath/$s$a.mp3';

    onAyahChanged?.call(surahId, ayahNum);
    notifyListeners();

    await playTrack(
      AudioTrackInfo(
        title: 'سورة $surahId - آية $ayahNum',
        subtitle: reciterName,
        url: sourceUrl,
        category: 'quran_verse',
      ),
    );
  }

  Future<void> nextAyah() async {
    if (currentSurahId != null &&
        currentAyahNum != null &&
        totalAyahsInSurah != null &&
        currentReciterPath != null &&
        currentAyahNum! < totalAyahsInSurah!) {
      await playQuranAyah(
        surahId: currentSurahId!,
        ayahNum: currentAyahNum! + 1,
        totalAyahs: totalAyahsInSurah!,
        reciterPath: currentReciterPath!,
        reciterName: currentReciterName ?? 'القارئ',
        continuous: isContinuousQuranPlayback,
      );
    }
  }

  Future<void> previousAyah() async {
    if (currentSurahId != null &&
        currentAyahNum != null &&
        totalAyahsInSurah != null &&
        currentReciterPath != null &&
        currentAyahNum! > 1) {
      await playQuranAyah(
        surahId: currentSurahId!,
        ayahNum: currentAyahNum! - 1,
        totalAyahs: totalAyahsInSurah!,
        reciterPath: currentReciterPath!,
        reciterName: currentReciterName ?? 'القارئ',
        continuous: isContinuousQuranPlayback,
      );
    }
  }

  void stopQuranRecitation() {
    isContinuousQuranPlayback = false;
    currentSurahId = null;
    currentAyahNum = null;
    totalAyahsInSurah = null;
    stop();
  }

  static String _sanitizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    try {
      final uri = Uri.parse(url);
      if (uri.hasScheme) {
        return uri.toString();
      }
      return Uri.encodeFull(url);
    } catch (_) {
      try {
        final decoded = Uri.decodeFull(url);
        return Uri.encodeFull(decoded);
      } catch (_) {
        return url;
      }
    }
  }

  Future<void> playTrack(AudioTrackInfo track) async {
    final generation = ++_playGeneration;
    _isTransitioningTrack = true;
    try {
      if (track.category != 'quran_verse' && track.category != 'quran_surah') {
        isContinuousQuranPlayback = false;
        currentSurahId = null;
        currentAyahNum = null;
        totalAyahsInSurah = null;
        currentReciterName = null;
        currentReciterPath = null;
      }

      if (_currentTrack?.url == track.url) {
        if (_playerState == PlayerState.playing) {
          await _player.pause();
          _isTransitioningTrack = false;
          return;
        } else if (_playerState == PlayerState.paused) {
          _playerState = PlayerState.playing;
          notifyListeners();
          await _player.resume();
          _isTransitioningTrack = false;
          return;
        }
      }

      _currentTrack = track;
      _position = Duration.zero;
      _duration = Duration.zero;
      _playerState = PlayerState.playing;
      notifyListeners();

      try {
        await _player.stop();
      } catch (_) {}

      if (generation != _playGeneration) return;
      final rawUrl = track.url.trim();
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        await _player.play(UrlSource(_sanitizeUrl(rawUrl)));
      } else {
        // Resolve local file path without URL-encoding spaces (critical for iOS & Android offline playback)
        String localPath = rawUrl;
        if (localPath.startsWith('file://')) {
          try {
            localPath = Uri.parse(localPath).toFilePath();
          } catch (_) {
            localPath = localPath.replaceFirst('file://', '');
          }
        }
        await _player.play(DeviceFileSource(localPath));
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
      if (generation == _playGeneration) _playerState = PlayerState.stopped;
    } finally {
      if (generation == _playGeneration) {
        _isTransitioningTrack = false;
        _playerState = _player.state;
        notifyListeners();
      }
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _playerState = _player.state;
      notifyListeners();
    } catch (e) {
      debugPrint('Audio pause error: $e');
    }
  }

  Future<void> resume() async {
    if (_currentTrack == null) return;
    if (_playerState == PlayerState.completed || _playerState == PlayerState.stopped) {
      await playTrack(_currentTrack!);
      return;
    }
    try {
      await _player.resume();
      _playerState = _player.state;
      notifyListeners();
    } catch (e) {
      debugPrint('Audio resume error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration pos) async {
    if (_currentTrack == null || _duration <= Duration.zero) return;
    final target = Duration(milliseconds: pos.inMilliseconds.clamp(0, _duration.inMilliseconds));
    try {
      await _player.seek(target);
      _position = target;
      notifyListeners();
    } catch (e) {
      debugPrint('Audio seek error: $e');
    }
  }

  Future<void> stop() async {
    ++_playGeneration;
    _isTransitioningTrack = false;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
    _currentTrack = null;
    _playerState = PlayerState.stopped;
    _position = Duration.zero;
    _duration = Duration.zero;
    isContinuousQuranPlayback = false;
    currentSurahId = null;
    currentAyahNum = null;
    totalAyahsInSurah = null;
    currentReciterName = null;
    currentReciterPath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

