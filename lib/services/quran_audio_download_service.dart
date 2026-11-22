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
  int _currentSurahIndex = 0; // 1..114
  String _currentSurahName = '';
  int _downloadedCountInBatch = 0;
  double _progress = 0.0;
  String? _statusMessage;

  final Map<int, int> _downloadedCounts = {}; // reciterId -> count of downloaded surahs
  final Map<String, double> _singleSurahProgress = {}; // "reciterId:surahId" -> progress 0.0..1.0

  bool get isDownloading => _isDownloading;
  bool get isPaused => _isPaused;
  ReciterItem? get currentReciter => _currentReciter;
  int get currentSurahIndex => _currentSurahIndex;
  String get currentSurahName => _currentSurahName;
  int get downloadedCountInBatch => _downloadedCountInBatch;
  double get progress => _progress;
  String? get statusMessage => _statusMessage;

  String? _baseAudioDirPath;
  final Set<String> _downloadedSurahKeys = {}; // "reciterId:surahId"

  bool isSurahDownloading(int reciterId, int surahId) {
    return _singleSurahProgress.containsKey('$reciterId:$surahId');
  }

  double? getSurahDownloadProgress(int reciterId, int surahId) {
    return _singleSurahProgress['$reciterId:$surahId'];
  }

  Future<void> _init() async {
    await refreshDownloadedCounts();
  }

  Future<Directory> _getReciterDir(int reciterId) async {
    final docs = await getApplicationDocumentsDirectory();
    _baseAudioDirPath = '${docs.path}/quran_audio';
    final dir = Directory('$_baseAudioDirPath/$reciterId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Refreshes the downloaded surahs count for all popular reciters
  Future<void> refreshDownloadedCounts() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      _baseAudioDirPath = '${docs.path}/quran_audio';
      _downloadedSurahKeys.clear();

      for (final r in ReciterItem.popularReciters) {
        final dir = Directory('$_baseAudioDirPath/${r.id}');
        if (await dir.exists()) {
          final files = dir.listSync().whereType<File>().where((f) {
            return f.path.endsWith('.mp3') && f.lengthSync() > 2048;
          }).toList();
          for (final f in files) {
            final fileName = f.uri.pathSegments.last;
            final numPart = fileName.replaceAll('.mp3', '');
            final surahId = int.tryParse(numPart);
            if (surahId != null) {
              _downloadedSurahKeys.add('${r.id}:$surahId');
            }
          }
          _downloadedCounts[r.id] = files.length;
        } else {
          _downloadedCounts[r.id] = 0;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing downloaded counts: $e');
    }
  }

  int getCachedDownloadedCount(int reciterId) {
    return _downloadedCounts[reciterId] ?? 0;
  }

  bool isReciterComplete(int reciterId) {
    return (_downloadedCounts[reciterId] ?? 0) >= 114;
  }

  /// Synchronous check if a specific surah is downloaded for a reciter
  bool isSurahDownloaded(int reciterId, int surahId) {
    return _downloadedSurahKeys.contains('$reciterId:$surahId');
  }

  /// Synchronous local file path lookup for instant offline playback
  String? getLocalSurahPath(int reciterId, int surahId) {
    if (_downloadedSurahKeys.contains('$reciterId:$surahId') && _baseAudioDirPath != null) {
      final s = surahId.toString().padLeft(3, '0');
      final path = '$_baseAudioDirPath/$reciterId/$s.mp3';
      return path;
    }
    return null;
  }

  /// Get how many surahs are locally downloaded for a reciter
  Future<int> getDownloadedCount(int reciterId) async {
    try {
      final dir = await _getReciterDir(reciterId);
      final files = dir.listSync().whereType<File>().where((f) {
        return f.path.endsWith('.mp3') && f.lengthSync() > 2048;
      }).toList();
      return files.length;
    } catch (_) {
      return 0;
    }
  }

  /// Async check for local audio file path
  Future<String?> findLocalSurahAudioPath(int reciterId, int surahId) async {
    try {
      final dir = await _getReciterDir(reciterId);
      final s = surahId.toString().padLeft(3, '0');
      final file = File('${dir.path}/$s.mp3');
      if (await file.exists() && await file.length() > 2048) {
        _downloadedSurahKeys.add('$reciterId:$surahId');
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Start or resume background download of all 114 Surahs for a reciter
  Future<void> startDownload(ReciterItem reciter, {String? serverUrl}) async {
    if (_isDownloading && _currentReciter?.id == reciter.id) {
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
    _currentSurahIndex = 1;
    _progress = 0.0;
    _statusMessage = 'بدء تحميل مصحف ${reciter.name}...';
    notifyListeners();

    final server = (serverUrl != null && serverUrl.isNotEmpty)
        ? serverUrl
        : (reciterServers[reciter.id] ?? 'https://server8.mp3quran.net/afs/');
    final cleanServer = server.endsWith('/') ? server : '$server/';
    final dir = await _getReciterDir(reciter.id);

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
          _downloadedSurahKeys.add('${reciter.id}:$ch');
          _downloadedCountInBatch = ch;
          _downloadedCounts[reciter.id] = ch;
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
                _downloadedSurahKeys.add('${reciter.id}:$ch');
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
        _downloadedCounts[reciter.id] = await getDownloadedCount(reciter.id);
        _progress = ch / 114.0;
        notifyListeners();
      }

      client.close();

      if (!_isCancelled) {
        _isDownloading = false;
        _isPaused = false;
        _progress = 1.0;
        _statusMessage = 'اكتمل تحميل مصحف ${reciter.name} بنجاح!';
        await refreshDownloadedCounts();
      }
    } catch (e) {
      debugPrint('Quran audio batch error: $e');
      _statusMessage = 'حدث خطأ أثناء التحميل: $e';
      _isDownloading = false;
    } finally {
      if (_isCancelled) {
        _isDownloading = false;
        _isPaused = false;
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
    _statusMessage = 'تم الإلغاء';
    notifyListeners();
  }

  /// Start batch download with optional serverUrl parameter
  Future<void> startBatchDownload(ReciterItem reciter, {String? serverUrl}) async {
    await startDownload(reciter, serverUrl: serverUrl);
  }

  /// Download a single full surah file for offline playback with live progress
  Future<bool> downloadSurahDirect({
    required ReciterItem reciter,
    required int surahId,
    String? serverUrl,
  }) async {
    final key = '${reciter.id}:$surahId';
    if (_singleSurahProgress.containsKey(key)) {
      return false; // Already downloading
    }

    try {
      final dir = await _getReciterDir(reciter.id);
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
          _downloadedCounts[reciter.id] = await getDownloadedCount(reciter.id);
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

  /// Delete downloaded audio files for a reciter to free phone space
  Future<void> deleteReciterAudio(int reciterId) async {
    try {
      if (_isDownloading && _currentReciter?.id == reciterId) {
        cancelDownload();
      }
      final dir = await _getReciterDir(reciterId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _downloadedCounts[reciterId] = 0;
      _downloadedSurahKeys.removeWhere((k) => k.startsWith('$reciterId:'));
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting reciter audio: $e');
    }
  }
}
