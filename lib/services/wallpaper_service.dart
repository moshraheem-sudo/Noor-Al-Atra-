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

  static const String _githubWallpapersUrl =
      'https://raw.githubusercontent.com/moshraheem-sudo/Noor-Al-Atra-/main/assets/data/wallpapers.json';
  static const String _prefsKey = 'cached_wallpapers_json_v1';

  List<WallpaperItem> _cachedList = [];

  List<WallpaperItem> get cachedWallpapers => _cachedList;

  /// Loads wallpapers from memory, cached SharedPreferences, or local assets,
  /// and silently attempts to sync updates from the GitHub repository.
  Future<List<WallpaperItem>> loadWallpapers({bool forceRefresh = false}) async {
    if (_cachedList.isNotEmpty && !forceRefresh) {
      return _cachedList;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString(_prefsKey);

      if (jsonStr == null || forceRefresh) {
        jsonStr = await rootBundle.loadString('assets/data/wallpapers.json');
      }

      final List<dynamic> list = json.decode(jsonStr);
      _cachedList = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();

      // Trigger daily background sync from GitHub repository
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastSync = prefs.getString('wallpapers_last_daily_sync');
      if (lastSync != today || forceRefresh) {
        _syncFromGithub();
        await prefs.setString('wallpapers_last_daily_sync', today);
      }

      return _cachedList;
    } catch (e) {
      debugPrint('Error loading wallpapers: $e');
      // Fallback to local asset
      try {
        final fallbackStr = await rootBundle.loadString('assets/data/wallpapers.json');
        final List<dynamic> list = json.decode(fallbackStr);
        _cachedList = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedList;
      } catch (_) {
        return [];
      }
    }
  }

  /// Silently fetch latest wallpapers from the project GitHub repo
  Future<void> _syncFromGithub() async {
    try {
      final res = await http.get(Uri.parse(_githubWallpapersUrl)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        final List<dynamic> list = json.decode(body);
        if (list.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, body);
          _cachedList = list.map((e) => WallpaperItem.fromJson(e as Map<String, dynamic>)).toList();
          debugPrint('Wallpapers synced successfully from GitHub (${_cachedList.length} items)');
        }
      }
    } catch (e) {
      debugPrint('Silent wallpaper sync notice: $e');
    }
  }

  /// Downloads wallpaper image to a local file for viewing, saving, or setting
  Future<File?> downloadWallpaperFile(String imageUrl, String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final wallpapersDir = Directory('${dir.path}/wallpapers');
      if (!wallpapersDir.existsSync()) {
        wallpapersDir.createSync(recursive: true);
      }

      final localFile = File('${wallpapersDir.path}/$id.png');

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

      // Download from network
      final res = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 25));
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
      debugPrint('Error downloading wallpaper file: $e');
      // Emergency fallback
      try {
        final dir = await getApplicationDocumentsDirectory();
        final localFile = File('${dir.path}/wallpapers/$id.png');
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

      final fileName = 'NoorAlAtra_Wallpaper_${id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${targetDir.path}/$fileName');
      await file.copy(savedFile.path);

      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving wallpaper to gallery: $e');
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
