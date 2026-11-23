class WallpaperItem {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String thumbnailUrl;
  final String sourceName;
  final String sourceUrl;
  final List<String> tags;
  final bool isFeatured;

  const WallpaperItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.sourceName,
    required this.sourceUrl,
    this.tags = const [],
    this.isFeatured = false,
  });

  factory WallpaperItem.fromJson(Map<String, dynamic> json) {
    return WallpaperItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'خلفية ولائية',
      category: json['category'] as String? ?? 'عام',
      imageUrl: json['imageUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['imageUrl'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? 'العتبات المقدسة',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
      'tags': tags,
      'isFeatured': isFeatured,
    };
  }
}
