import '../services/quran_api_service.dart';

class QuranBookmark {
  final int surahId;
  final String surahName;
  final int ayahNumber;
  final int pageNumber;
  final String ayahText;
  final DateTime createdAt;

  QuranBookmark({
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    this.pageNumber = 1,
    required this.ayahText,
    required this.createdAt,
  });

  // Aliases for compatibility
  int get ayahNum => ayahNumber;
  String get verseText => ayahText;

  /// Returns the exact authentic Uthmani Quranic text from the offline Quran database
  String get exactVerseText {
    final cached = QuranApiService.getCachedVerses(surahId);
    if (cached != null && cached.isNotEmpty) {
      for (final v in cached) {
        final aNum = int.tryParse(v.verseKey.split(':').last) ?? v.id;
        if (aNum == ayahNumber && v.textUthmani.isNotEmpty) {
          return v.textUthmani;
        }
      }
    }
    return ayahText;
  }

  Map<String, dynamic> toJson() => {
    'surahId': surahId,
    'surahName': surahName,
    'ayahNumber': ayahNumber,
    'ayahNum': ayahNumber,
    'pageNumber': pageNumber,
    'ayahText': ayahText,
    'verseText': ayahText,
    'createdAt': createdAt.toIso8601String(),
  };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    final surahId = json['surahId'] as int? ?? 1;
    final ayahNumber = json['ayahNumber'] as int? ?? json['ayahNum'] as int? ?? 1;
    final pageNumber = json['pageNumber'] as int? ?? _estimatePage(surahId, ayahNumber);
    final ayahText = (json['ayahText'] as String?) ?? (json['verseText'] as String?) ?? '';

    return QuranBookmark(
      surahId: surahId,
      surahName: json['surahName'] as String? ?? '',
      ayahNumber: ayahNumber,
      pageNumber: pageNumber,
      ayahText: ayahText,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Approximate page number in standard Medina Mushaf (604 pages) if not provided
  static int _estimatePage(int surahId, int ayahNum) {
    const surahStartPages = [
      1, 1, 2, 50, 77, 106, 128, 151, 177, 187,
      208, 221, 235, 249, 255, 261, 267, 282, 293, 305,
      312, 322, 332, 342, 350, 359, 367, 377, 385, 396,
      404, 411, 415, 418, 428, 434, 440, 446, 453, 458,
      467, 477, 483, 489, 496, 499, 502, 507, 511, 515,
      518, 520, 523, 526, 528, 531, 534, 537, 542, 545,
      549, 551, 553, 554, 556, 558, 560, 562, 564, 566,
      568, 570, 572, 574, 575, 577, 578, 580, 582, 583,
      585, 586, 587, 587, 589, 590, 591, 592, 593, 594,
      595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
      600, 600, 601, 601, 601, 602, 602, 602, 603, 603,
      603, 604, 604, 604, 604
    ];
    if (surahId >= 1 && surahId <= 114) {
      return surahStartPages[surahId];
    }
    return 1;
  }

  /// تاريخ الحفظ بصيغة عربية دقيقة مطابقة للتصميم:
  /// تاريخ الحفظ: 27 سبتمبر 2026 • 05:35 ص
  String get formattedDate {
    const arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final day = createdAt.day;
    final month = arabicMonths[createdAt.month - 1];
    final year = createdAt.year;
    final hourRaw = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final hourStr = hourRaw.toString().padLeft(2, '0');
    final minuteStr = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'م' : 'ص';
    return 'تاريخ الحفظ: $day $month $year • $hourStr:$minuteStr $period';
  }
}
