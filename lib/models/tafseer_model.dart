import 'quran_chapter.dart';

/// أنواع التفاسير المعتمدة حصراً
enum TafseerType {
  almizan,
  safi;

  String get id => name;

  String get displayName {
    switch (this) {
      case TafseerType.almizan:
        return 'الميزان في تفسير القرآن';
      case TafseerType.safi:
        return 'تفسير الصافي';
    }
  }

  String get shortName {
    switch (this) {
      case TafseerType.almizan:
        return 'تفسير الميزان';
      case TafseerType.safi:
        return 'تفسير الصافي';
    }
  }

  String get author {
    switch (this) {
      case TafseerType.almizan:
        return 'العلامة السيد محمد حسين الطباطبائي (قدس سره)';
      case TafseerType.safi:
        return 'الشيخ محمد محسن الفيض الكاشاني (قدس سره)';
    }
  }

  String get shortAuthor {
    switch (this) {
      case TafseerType.almizan:
        return 'العلامة الطباطبائي';
      case TafseerType.safi:
        return 'الفيض الكاشاني';
    }
  }

  String get description {
    switch (this) {
      case TafseerType.almizan:
        return 'تفسير تحليلي يقوم على منهج تفسير القرآن بالقرآن مع بحوث روائية وفلسفية واجتماعية.';
      case TafseerType.safi:
        return 'تفسير روائي نفيس يعتمد على روايات وأحاديث أهل البيت (عليهم السلام) في بيان الآيات.';
    }
  }

  String get briefSummary {
    switch (this) {
      case TafseerType.almizan:
        return 'تفسير القرآن بالقرآن وبحوث روائية معمقة';
      case TafseerType.safi:
        return 'تفسير روائي شريف عن أحاديث أهل البيت (ع)';
    }
  }

  String get downloadSizeText {
    switch (this) {
      case TafseerType.almizan:
        return '٦.٨ م.ب';
      case TafseerType.safi:
        return '٨.٥ م.ب';
    }
  }

  int get approxCompressedBytes {
    switch (this) {
      case TafseerType.almizan:
        return 6833337;
      case TafseerType.safi:
        return 8587997;
    }
  }

  String get downloadUrl {
    return 'https://raw.githubusercontent.com/moshraheem-sudo/Noor-Al-Atra-/main/data/tafseer/$dbFileName.gz';
  }

  String get dbAssetPath {
    switch (this) {
      case TafseerType.almizan:
        return 'assets/data/tafseer/tafsir_almizan_ar.db';
      case TafseerType.safi:
        return 'assets/data/tafseer/tafsir_safi_ar.db';
    }
  }

  String get dbFileName {
    switch (this) {
      case TafseerType.almizan:
        return 'tafsir_almizan_ar.db';
      case TafseerType.safi:
        return 'tafsir_safi_ar.db';
    }
  }

  static TafseerType fromId(String? id) {
    if (id == 'safi') return TafseerType.safi;
    return TafseerType.almizan;
  }
}

/// كائن يمثل وحدة تفسيرية لسورة أو مجموعة آيات
class TafseerEntry {
  final int contentId;
  final TafseerType type;
  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final String content;
  final String surahName;

  const TafseerEntry({
    required this.contentId,
    required this.type,
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.content,
    required this.surahName,
  });

  bool get isAyahRange => startAyah != endAyah;

  String get ayahRangeText {
    if (startAyah == endAyah) {
      return 'الآية $startAyah';
    }
    return 'الآيات $startAyah - $endAyah';
  }

  bool containsAyah(int ayah) => ayah >= startAyah && ayah <= endAyah;
}

/// مفضلة التفسير
class TafseerFavorite {
  final String id;
  final TafseerType type;
  final int surahNumber;
  final int ayahNumber;
  final int startAyah;
  final int endAyah;
  final String surahName;
  final String snippet;
  final DateTime savedAt;

  const TafseerFavorite({
    required this.id,
    required this.type,
    required this.surahNumber,
    required this.ayahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.surahName,
    required this.snippet,
    required this.savedAt,
  });

  String get ayahRangeText {
    if (startAyah == endAyah) {
      return 'الآية $startAyah';
    }
    return 'الآيات $startAyah - $endAyah';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.id,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'startAyah': startAyah,
        'endAyah': endAyah,
        'surahName': surahName,
        'snippet': snippet,
        'savedAt': savedAt.toIso8601String(),
      };

  factory TafseerFavorite.fromJson(Map<String, dynamic> json) {
    return TafseerFavorite(
      id: json['id'] as String? ?? '${json['type']}_${json['surahNumber']}_${json['ayahNumber']}',
      type: TafseerType.fromId(json['type'] as String?),
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
      startAyah: (json['startAyah'] as num?)?.toInt() ?? 1,
      endAyah: (json['endAyah'] as num?)?.toInt() ?? 1,
      surahName: json['surahName'] as String? ?? 'الفاتحة',
      snippet: json['snippet'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// موضع القراءة الأخير
class TafseerReadingPosition {
  final TafseerType type;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final DateTime updatedAt;

  const TafseerReadingPosition({
    required this.type,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'type': type.id,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'surahName': surahName,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TafseerReadingPosition.fromJson(Map<String, dynamic> json) {
    final surahNum = (json['surahNumber'] as num?)?.toInt() ?? 1;
    final ch = QuranChapter.getChapterById(surahNum);
    return TafseerReadingPosition(
      type: TafseerType.fromId(json['type'] as String?),
      surahNumber: surahNum,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
      surahName: json['surahName'] as String? ?? ch?.nameArabic ?? 'الفاتحة',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// نتيجة البحث في التفسير
class TafseerSearchResult {
  final TafseerType type;
  final int contentId;
  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final String surahName;
  final String snippet;
  final String matchedText;

  const TafseerSearchResult({
    required this.type,
    required this.contentId,
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.surahName,
    required this.snippet,
    required this.matchedText,
  });

  String get ayahRangeText {
    if (startAyah == endAyah) {
      return 'الآية $startAyah';
    }
    return 'الآيات $startAyah - $endAyah';
  }
}
