import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class MuezzinItem {
  final String id;
  final String name;
  final String title;
  final String cdnUrl;
  final String fallbackUrl;
  final String durationText;

  const MuezzinItem({
    required this.id,
    required this.name,
    required this.title,
    required this.cdnUrl,
    required this.fallbackUrl,
    this.durationText = '03:45',
  });
}

class MuezzinDownloadService {
  static final MuezzinDownloadService _instance = MuezzinDownloadService._internal();
  factory MuezzinDownloadService() => _instance;
  MuezzinDownloadService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;

  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _playerState == PlayerState.playing;

  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};

  double getDownloadProgress(String id) => _downloadProgress[id] ?? 0.0;
  bool isMuezzinDownloading(String id) => _isDownloading[id] ?? false;

  static const List<MuezzinItem> muezzins = [
    MuezzinItem(
      id: 'amer_kazemi',
      name: 'الحاج عامر الكاظمي',
      title: 'مؤذن العتبة الكاظمية المقدسة (الافتراضي)',
      cdnUrl: 'https://cdn.jsdelivr.net/gh/moshraheem-sudo/Muezzin@main/%D8%B9%D8%A7%D9%85%D8%B1%20%D8%A7%D9%84%D9%83%D8%A7%D8%B8%D9%85%D9%8A%20.mp3',
      fallbackUrl: 'https://raw.githubusercontent.com/moshraheem-sudo/Muezzin/main/%D8%B9%D8%A7%D9%85%D8%B1%20%D8%A7%D9%84%D9%83%D8%A7%D8%B8%D9%85%D9%8A%20.mp3',
      durationText: '04:15',
    ),
    MuezzinItem(
      id: 'osama_karbalai',
      name: 'الحاج أسامة الكربلائي',
      title: 'مؤذن العتبتين الحسينية والعباسية المقدستين',
      cdnUrl: 'https://cdn.jsdelivr.net/gh/moshraheem-sudo/Muezzin@main/%D8%A3%D8%B3%D8%A7%D9%85%D8%A9%20%D8%A7%D9%84%D9%83%D8%B1%D8%A8%D9%84%D8%A7%D8%A6%D9%8A%20.mp3',
      fallbackUrl: 'https://raw.githubusercontent.com/moshraheem-sudo/Muezzin/main/%D8%A3%D8%B3%D8%A7%D9%85%D8%A9%20%D8%A7%D9%84%D9%83%D8%B1%D8%A8%D9%84%D8%A7%D8%A6%D9%8A%20.mp3',
      durationText: '03:50',
    ),
    MuezzinItem(
      id: 'rafea_ameri',
      name: 'المقرئ رافع العامري',
      title: 'مقرئ ومؤذن شيعي عراقي متميز',
      cdnUrl: 'https://cdn.jsdelivr.net/gh/moshraheem-sudo/Muezzin@main/%D8%B1%D8%A7%D9%81%D8%B9%20%D8%A7%D9%84%D8%B9%D8%A7%D9%85%D8%B1%D9%8A%20.mp3',
      fallbackUrl: 'https://raw.githubusercontent.com/moshraheem-sudo/Muezzin/main/%D8%B1%D8%A7%D9%81%D8%B9%20%D8%A7%D9%84%D8%B9%D8%A7%D9%85%D8%B1%D9%8A%20.mp3',
      durationText: '03:40',
    ),
    MuezzinItem(
      id: 'buratha_mosque',
      name: 'أذان جامع براثا المعظم',
      title: 'الأذان الروحاني التاريخي لجامع براثا في بغداد',
      cdnUrl: 'https://cdn.jsdelivr.net/gh/moshraheem-sudo/Muezzin@main/%D8%A7%D8%B0%D8%A7%D9%86%20%D8%A8%D8%B1%D8%A7%D8%AB%D8%A7.mp3',
      fallbackUrl: 'https://raw.githubusercontent.com/moshraheem-sudo/Muezzin/main/%D8%A7%D8%B0%D8%A7%D9%86%20%D8%A8%D8%B1%D8%A7%D8%AB%D8%A7.mp3',
      durationText: '04:02',
    ),
    MuezzinItem(
      id: 'abathar_halwachi',
      name: 'المنشد أباذر الحلواجي',
      title: 'الأذان الشجي بصوت الرادود أباذر الحلواجي',
      cdnUrl: 'https://cdn.jsdelivr.net/gh/moshraheem-sudo/Muezzin@main/%D8%A7%D8%A8%D8%A7%D8%B0%D8%B1%20%D8%A7%D9%84%D8%AD%D9%84%D9%88%D8%A7%D8%AC%D9%8A.mp3',
      fallbackUrl: 'https://raw.githubusercontent.com/moshraheem-sudo/Muezzin/main/%D8%A7%D8%A8%D8%A7%D8%B0%D8%B1%20%D8%A7%D9%84%D8%AD%D9%84%D9%88%D8%A7%D8%AC%D9%8A.mp3',
      durationText: '03:30',
    ),
  ];

  Future<String> _getStoragePath(String id) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final adhanDir = Directory('${docsDir.path}/muezzin_audio');
    if (!adhanDir.existsSync()) {
      adhanDir.createSync(recursive: true);
    }
    return '${adhanDir.path}/$id.mp3';
  }

  Future<bool> isMuezzinDownloaded(String id) async {
    try {
      final filePath = await _getStoragePath(id);
      final file = File(filePath);
      return file.existsSync() && file.lengthSync() > 1024;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getLocalMuezzinPath(String id) async {
    final downloaded = await isMuezzinDownloaded(id);
    if (downloaded) {
      return await _getStoragePath(id);
    }
    return null;
  }

  Future<bool> downloadMuezzin(
    MuezzinItem muezzin, {
    void Function(double progress)? onProgress,
  }) async {
    _isDownloading[muezzin.id] = true;
    _downloadProgress[muezzin.id] = 0.0;

    try {
      final targetPath = await _getStoragePath(muezzin.id);
      final file = File(targetPath);

      // Try primary CDN URL first
      http.Response response;
      try {
        final uri = Uri.parse(muezzin.cdnUrl);
        response = await http.get(uri).timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) {
          throw Exception('CDN status ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Primary CDN failed for ${muezzin.name}, trying fallback: $e');
        final fallbackUri = Uri.parse(muezzin.fallbackUrl);
        response = await http.get(fallbackUri).timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) {
          throw Exception('Fallback status ${response.statusCode}');
        }
      }

      await file.writeAsBytes(response.bodyBytes);
      _downloadProgress[muezzin.id] = 1.0;
      onProgress?.call(1.0);
      _isDownloading[muezzin.id] = false;
      return true;
    } catch (e) {
      debugPrint('Error downloading muezzin ${muezzin.name}: $e');
      _isDownloading[muezzin.id] = false;
      return false;
    }
  }

  /// Automatically downloads all Muezzin full audios in background upon app startup
  Future<void> downloadAllMuezzinsInBackground() async {
    try {
      for (final muezzin in muezzins) {
        final isDownloaded = await isMuezzinDownloaded(muezzin.id);
        if (!isDownloaded) {
          debugPrint('Starting background download for muezzin: ${muezzin.name}');
          await downloadMuezzin(muezzin);
        }
      }
      debugPrint('All muezzin audios are verified and downloaded locally.');
    } catch (e) {
      debugPrint('Error in background muezzin downloads: $e');
    }
  }

  Future<void> playPreview(
    MuezzinItem muezzin, {
    required VoidCallback onStateChange,
  }) async {
    if (_currentlyPlayingId == muezzin.id && _playerState == PlayerState.playing) {
      await stopPreview();
      onStateChange();
      return;
    }

    await _audioPlayer.stop();
    _currentlyPlayingId = muezzin.id;

    final localPath = await getLocalMuezzinPath(muezzin.id);
    if (localPath != null) {
      await _audioPlayer.play(DeviceFileSource(localPath));
    } else {
      // Stream directly from CDN
      await _audioPlayer.play(UrlSource(muezzin.cdnUrl));
    }

    _playerState = PlayerState.playing;
    onStateChange();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentlyPlayingId = null;
      }
      onStateChange();
    });
  }

  Future<void> stopPreview() async {
    await _audioPlayer.stop();
    _currentlyPlayingId = null;
    _playerState = PlayerState.stopped;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
