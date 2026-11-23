import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/models/wallpaper_item.dart';
import 'package:flutter_noor_alatra/services/wallpaper_service.dart';

void main() {
  test('WallpaperItem parses remote GitHub repository JSON structure correctly', () {
    const rawJson = '''
    {
      "id": "wp_31e4c8cf6c4e8f9b",
      "title": "الحرم الحسيني (العتبة الحسينية المقدسة)",
      "category": "العتبة العلوية المقدسة",
      "shrine": "مرقد الإمام علي بن أبي طالب (ع) - النجف الأشرف",
      "image_url": "https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/images/wp_31e4c8cf6c4e8f9b.webp",
      "thumbnail_url": "https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/thumbnails/wp_31e4c8cf6c4e8f9b_thumb.webp",
      "original_url": "https://imamali.net/files/sections/images/4ul5u5nde.jpg",
      "source_name": "شبكة الإمام علي (ع) ميديا",
      "source_page": "https://media.imamali.net/?id=1368&p=1",
      "file_size": 233338,
      "width": 1100,
      "height": 733
    }
    ''';

    final data = json.decode(rawJson) as Map<String, dynamic>;
    final item = WallpaperItem.fromJson(data);

    expect(item.id, 'wp_31e4c8cf6c4e8f9b');
    expect(item.title, 'الحرم الحسيني (العتبة الحسينية المقدسة)');
    expect(item.category, 'العتبة العلوية المقدسة');
    expect(item.shrine, 'مرقد الإمام علي بن أبي طالب (ع) - النجف الأشرف');
    expect(item.imageUrl, 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/images/wp_31e4c8cf6c4e8f9b.webp');
    expect(item.thumbnailUrl, 'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/thumbnails/wp_31e4c8cf6c4e8f9b_thumb.webp');
    expect(item.sourceName, 'شبكة الإمام علي (ع) ميديا');
    expect(item.sourceUrl, 'https://media.imamali.net/?id=1368&p=1');
    expect(item.width, 1100);
    expect(item.height, 733);
    expect(item.fileSize, 233338);
  });

  test('WallpaperService points to official remote GitHub repository', () {
    expect(
      WallpaperService.versionUrl,
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/version.json',
    );
    expect(
      WallpaperService.wallpapersUrl,
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/wallpapers.json',
    );
    expect(
      WallpaperService.pagesIndexUrl,
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/pages/index.json',
    );
    expect(
      WallpaperService.page1Url,
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/pages/page_1.json',
    );
    expect(
      WallpaperService.categoriesIndexUrl,
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/index.json',
    );
    expect(
      WallpaperService.pageUrl(2),
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/pages/page_2.json',
    );
    expect(WallpaperService.categoryEndpoints.length, 9);
    expect(
      WallpaperService.categoryEndpoints['events'],
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/events.json',
    );
    expect(
      WallpaperService.categoryEndpoints['shrines'],
      'https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/categories/shrines.json',
    );
  });
}
