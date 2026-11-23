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
  static const String wallpapersUrl =
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/wallpapers.json';

  static const String _prefsCacheKey = 'cached_islamic_wallpapers_data_v2';
  static const String _prefsVersionKey = 'cached_islamic_wallpapers_version_v2';
  static const String _prefsLastSyncKey = 'cached_islamic_wallpapers_last_sync_v2';

  List<WallpaperItem> _cachedList = [];

  List<WallpaperItem> get cachedWallpapers => _cachedList;

  /// Loads wallpapers from memory, cached storage, or local assets,
  /// and automatically synchronizes updates from the GitHub repository.
  Future<List<WallpaperItem>> loadWallpapers({bool forceRefresh = false}) async {
    if (_cachedList.isNotEmpty && !forceRefresh) {
      // Trigger background update check if not checked recently
      _checkBackgroundUpdates();
      return _cachedList;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString(_prefsCacheKey);

      // If no local cache exists, load bundled assets as initial fallback
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        try {
          jsonStr = await rootBundle.loadString('assets/data/wallpapers.json');
        } catch (_) {}
      }

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final List<dynamic> list = json.decode(jsonStr);
        _cachedList = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (forceRefresh) {
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
      // Emergency fallback to local asset
      try {
        final fallbackStr = await rootBundle.loadString('assets/data/wallpapers.json');
        final List<dynamic> list = json.decode(fallbackStr);
        _cachedList = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedList;
      } catch (_) {
        return _cachedList;
      }
    }
  }

  /// Triggers a background update check if not checked in the current hour
  void _checkBackgroundUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastSync = prefs.getInt(_prefsLastSyncKey) ?? 0;
      // Check every 30 minutes
      if (now - lastSync > 30 * 60 * 1000 || _cachedList.isEmpty) {
        await checkForRemoteUpdates(force: false);
        await prefs.setInt(_prefsLastSyncKey, now);
      }
    } catch (e) {
      debugPrint('[WallpaperService] Background check notice: $e');
    }
  }

  /// Checks version.json and downloads wallpapers.json if an update is available
  Future<List<WallpaperItem>?> checkForRemoteUpdates({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_prefsVersionKey) ?? 0;

      // 1. Fetch version.json from GitHub
      final versionRes = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));

      if (versionRes.statusCode != 200) {
        debugPrint('[WallpaperService] Failed to fetch version.json (status: ${versionRes.statusCode})');
        if (!force) return null;
      }

      int remoteVersion = currentVersion;
      if (versionRes.statusCode == 200) {
        final versionData = json.decode(utf8.decode(versionRes.bodyBytes));
        remoteVersion = (versionData['version'] is int)
            ? versionData['version'] as int
            : int.tryParse(versionData['version']?.toString() ?? '0') ?? 0;
      }

      // Check if update is needed
      final bool needsUpdate = force || remoteVersion > currentVersion || _cachedList.isEmpty;
      if (!needsUpdate) {
        debugPrint('[WallpaperService] Wallpapers are up-to-date (v$currentVersion).');
        return _cachedList;
      }

      debugPrint('[WallpaperService] Updating wallpapers (local: v$currentVersion -> remote: v$remoteVersion)...');

      // 2. Fetch wallpapers.json from GitHub
      final wallpapersRes = await http
          .get(Uri.parse(wallpapersUrl))
          .timeout(const Duration(seconds: 20));

      if (wallpapersRes.statusCode == 200) {
        final body = utf8.decode(wallpapersRes.bodyBytes);
        final List<dynamic> list = json.decode(body);

        if (list.isNotEmpty) {
          final items = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
          await prefs.setString(_prefsCacheKey, body);
          await prefs.setInt(_prefsVersionKey, remoteVersion);
          _cachedList = items;
          debugPrint('[WallpaperService] Successfully updated ${_cachedList.length} wallpapers from GitHub (v$remoteVersion)');
          return _cachedList;
        }
      }
    } catch (e) {
      debugPrint('[WallpaperService] Offline or sync error (cached items remain available): $e');
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

      final localFile = File('${wallpapersDir.path}/${id}.$ext');

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
      final res = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 30));
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
      // Emergency fallback
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

      // On Android, copy to public Pictures or Downloads directory if accessible
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
      }

      if (targetDir == null) {
        final extDir = await getExternalStorageDirectory();
        targetDir = extDir ?? await getApplicationDocumentsDirectory();
      }

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
