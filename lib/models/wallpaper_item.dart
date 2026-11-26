class WallpaperItem {
  final String id;
  final String title;
  final String category;
  final String? shrine;
  final String imageUrl;
  final String thumbnailUrl;
  final String sourceName;
  final String sourceUrl;
  final List<String> tags;
  final bool isFeatured;
  final int? width;
  final int? height;
  final int? fileSize;

  const WallpaperItem({
    required this.id,
    required this.title,
    required this.category,
    this.shrine,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.sourceName,
    required this.sourceUrl,
    this.tags = const [],
    this.isFeatured = false,
    this.width,
    this.height,
    this.fileSize,
  });

  static Uri? httpsUri(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty &&
        uri.userInfo.isEmpty ? uri : null;
  }

  static String _imageUrl(String value) {
    if (value.startsWith('assets/') && !value.contains('..')) return value;
    return httpsUri(value)?.toString() ?? '';
  }

  factory WallpaperItem.fromJson(Map<String, dynamic> json) {
    final rawImg = (json['image_url'] ?? json['imageUrl'] ?? '').toString();
    final rawThumb = (json['thumbnail_url'] ?? json['thumbnailUrl'] ?? rawImg).toString();
    final rawSource = (json['source_name'] ?? json['sourceName'] ?? 'العتبات المقدسة').toString();
    final rawSourceUrl = (json['source_page'] ?? json['source_url'] ?? json['sourceUrl'] ?? json['original_url'] ?? '').toString();

    final image = _imageUrl(rawImg);
    final thumbnail = _imageUrl(rawThumb);

    return WallpaperItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'خلفية دينية').toString(),
      category: (json['category'] ?? 'عام').toString(),
      shrine: json['shrine']?.toString(),
      imageUrl: image,
      thumbnailUrl: thumbnail.isNotEmpty ? thumbnail : image,
      sourceName: rawSource,
      sourceUrl: httpsUri(rawSourceUrl)?.toString() ?? "",
      tags: json['tags'] is List ? (json['tags'] as List).map((e) => e.toString()).toList() : const [],
      isFeatured: json['isFeatured'] == true,
      width: json['width'] is int ? json['width'] as int : int.tryParse(json['width']?.toString() ?? ''),
      height: json['height'] is int ? json['height'] as int : int.tryParse(json['height']?.toString() ?? ''),
      fileSize: json['file_size'] is int ? json['file_size'] as int : int.tryParse(json['file_size']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'shrine': shrine,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'tags': tags,
      'isFeatured': isFeatured,
      'width': width,
      'height': height,
      'file_size': fileSize,
    };
  }
}
