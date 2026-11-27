import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/quran_chapter.dart';
import '../models/reciter.dart';

class QuranAudioDownloadService extends ChangeNotifier {
  static final QuranAudioDownloadService _instance = QuranAudioDownloadService._internal();
  factory QuranAudioDownloadService() => _instance;
  QuranAudioDownloadService._internal() {
    _init();
  }

  static const Map<int, String> reciterServers = {
    108: 'https://server8.mp3quran.net/afs/',
    51: 'https://server7.mp3quran.net/basit/',
    118: 'https://server13.mp3quran.net/husr/',
    112: 'https://server10.mp3quran.net/minsh/',
    104: 'https://server12.mp3quran.net/maher/',
    13: 'https://server11.mp3quran.net/shatri/',
  };

  bool _isDownloading = false;
  bool _isPaused = false;
  bool _isCancelled = false;
  ReciterItem? _currentReciter;
  int? _currentStyleId;
  int _currentSurahIndex = 0; // 1..114
  String _currentSurahName = '';
  int _downloadedCountInBatch = 0;
  double _progress = 0.0;
  String? _statusMessage;

  final Map<int, int> _downloadedCounts = {}; // reciterId -> total count across styles
  final Map<String, int> _styleDownloadedCounts = {}; // "reciterId:styleId" -> count
  final Map<String, double> _singleSurahProgress = {}; // key -> progress 0.0..1.0

  bool get isDownloading => _isDownloading;
  bool get isPaused => _isPaused;
  ReciterItem? get currentReciter => _currentReciter;
  int? get currentStyleId => _currentStyleId;
  int get currentSurahIndex => _currentSurahIndex;
  String get currentSurahName => _currentSurahName;
  int get downloadedCountInBatch => _downloadedCountInBatch;
  double get progress => _progress;
  String? get statusMessage => _statusMessage;

  String? _baseAudioDirPath;
  final Set<String> _downloadedSurahKeys = {}; // "reciterId:styleKey:surahId"

  String _surahKey(int reciterId, int surahId, {int? styleId}) =>
      '$reciterId:${styleId ?? 'default'}:$surahId';

  String _styleCountKey(int reciterId, int styleId) => '$reciterId:$styleId';

  bool isSurahDownloading(int reciterId, int surahId, {int? styleId}) {
    return _singleSurahProgress.containsKey(_surahKey(reciterId, surahId, styleId: styleId));
  }

  double? getSurahDownloadProgress(int reciterId, int surahId, {int? styleId}) {
    return _singleSurahProgress[_surahKey(reciterId, surahId, styleId: styleId)];
  }

  Future<void> _init() async {
    await refreshDownloadedCounts();
  }

  Future<Directory> _getReciterDir(int reciterId, {int? styleId}) async {
    final docs = await getApplicationDocumentsDirectory();
    _baseAudioDirPath = '${docs.path}/quran_audio';
    final path = styleId != null
        ? '$_baseAudioDirPath/$reciterId/style_$styleId'
        : '$_baseAudioDirPath/$reciterId';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Refreshes the downloaded surahs count for all reciters and styles
  Future<void> refreshDownloadedCounts() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      _baseAudioDirPath = '${docs.path}/quran_audio';
      _downloadedSurahKeys.clear();
      _downloadedCounts.clear();
      _styleDownloadedCounts.clear();

      final baseDir = Directory(_baseAudioDirPath!);
      if (await baseDir.exists()) {
        for (final entity in baseDir.listSync().whereType<Directory>()) {
          final folderName = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
          final reciterId = int.tryParse(folderName);
          if (reciterId == null) continue;

          int totalForReciter = 0;

          // 1. Legacy/default root files for this reciter
          final rootFiles = entity.listSync().whereType<File>().where((f) {
            return f.path.endsWith('.mp3') && f.lengthSync() > 2048;
          }).toList();
          for (final f in rootFiles) {
            final fileName = f.uri.pathSegments.last;
            final surahId = int.tryParse(fileName.replaceAll('.mp3', ''));
            if (surahId != null) {
              _downloadedSurahKeys.add(_surahKey(reciterId, surahId));
            }
          }
          totalForReciter += rootFiles.length;

          // 2. Style-specific subdirectories (style_<id>)
          for (final sub in entity.listSync().whereType<Directory>()) {
            final subName = sub.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
            if (!subName.startsWith('style_')) continue;
            final styleId = int.tryParse(subName.substring('style_'.length));
            if (styleId == null) continue;

            final styleFiles = sub.listSync().whereType<File>().where((f) {
              return f.path.endsWith('.mp3') && f.lengthSync() > 2048;
            }).toList();
            for (final f in styleFiles) {
              final fileName = f.uri.pathSegments.last;
              final surahId = int.tryParse(fileName.replaceAll('.mp3', ''));
              if (surahId != null) {
                _downloadedSurahKeys.add(_surahKey(reciterId, surahId, styleId: styleId));
              }
            }
            _styleDownloadedCounts[_styleCountKey(reciterId, styleId)] = styleFiles.length;
            totalForReciter += styleFiles.length;
          }

          _downloadedCounts[reciterId] = totalForReciter;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing downloaded counts: $e');
    }
  }

  int getCachedDownloadedCount(int reciterId, {int? styleId}) {
    if (styleId != null) {
      return _styleDownloadedCounts[_styleCountKey(reciterId, styleId)] ?? 0;
    }
    return _downloadedCounts[reciterId] ?? 0;
  }

  bool isReciterComplete(int reciterId, {int? styleId}) {
    return getCachedDownloadedCount(reciterId, styleId: styleId) >= 114;
  }

  /// Synchronous check if a specific surah is downloaded for a reciter (and optional style)
  bool isSurahDownloaded(int reciterId, int surahId, {int? styleId}) {
    return _downloadedSurahKeys.contains(_surahKey(reciterId, surahId, styleId: styleId));
  }

  /// Synchronous local file path lookup for instant offline playback
  String? getLocalSurahPath(int reciterId, int surahId, {int? styleId}) {
    if (_downloadedSurahKeys.contains(_surahKey(reciterId, surahId, styleId: styleId)) &&
        _baseAudioDirPath != null) {
      final s = surahId.toString().padLeft(3, '0');
      if (styleId != null) {
        return '$_baseAudioDirPath/$reciterId/style_$styleId/$s.mp3';
      }
      return '$_baseAudioDirPath/$reciterId/$s.mp3';
    }
    return null;
  }

  /// Get how many surahs are locally downloaded for a reciter (and optional style)
  Future<int> getDownloadedCount(int reciterId, {int? styleId}) async {
    try {
      final dir = await _getReciterDir(reciterId, styleId: styleId);
      final files = dir.listSync().whereType<File>().where((f) {
        return f.path.endsWith('.mp3') && f.lengthSync() > 2048;
      }).toList();
      return files.length;
    } catch (_) {
      return 0;
    }
  }

  /// Async check for local audio file path
  Future<String?> findLocalSurahAudioPath(int reciterId, int surahId, {int? styleId}) async {
    try {
      final dir = await _getReciterDir(reciterId, styleId: styleId);
      final s = surahId.toString().padLeft(3, '0');
      final file = File('${dir.path}/$s.mp3');
      if (await file.exists() && await file.length() > 2048) {
        _downloadedSurahKeys.add(_surahKey(reciterId, surahId, styleId: styleId));
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Start or resume background download of all 114 Surahs for a reciter
  Future<void> startDownload(ReciterItem reciter, {String? serverUrl, int? styleId}) async {
    if (_isDownloading && _currentReciter?.id == reciter.id && _currentStyleId == styleId) {
      if (_isPaused) {
        resumeDownload();
      }
      return;
    }

    if (_isDownloading) {
      // Cancel previous download before starting new
      cancelDownload();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isDownloading = true;
    _isPaused = false;
    _isCancelled = false;
    _currentReciter = reciter;
    _currentStyleId = styleId;
    _currentSurahIndex = 1;
    _progress = 0.0;
    _statusMessage = 'بدء تحميل مصحف ${reciter.name}...';
    notifyListeners();

    final server = (serverUrl != null && serverUrl.isNotEmpty)
        ? serverUrl
        : (reciterServers[reciter.id] ?? 'https://server8.mp3quran.net/afs/');
    final cleanServer = server.endsWith('/') ? server : '$server/';
    final dir = await _getReciterDir(reciter.id, styleId: styleId);

    try {
      final client = http.Client();

      for (int ch = 1; ch <= 114; ch++) {
        if (_isCancelled) break;

        while (_isPaused && !_isCancelled) {
          await Future.delayed(const Duration(milliseconds: 400));
        }

        if (_isCancelled) break;

        _currentSurahIndex = ch;
        final chapterObj = QuranChapter.allChapters.firstWhere(
          (c) => c.id == ch,
          orElse: () => QuranChapter(id: ch, nameArabic: '$ch', nameSimple: '', revelationPlace: '', versesCount: 0),
        );
        _currentSurahName = chapterObj.nameArabic;
        _progress = (ch - 1) / 114.0;
        _statusMessage = 'جاري تحميل سورة $_currentSurahName ($ch / 114)...';
        notifyListeners();

        final s = ch.toString().padLeft(3, '0');
        final targetFile = File('${dir.path}/$s.mp3');

        // Check if already downloaded
        if (await targetFile.exists() && await targetFile.length() > 5000) {
          _downloadedSurahKeys.add(_surahKey(reciter.id, ch, styleId: styleId));
          _downloadedCountInBatch = ch;
          if (styleId != null) {
            _styleDownloadedCounts[_styleCountKey(reciter.id, styleId)] = ch;
          } else {
            _downloadedCounts[reciter.id] = ch;
          }
          continue;
        }

        final audioUrl = '$cleanServer$s.mp3';
        for (int attempt = 0; attempt < 3; attempt++) {
          if (_isCancelled) break;
          try {
            final req = http.Request('GET', Uri.parse(audioUrl));
            req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NoorAlAtra/1.0';
            final streamedResponse = await client.send(req).timeout(const Duration(seconds: 40));

            if (streamedResponse.statusCode == 200) {
              final tempFile = File('${dir.path}/$s.tmp');
              final sink = tempFile.openWrite();
              await streamedResponse.stream.pipe(sink);
              await sink.flush();
              await sink.close();

              if (await tempFile.exists() && await tempFile.length() > 5000) {
                if (await targetFile.exists()) {
                  await targetFile.delete();
                }
                await tempFile.rename(targetFile.path);
                _downloadedSurahKeys.add(_surahKey(reciter.id, ch, styleId: styleId));
                break;
              } else {
                if (await tempFile.exists()) await tempFile.delete();
              }
            }
          } catch (e) {
            debugPrint('Download error surah $ch attempt $attempt: $e');
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        _downloadedCountInBatch = ch;
        final count = await getDownloadedCount(reciter.id, styleId: styleId);
        if (styleId != null) {
          _styleDownloadedCounts[_styleCountKey(reciter.id, styleId)] = count;
        } else {
          _downloadedCounts[reciter.id] = count;
        }
        _progress = ch / 114.0;
        notifyListeners();
      }

      client.close();

      if (!_isCancelled) {
        _isDownloading = false;
        _isPaused = false;
        _currentStyleId = null;
        _progress = 1.0;
        _statusMessage = 'اكتمل تحميل مصحف ${reciter.name} بنجاح!';
        await refreshDownloadedCounts();
      }
    } catch (e) {
      debugPrint('Quran audio batch error: $e');
      _statusMessage = 'حدث خطأ أثناء التحميل: $e';
      _isDownloading = false;
      _currentStyleId = null;
    } finally {
      if (_isCancelled) {
        _isDownloading = false;
        _isPaused = false;
        _currentStyleId = null;
        _statusMessage = 'تم إلغاء التحميل';
      }
      notifyListeners();
    }
  }

  void pauseDownload() {
    if (_isDownloading) {
      _isPaused = true;
      _statusMessage = 'تم إيقاف التحميل مؤقتاً';
      notifyListeners();
    }
  }

  void resumeDownload() {
    if (_isDownloading && _isPaused) {
      _isPaused = false;
      _statusMessage = 'استئناف التحميل...';
      notifyListeners();
    }
  }

  void cancelDownload() {
    _isCancelled = true;
    _isDownloading = false;
    _isPaused = false;
    _currentStyleId = null;
    _statusMessage = 'تم الإلغاء';
    notifyListeners();
  }

  /// Start batch download with optional serverUrl and styleId parameters
  Future<void> startBatchDownload(ReciterItem reciter, {String? serverUrl, int? styleId}) async {
    await startDownload(reciter, serverUrl: serverUrl, styleId: styleId);
  }

  /// Download a single full surah file for offline playback with live progress
  Future<bool> downloadSurahDirect({
    required ReciterItem reciter,
    required int surahId,
    String? serverUrl,
    int? styleId,
  }) async {
    final key = _surahKey(reciter.id, surahId, styleId: styleId);
    if (_singleSurahProgress.containsKey(key)) {
      return false; // Already downloading
    }

    try {
      final dir = await _getReciterDir(reciter.id, styleId: styleId);
      final s = surahId.toString().padLeft(3, '0');
      final targetFile = File('${dir.path}/$s.mp3');
      if (await targetFile.exists() && await targetFile.length() > 5000) {
        _downloadedSurahKeys.add(key);
        notifyListeners();
        return true;
      }

      // Mark as downloading with initial progress
      _singleSurahProgress[key] = 0.0;
      notifyListeners();

      final server = (serverUrl != null && serverUrl.isNotEmpty)
          ? serverUrl
          : reciter.defaultServer;
      final cleanServer = server.endsWith('/') ? server : '$server/';
      final audioUrl = '$cleanServer$s.mp3';

      final client = http.Client();
      final req = http.Request('GET', Uri.parse(audioUrl));
      req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NoorAlAtra/1.0';
      final streamedResponse = await client.send(req).timeout(const Duration(seconds: 40));

      if (streamedResponse.statusCode == 200) {
        final totalBytes = streamedResponse.contentLength ?? 0;
        int receivedBytes = 0;

        final tempFile = File('${dir.path}/$s.tmp');
        final sink = tempFile.openWrite();

        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            _singleSurahProgress[key] = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            notifyListeners();
          }
        }

        await sink.flush();
        await sink.close();

        if (await tempFile.exists() && await tempFile.length() > 5000) {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          await tempFile.rename(targetFile.path);
          _downloadedSurahKeys.add(key);
          if (styleId != null) {
            _styleDownloadedCounts[_styleCountKey(reciter.id, styleId)] =
                await getDownloadedCount(reciter.id, styleId: styleId);
          }
          await refreshDownloadedCounts();
          _singleSurahProgress.remove(key);
          notifyListeners();
          client.close();
          return true;
        } else {
          if (await tempFile.exists()) await tempFile.delete();
        }
      }
      client.close();
    } catch (e) {
      debugPrint('Error downloading single surah: $e');
    } finally {
      _singleSurahProgress.remove(key);
      notifyListeners();
    }
    return false;
  }

  /// Delete downloaded audio files for a reciter (or specific style) to free phone space
  Future<void> deleteReciterAudio(int reciterId, {int? styleId}) async {
    try {
      if (_isDownloading && _currentReciter?.id == reciterId &&
          (styleId == null || _currentStyleId == styleId)) {
        cancelDownload();
      }
      final dir = await _getReciterDir(reciterId, styleId: styleId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      if (styleId != null) {
        _styleDownloadedCounts[_styleCountKey(reciterId, styleId)] = 0;
        _downloadedSurahKeys.removeWhere((k) => k.startsWith('$reciterId:$styleId:'));
        await refreshDownloadedCounts();
      } else {
        _downloadedCounts[reciterId] = 0;
        _styleDownloadedCounts.removeWhere((k, _) => k.startsWith('$reciterId:'));
        _downloadedSurahKeys.removeWhere((k) => k.startsWith('$reciterId:'));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting reciter audio: $e');
    }
  }
}
