import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper_item.dart';
import 'proximity_wakelock_service.dart';

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

  static const String _prefsCacheKey = 'cached_islamic_wallpapers_v4';
  static const String _prefsVersionKey = 'cached_islamic_version_v4';
  static const String _prefsLastSyncKey = 'cached_islamic_last_sync_v4';

  List<WallpaperItem> _cachedList = [];

  List<WallpaperItem> get cachedWallpapers => _cachedList;

  /// Loads wallpapers from memory, cached storage, or local assets,
  /// and automatically synchronizes updates from the GitHub repository.
  Future<List<WallpaperItem>> loadWallpapers({bool forceRefresh = false}) async {
    if (_cachedList.isNotEmpty && !forceRefresh) {
      _checkBackgroundUpdates();
      return _cachedList;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear legacy broken caches if present
      for (final oldKey in [
        'cached_wallpapers_json_v1',
        'cached_islamic_wallpapers_data_v2',
        'cached_islamic_wallpapers_v3',
      ]) {
        if (prefs.containsKey(oldKey)) {
          await prefs.remove(oldKey);
        }
      }

      String? jsonStr = prefs.getString(_prefsCacheKey);

      // Validate cache: if it contains dead links or lacks verified domain, invalidate
      if (jsonStr != null && (jsonStr.contains('main.pictures.alkafeel.net') || !jsonStr.contains('Islamic-Shrines-Wallpapers'))) {
        jsonStr = null;
        await prefs.remove(_prefsCacheKey);
      }

      // If no valid cache, load updated bundled asset
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        try {
          jsonStr = await rootBundle.loadString('assets/data/wallpapers.json');
        } catch (_) {}
      }

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final decoded = json.decode(jsonStr);
        final list = _extractItemsList(decoded);
        _cachedList = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (forceRefresh || _cachedList.isEmpty) {
        final updated = await checkForRemoteUpdates(force: true);
        if (updated != null && updated.isNotEmpty) {
          _cachedList = updated;
        }
      } else {
        _checkBackgroundUpdates();
      }

      return _cachedList;
    } catch (e) {
      debugPrint('[WallpaperService] Error loading wallpapers: $e');
      try {
        final fallbackStr = await rootBundle.loadString('assets/data/wallpapers.json');
        final decoded = json.decode(fallbackStr);
        final list = _extractItemsList(decoded);
        _cachedList = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedList;
      } catch (_) {
        return _cachedList;
      }
    }
  }

  /// Helper to extract list from either a direct List or a paged Map {'items': [...]}
  List<dynamic> _extractItemsList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }

  /// Triggers a background update check if not checked in the last 15 minutes
  void _checkBackgroundUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastSync = prefs.getInt(_prefsLastSyncKey) ?? 0;
      if (now - lastSync > 15 * 60 * 1000 || _cachedList.isEmpty) {
        await checkForRemoteUpdates(force: false);
        await prefs.setInt(_prefsLastSyncKey, now);
      }
    } catch (e) {
      debugPrint('[WallpaperService] Background check notice: $e');
    }
  }

  /// Checks version.json and downloads wallpapers.json or page_1.json if an update is available
  Future<List<WallpaperItem>?> checkForRemoteUpdates({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_prefsVersionKey) ?? 0;

      // 1. Fetch version.json from GitHub
      int remoteVersion = currentVersion;
      try {
        final versionRes = await http
            .get(Uri.parse(versionUrl), headers: {'User-Agent': 'NoorAlAtra/1.0'})
            .timeout(const Duration(seconds: 8));

        if (versionRes.statusCode == 200) {
          final versionData = json.decode(utf8.decode(versionRes.bodyBytes));
          remoteVersion = (versionData['version'] is int)
              ? versionData['version'] as int
              : int.tryParse(versionData['version']?.toString() ?? '0') ?? 0;
        }
      } catch (e) {
        debugPrint('[WallpaperService] Notice on version check: $e');
      }

      final bool needsUpdate = force || remoteVersion > currentVersion || _cachedList.isEmpty;
      if (!needsUpdate) {
        debugPrint('[WallpaperService] Wallpapers are up-to-date (v$currentVersion).');
        return _cachedList;
      }

      debugPrint('[WallpaperService] Fetching remote wallpapers (remote: v$remoteVersion)...');

      // 2. Fetch wallpapers from primary wallpapersUrl, with page1Url fallback
      http.Response? res;
      try {
        res = await http
            .get(Uri.parse(wallpapersUrl), headers: {'User-Agent': 'NoorAlAtra/1.0'})
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        try {
          res = await http
              .get(Uri.parse(page1Url), headers: {'User-Agent': 'NoorAlAtra/1.0'})
              .timeout(const Duration(seconds: 15));
        } catch (_) {}
      }

      if (res != null && res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        final decoded = json.decode(body);
        final List<dynamic> list = _extractItemsList(decoded);

        if (list.isNotEmpty) {
          final items = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
          await prefs.setString(_prefsCacheKey, body);
          await prefs.setInt(_prefsVersionKey, remoteVersion > 0 ? remoteVersion : 1);
          _cachedList = items;
          debugPrint('[WallpaperService] Successfully updated ${_cachedList.length} wallpapers from GitHub');
          return _cachedList;
        }
      }
    } catch (e) {
      debugPrint('[WallpaperService] Sync notice (cached items remain available): $e');
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
        final decoded = json.decode(body);
        final List<dynamic> list = _extractItemsList(decoded);
        return list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
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
        final decoded = json.decode(body);
        final List<dynamic> list = _extractItemsList(decoded);
        return list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[WallpaperService] Error fetching page $pageNumber: $e');
    }
    return null;
  }

  /// Downloads wallpaper image to a local file for viewing, saving, or setting
  Future<File?> downloadWallpaperFile(String imageUrl, String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final wallpapersDir = Directory('${dir.path}/wallpapers');
      if (!wallpapersDir.existsSync()) {
        wallpapersDir.createSync(recursive: true);
      }

      // Determine extension (.webp, .jpg, .png)
      String ext = 'webp';
      if (imageUrl.toLowerCase().endsWith('.png')) {
        ext = 'png';
      } else if (imageUrl.toLowerCase().endsWith('.jpg') || imageUrl.toLowerCase().endsWith('.jpeg')) {
        ext = 'jpg';
      }

      final localFile = File('${wallpapersDir.path}/$id.$ext');

      // If already downloaded and exists with positive length, return it
      if (localFile.existsSync() && localFile.lengthSync() > 0) {
        return localFile;
      }

      // Check if it's a local asset or remote URL
      if (imageUrl.startsWith('assets/')) {
        final byteData = await rootBundle.load(imageUrl);
        await localFile.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
        return localFile;
      }

      // Download full resolution from network
      final res = await http.get(Uri.parse(imageUrl), headers: {
        'User-Agent': 'NoorAlAtra/1.0'
      }).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        await localFile.writeAsBytes(res.bodyBytes);
        return localFile;
      } else {
        // Fallback to local asset if remote fails
        final byteData = await rootBundle.load('assets/images/worship/wallpapers.png');
        await localFile.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
        return localFile;
      }
    } catch (e) {
      debugPrint('[WallpaperService] Error downloading wallpaper file: $e');
      try {
        final dir = await getApplicationDocumentsDirectory();
        final localFile = File('${dir.path}/wallpapers/$id.webp');
        final byteData = await rootBundle.load('assets/images/worship/wallpapers.png');
        await localFile.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
        return localFile;
      } catch (_) {
        return null;
      }
    }
  }

  /// Copies the wallpaper image to public pictures/downloads gallery
  Future<String?> saveWallpaperToGallery(String imageUrl, String id) async {
    try {
      final file = await downloadWallpaperFile(imageUrl, id);
      if (file == null || !file.existsSync()) return null;

      Directory? targetDir;
      if (Platform.isAndroid) {
        final publicPictures = Directory('/storage/emulated/0/Pictures/NoorAlAtra');
        final publicDownloads = Directory('/storage/emulated/0/Download');

        try {
          if (!publicPictures.existsSync()) {
            publicPictures.createSync(recursive: true);
          }
          targetDir = publicPictures;
        } catch (_) {
          try {
            if (publicDownloads.existsSync()) {
              targetDir = publicDownloads;
            }
          } catch (_) {}
        }

        if (targetDir == null) {
          try {
            final extDir = await getExternalStorageDirectory();
            targetDir = extDir;
          } catch (_) {}
        }
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final ext = file.path.split('.').last;
      final fileName = 'NoorAlAtra_Wallpaper_${id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = File('${targetDir.path}/$fileName');
      await file.copy(savedFile.path);

      return savedFile.path;
    } catch (e) {
      debugPrint('[WallpaperService] Error saving wallpaper to gallery: $e');
      return null;
    }
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
