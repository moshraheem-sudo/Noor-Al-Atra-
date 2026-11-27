import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper_item.dart';
import 'proximity_wakelock_service.dart';

List<WallpaperItem> _parseWallpapers(String body) {
  final decoded = json.decode(body);
  final items = decoded is Map ? decoded['items'] : decoded;
  if (items is! List) return [];
  return items.whereType<Map<String, dynamic>>()
      .map(WallpaperItem.fromJson)
      .where((item) => item.id.isNotEmpty && item.imageUrl.isNotEmpty)
      .toList(growable: false);
}

class WallpaperService {
  static final WallpaperService _instance = WallpaperService._internal();
  factory WallpaperService() => _instance;
  WallpaperService._internal();

  /// Direct repository URLs for Islamic Shrines Wallpapers
  static const String versionUrl =
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/version.json';
  static const String pagesIndexUrl =
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/pages/index.json';
  static const String page1Url =
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/pages/page_1.json';
  static const String categoriesIndexUrl =
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/index.json';
  static const String wallpapersUrl =
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/wallpapers.json';

  static String pageUrl(int pageNumber) =>
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/pages/page_$pageNumber.json';

  static const Map<String, String> categoryEndpoints = {
    'events': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/events.json',
    'abbasi': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/abbasi.json',
    'hussaini': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/hussaini.json',
    'alawi': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/alawi.json',
    'kadhimi': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/kadhimi.json',
    'askari': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/askari.json',
    'ridhawi': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/ridhawi.json',
    'shrines': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/shrines.json',
    'architecture': 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/architecture.json',
  };

  static const String _prefsCacheKey = 'cached_islamic_wallpapers_v5';
  static const String _prefsVersionKey = 'cached_islamic_version_v5';
  static const String _prefsLastSyncKey = 'cached_islamic_last_sync_v5';

  List<WallpaperItem> _cachedList = [];

  List<WallpaperItem> get cachedWallpapers => _cachedList;

  /// Loads wallpapers from memory, cached storage, or local assets,
  /// and automatically synchronizes updates from the GitHub repository.
  Future<List<WallpaperItem>> loadWallpapers({bool forceRefresh = false}) async {
    if (_cachedList.isNotEmpty && !forceRefresh) {
      _checkBackgroundUpdates();
      return _cachedList;
    }

    if (_cachedList.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_prefsCacheKey);
        if (cached != null) {
          _cachedList = await compute(_parseWallpapers, cached);
        }
      } catch (error) {
        debugPrint('[WallpaperService] Invalid cached catalog: $error');
      }
      if (_cachedList.isEmpty) {
        try {
          final bundled = await rootBundle.loadString('assets/data/wallpapers.json');
          _cachedList = await compute(_parseWallpapers, bundled);
        } catch (error) {
          debugPrint('[WallpaperService] Could not load bundled catalog: $error');
        }
      }
    }

    if (forceRefresh || _cachedList.isEmpty) {
      await checkForRemoteUpdates(force: true);
    } else {
      _checkBackgroundUpdates();
    }
    return _cachedList;
  }

  void _checkBackgroundUpdates() {
    unawaited(checkForRemoteUpdates());
  }

  Future<List<WallpaperItem>?>? _remoteSync;

  Future<List<WallpaperItem>?> checkForRemoteUpdates({bool force = false}) async {
    final pending = _remoteSync;
    if (pending != null) {
      final result = await pending;
      if (!force || result != null) return result;
      return checkForRemoteUpdates(force: true);
    }

    final sync = _fetchCatalogUpdate(force: force);
    _remoteSync = sync;
    try {
      return await sync;
    } finally {
      _remoteSync = null;
    }
  }

  static const _headers = {'User-Agent': 'NoorAlAtra/1.0'};

  Future<List<WallpaperItem>?> _fetchCatalogUpdate({required bool force}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastSync = prefs.getInt(_prefsLastSyncKey) ?? 0;
      if (!force && now - lastSync < const Duration(minutes: 15).inMilliseconds) {
        return null;
      }

      final currentVersion = prefs.getInt(_prefsVersionKey) ?? 0;
      int? remoteVersion;
      try {
        final response = await http.get(Uri.parse(versionUrl), headers: _headers)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final version = json.decode(response.body);
          remoteVersion = int.tryParse(version['version'].toString());
        }
      } catch (error) {
        debugPrint('[WallpaperService] Version check failed: $error');
      }

      if (!force && remoteVersion != null && remoteVersion <= currentVersion) {
        await prefs.setInt(_prefsLastSyncKey, now);
        return null;
      }

      for (final url in [wallpapersUrl, page1Url]) {
        try {
          final response = await http.get(Uri.parse(url), headers: _headers)
              .timeout(const Duration(seconds: 8));
          if (response.statusCode != 200) continue;
          final body = utf8.decode(response.bodyBytes);
          final items = await compute(_parseWallpapers, body);
          if (items.isEmpty) continue;
          // A single fallback page can bootstrap an empty catalog only.
          if (url == page1Url && _cachedList.isNotEmpty) return null;
          if (url == wallpapersUrl) {
            await prefs.setString(_prefsCacheKey, body);
            if (remoteVersion != null) {
              await prefs.setInt(_prefsVersionKey, remoteVersion);
            }
            await prefs.setInt(_prefsLastSyncKey, now);
          }
          return _cachedList = items;
        } catch (error) {
          debugPrint('[WallpaperService] Catalog request failed: $error');
        }
      }
    } catch (error) {
      debugPrint('[WallpaperService] Catalog sync failed: $error');
    }
    return null;
  }

  /// Fetches items for a specific category endpoint (e.g. 'events', 'abbasi', etc.)
  Future<List<WallpaperItem>?> fetchCategoryWallpapers(String slug) async {
    final endpoint = categoryEndpoints[slug];
    if (endpoint == null) return null;
    try {
      final res = await http
          .get(Uri.parse(endpoint), headers: {'User-Agent': 'NoorAlAtra/1.0'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        return await compute(_parseWallpapers, body);
      }
    } catch (e) {
      debugPrint('[WallpaperService] Error fetching category $slug: $e');
    }
    return null;
  }

  /// Fetches a specific page of wallpapers (page 1 to 23)
  Future<List<WallpaperItem>?> fetchPageWallpapers(int pageNumber) async {
    try {
      final url = pageUrl(pageNumber);
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'NoorAlAtra/1.0'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        return await compute(_parseWallpapers, body);
      }
    } catch (e) {
      debugPrint('[WallpaperService] Error fetching page $pageNumber: $e');
    }
    return null;
  }

  final _downloads = <String, Future<File?>>{};
  static const _maxImageBytes = 48 * 1024 * 1024;
  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static const _galleryChannel = MethodChannel('com.example.flutter_noor_alatra/wakelock');

  /// Downloads the original image only when an action requires a local file.
  Future<File?> downloadWallpaperFile(String imageUrl, String id) async {
    if (!_safeId.hasMatch(id)) return null;
    final existing = _downloads[id];
    if (existing != null) return existing;
    final download = _downloadWallpaper(imageUrl, id);
    _downloads[id] = download;
    try {
      return await download;
    } finally {
      _downloads.remove(id);
    }
  }

  Future<File?> _downloadWallpaper(String imageUrl, String id) async {
    final asset = imageUrl.startsWith('assets/') && !imageUrl.contains('..');
    final uri = WallpaperItem.httpsUri(imageUrl);
    if (!asset && uri == null) return null;
    Directory? staging;
    try {
      final cache = await getTemporaryDirectory();
      final dir = await Directory('${cache.path}/wallpaper-originals').create(recursive: true);
      for (final extension in ['webp', 'jpg', 'png']) {
        final file = File('${dir.path}/$id.$extension');
        if (await file.exists()) return file;
      }

      staging = await dir.createTemp('download-');
      final partial = File('${staging.path}/image');
      if (asset) {
        final data = await rootBundle.load(imageUrl);
        await partial.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      } else {
        final client = http.Client();
        try {
          final request = http.Request('GET', uri!)
            ..headers.addAll(_headers)
            ..followRedirects = false;
          final response = await client.send(request).timeout(const Duration(seconds: 15));
          if (response.statusCode != 200 || (response.contentLength ?? 0) > _maxImageBytes) {
            return null;
          }

          final output = await partial.open(mode: FileMode.write);
          try {
            var received = 0;
            await for (final chunk in response.stream.timeout(const Duration(seconds: 15))) {
              received += chunk.length;
              if (received > _maxImageBytes) return null;
              await output.writeFrom(chunk);
            }
            if (response.contentLength != null && response.contentLength != received) return null;
          } finally {
            await output.close();
          }
        } finally {
          client.close();
        }
      }

      final input = await partial.open();
      final List<int> header;
      try {
        header = await input.read(12);
      } finally {
        await input.close();
      }
      final extension = _imageExtension(header);
      if (extension == null) return null;
      return await partial.rename('${dir.path}/$id.$extension');
    } catch (error) {
      debugPrint('[WallpaperService] Image download failed: $error');
      return null;
    } finally {
      if (staging != null) {
        try {
          await staging.delete(recursive: true);
        } on FileSystemException catch (error) {
          debugPrint('[WallpaperService] Could not clean download staging: $error');
        }
      }
    }
  }

  String? _imageExtension(List<int> header) {
    if (header.length < 12) return null;
    if (header[0] == 0xff && header[1] == 0xd8 && header[2] == 0xff) return 'jpg';
    if (header[0] == 0x89 && String.fromCharCodes(header.sublist(1, 4)) == 'PNG') return 'png';
    if (String.fromCharCodes(header.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(header.sublist(8, 12)) == 'WEBP') {
      return 'webp';
    }
    return null;
  }

  Future<String?> saveWallpaperToGallery(String imageUrl, String id) async {
    final file = await downloadWallpaperFile(imageUrl, id);
    if (file == null) return null;
    if (Platform.isAndroid) {
      return _galleryChannel.invokeMethod<String>('saveWallpaperToGallery', {'filePath': file.path});
    }
    if (Platform.isIOS) {
      final saved = await applyDeviceWallpaper(file: file);
      return saved ? file.path : null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final name = 'NoorAlAtra_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final saved = await file.copy('${directory.path}/$name');
    return saved.path;
  }

  /// Applies image as device wallpaper using native WallpaperManager
  /// [target]: 'home', 'lock', or 'both'
  Future<bool> applyDeviceWallpaper({
    required File file,
    String target = 'both',
  }) async {
    return ProximityWakeLockService().setDeviceWallpaper(
      filePath: file.path,
      target: target,
    );
  }
}
