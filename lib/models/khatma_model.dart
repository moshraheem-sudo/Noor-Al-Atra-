import 'quran_chapter.dart';

class JuzInfo {
  final int juzNumber;
  final String arabicName;
  final int startPage;
  final int endPage;
  final int startSurahId;
  final String startSurahName;
  final int startAyah;

  const JuzInfo({
    required this.juzNumber,
    required this.arabicName,
    required this.startPage,
    required this.endPage,
    required this.startSurahId,
    required this.startSurahName,
    required this.startAyah,
  });

  int get totalPages => (endPage - startPage) + 1;

  static const List<JuzInfo> allAjza = [
    JuzInfo(juzNumber: 1, arabicName: 'الجزء الأول', startPage: 1, endPage: 21, startSurahId: 1, startSurahName: 'الفاتحة', startAyah: 1),
    JuzInfo(juzNumber: 2, arabicName: 'الجزء الثاني', startPage: 22, endPage: 41, startSurahId: 2, startSurahName: 'البقرة', startAyah: 142),
    JuzInfo(juzNumber: 3, arabicName: 'الجزء الثالث', startPage: 42, endPage: 61, startSurahId: 2, startSurahName: 'البقرة', startAyah: 253),
    JuzInfo(juzNumber: 4, arabicName: 'الجزء الرابع', startPage: 62, endPage: 81, startSurahId: 3, startSurahName: 'آل عمران', startAyah: 93),
    JuzInfo(juzNumber: 5, arabicName: 'الجزء الخامس', startPage: 82, endPage: 101, startSurahId: 4, startSurahName: 'النساء', startAyah: 24),
    JuzInfo(juzNumber: 6, arabicName: 'الجزء السادس', startPage: 102, endPage: 121, startSurahId: 4, startSurahName: 'النساء', startAyah: 148),
    JuzInfo(juzNumber: 7, arabicName: 'الجزء السابع', startPage: 122, endPage: 141, startSurahId: 5, startSurahName: 'المائدة', startAyah: 82),
    JuzInfo(juzNumber: 8, arabicName: 'الجزء الثامن', startPage: 142, endPage: 161, startSurahId: 6, startSurahName: 'الأنعام', startAyah: 111),
    JuzInfo(juzNumber: 9, arabicName: 'الجزء التاسع', startPage: 162, endPage: 181, startSurahId: 7, startSurahName: 'الأعراف', startAyah: 88),
    JuzInfo(juzNumber: 10, arabicName: 'الجزء العاشر', startPage: 182, endPage: 201, startSurahId: 8, startSurahName: 'الأنفال', startAyah: 41),
    JuzInfo(juzNumber: 11, arabicName: 'الجزء الحادي عشر', startPage: 202, endPage: 221, startSurahId: 9, startSurahName: 'التوبة', startAyah: 93),
    JuzInfo(juzNumber: 12, arabicName: 'الجزء الثاني عشر', startPage: 222, endPage: 241, startSurahId: 11, startSurahName: 'هود', startAyah: 6),
    JuzInfo(juzNumber: 13, arabicName: 'الجزء الثالث عشر', startPage: 242, endPage: 261, startSurahId: 12, startSurahName: 'يوسف', startAyah: 53),
    JuzInfo(juzNumber: 14, arabicName: 'الجزء الرابع عشر', startPage: 262, endPage: 281, startSurahId: 15, startSurahName: 'الحجر', startAyah: 1),
    JuzInfo(juzNumber: 15, arabicName: 'الجزء الخامس عشر', startPage: 282, endPage: 301, startSurahId: 17, startSurahName: 'الإسراء', startAyah: 1),
    JuzInfo(juzNumber: 16, arabicName: 'الجزء السادس عشر', startPage: 302, endPage: 321, startSurahId: 18, startSurahName: 'الكهف', startAyah: 75),
    JuzInfo(juzNumber: 17, arabicName: 'الجزء السابع عشر', startPage: 322, endPage: 341, startSurahId: 21, startSurahName: 'الأنبياء', startAyah: 1),
    JuzInfo(juzNumber: 18, arabicName: 'الجزء الثامن عشر', startPage: 342, endPage: 361, startSurahId: 23, startSurahName: 'المؤمنون', startAyah: 1),
    JuzInfo(juzNumber: 19, arabicName: 'الجزء التاسع عشر', startPage: 362, endPage: 381, startSurahId: 25, startSurahName: 'الفرقان', startAyah: 21),
    JuzInfo(juzNumber: 20, arabicName: 'الجزء العشرون', startPage: 382, endPage: 401, startSurahId: 27, startSurahName: 'النمل', startAyah: 56),
    JuzInfo(juzNumber: 21, arabicName: 'الجزء الحادي والعشرون', startPage: 402, endPage: 421, startSurahId: 29, startSurahName: 'العنكبوت', startAyah: 46),
    JuzInfo(juzNumber: 22, arabicName: 'الجزء الثاني والعشرون', startPage: 422, endPage: 441, startSurahId: 33, startSurahName: 'الأحزاب', startAyah: 31),
    JuzInfo(juzNumber: 23, arabicName: 'الجزء الثالث والعشرون', startPage: 442, endPage: 461, startSurahId: 36, startSurahName: 'يس', startAyah: 28),
    JuzInfo(juzNumber: 24, arabicName: 'الجزء الرابع والعشرون', startPage: 462, endPage: 481, startSurahId: 39, startSurahName: 'الزمر', startAyah: 32),
    JuzInfo(juzNumber: 25, arabicName: 'الجزء الخامس والعشرون', startPage: 482, endPage: 501, startSurahId: 41, startSurahName: 'فصلت', startAyah: 47),
    JuzInfo(juzNumber: 26, arabicName: 'الجزء السادس والعشرون', startPage: 502, endPage: 521, startSurahId: 46, startSurahName: 'الأحقاف', startAyah: 1),
    JuzInfo(juzNumber: 27, arabicName: 'الجزء السابع والعشرون', startPage: 522, endPage: 541, startSurahId: 51, startSurahName: 'الذاريات', startAyah: 31),
    JuzInfo(juzNumber: 28, arabicName: 'الجزء الثامن والعشرون', startPage: 542, endPage: 561, startSurahId: 58, startSurahName: 'المجادلة', startAyah: 1),
    JuzInfo(juzNumber: 29, arabicName: 'الجزء التاسع والعشرون', startPage: 562, endPage: 581, startSurahId: 67, startSurahName: 'الملك', startAyah: 1),
    JuzInfo(juzNumber: 30, arabicName: 'الجزء الثلاثون', startPage: 582, endPage: 604, startSurahId: 78, startSurahName: 'النبأ', startAyah: 1),
  ];

  static JuzInfo getJuzForPage(int page) {
    for (final j in allAjza) {
      if (page >= j.startPage && page <= j.endPage) {
        return j;
      }
    }
    return allAjza.first;
  }

  static int getJuzNumberForAyah(int surahId, int ayah) {
    if (surahId == 1) return 1;
    if (surahId == 2) {
      if (ayah < 142) return 1;
      if (ayah < 253) return 2;
      return 3;
    }
    if (surahId == 3) {
      if (ayah < 93) return 3;
      return 4;
    }
    if (surahId == 4) {
      if (ayah < 24) return 4;
      if (ayah < 148) return 5;
      return 6;
    }
    if (surahId == 5) {
      if (ayah < 82) return 6;
      return 7;
    }
    if (surahId == 6) {
      if (ayah < 111) return 7;
      return 8;
    }
    if (surahId == 7) {
      if (ayah < 88) return 8;
      return 9;
    }
    if (surahId == 8) {
      if (ayah < 41) return 9;
      return 10;
    }
    if (surahId == 9) {
      if (ayah < 93) return 10;
      return 11;
    }
    if (surahId == 10) return 11;
    if (surahId == 11) {
      if (ayah < 6) return 11;
      return 12;
    }
    if (surahId == 12) {
      if (ayah < 53) return 12;
      return 13;
    }
    if (surahId == 13 || surahId == 14) return 13;
    if (surahId == 15 || surahId == 16) return 14;
    if (surahId == 17) return 15;
    if (surahId == 18) {
      if (ayah < 75) return 15;
      return 16;
    }
    if (surahId == 19 || surahId == 20) return 16;
    if (surahId == 21 || surahId == 22) return 17;
    if (surahId == 23 || surahId == 24) return 18;
    if (surahId == 25) {
      if (ayah < 21) return 18;
      return 19;
    }
    if (surahId == 26) return 19;
    if (surahId == 27) {
      if (ayah < 56) return 19;
      return 20;
    }
    if (surahId == 28) return 20;
    if (surahId == 29) {
      if (ayah < 46) return 20;
      return 21;
    }
    if (surahId == 30 || surahId == 31 || surahId == 32) return 21;
    if (surahId == 33) {
      if (ayah < 31) return 21;
      return 22;
    }
    if (surahId == 34 || surahId == 35) return 22;
    if (surahId == 36) {
      if (ayah < 28) return 22;
      return 23;
    }
    if (surahId == 37 || surahId == 38) return 23;
    if (surahId == 39) {
      if (ayah < 32) return 23;
      return 24;
    }
    if (surahId == 40) return 24;
    if (surahId == 41) {
      if (ayah < 47) return 24;
      return 25;
    }
    if (surahId >= 42 && surahId <= 45) return 25;
    if (surahId >= 46 && surahId <= 50) return 26;
    if (surahId == 51) {
      if (ayah < 31) return 26;
      return 27;
    }
    if (surahId >= 52 && surahId <= 57) return 27;
    if (surahId >= 58 && surahId <= 66) return 28;
    if (surahId >= 67 && surahId <= 77) return 29;
    return 30; // 78 to 114
  }

  static const Map<int, int> surahStartPages = {
    1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187, 10: 208,
    11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282, 18: 293, 19: 305, 20: 312,
    21: 322, 22: 332, 23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396, 30: 404,
    31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467,
    41: 477, 42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
    51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537, 58: 542, 59: 545, 60: 549,
    61: 551, 62: 553, 63: 554, 64: 556, 65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568,
    71: 570, 72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585,
    81: 586, 82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593, 90: 594,
    91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599, 100: 599,
    101: 600, 102: 600, 103: 601, 104: 601, 105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603,
    111: 603, 112: 604, 113: 604, 114: 604, 115: 605,
  };

  static int getPageForSurahAndAyah(int surahId, int ayah) {
    final startPage = surahStartPages[surahId] ?? 1;
    final nextStartPage = surahStartPages[surahId + 1] ?? 605;
    final totalAyahs = QuranChapter.allChapters.firstWhere(
      (c) => c.id == surahId,
      orElse: () => QuranChapter.allChapters.first,
    ).versesCount;
    if (totalAyahs <= 0 || nextStartPage <= startPage) return startPage;
    final pageOffset = ((ayah - 1) / totalAyahs) * (nextStartPage - startPage);
    final calculatedPage = (startPage + pageOffset.floor()).clamp(startPage, nextStartPage - 1);
    return calculatedPage;
  }
}

enum JuzStatus {
  notStarted,
  inProgress,
  completed,
}

class JuzProgress {
  final int juzNumber;
  final int? lastReadPage;
  final int? lastReadSurahId;
  final String? lastReadSurahName;
  final int? lastReadAyah;
  final bool isCompleted;
  final DateTime? updatedAt;

  const JuzProgress({
    required this.juzNumber,
    this.lastReadPage,
    this.lastReadSurahId,
    this.lastReadSurahName,
    this.lastReadAyah,
    this.isCompleted = false,
    this.updatedAt,
  });

  JuzInfo get info => JuzInfo.allAjza[juzNumber - 1];

  JuzStatus get status {
    if (isCompleted) return JuzStatus.completed;
    if (lastReadPage != null && lastReadPage! >= info.startPage) {
      return JuzStatus.inProgress;
    }
    return JuzStatus.notStarted;
  }

  double get progressRatio {
    if (isCompleted) return 1.0;
    if (lastReadPage == null || lastReadPage! < info.startPage) return 0.0;
    final pagesRead = (lastReadPage! - info.startPage) + 1;
    return (pagesRead / info.totalPages).clamp(0.0, 1.0);
  }

  int get progressPercentInt => (progressRatio * 100).round();

  String get locationDescription {
    if (lastReadSurahName != null && lastReadAyah != null && lastReadPage != null) {
      return 'سورة $lastReadSurahName: آية $lastReadAyah • صفحة $lastReadPage';
    }
    if (lastReadPage != null) {
      return 'صفحة $lastReadPage من ${info.endPage}';
    }
    return '${info.startSurahName} • صفحة ${info.startPage}';
  }

  Map<String, dynamic> toJson() => {
    'juzNumber': juzNumber,
    'lastReadPage': lastReadPage,
    'lastReadSurahId': lastReadSurahId,
    'lastReadSurahName': lastReadSurahName,
    'lastReadAyah': lastReadAyah,
    'isCompleted': isCompleted,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory JuzProgress.fromJson(Map<String, dynamic> json) => JuzProgress(
    juzNumber: json['juzNumber'] as int,
    lastReadPage: json['lastReadPage'] as int?,
    lastReadSurahId: json['lastReadSurahId'] as int?,
    lastReadSurahName: json['lastReadSurahName'] as String?,
    lastReadAyah: json['lastReadAyah'] as int?,
    isCompleted: json['isCompleted'] as bool? ?? false,
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
  );
}
