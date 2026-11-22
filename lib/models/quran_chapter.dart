class QuranChapter {
  final int id;
  final String nameArabic;
  final String nameSimple;
  final String revelationPlace; // makkah / madinah
  final int versesCount;

  const QuranChapter({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.revelationPlace,
    required this.versesCount,
  });

  bool get isMakki => revelationPlace.toLowerCase().contains('makkah');

  static const List<QuranChapter> allChapters = [
    QuranChapter(id: 1, nameArabic: 'الفاتحة', nameSimple: 'Al-Fatihah', revelationPlace: 'makkah', versesCount: 7),
    QuranChapter(id: 2, nameArabic: 'البقرة', nameSimple: 'Al-Baqarah', revelationPlace: 'madinah', versesCount: 286),
    QuranChapter(id: 3, nameArabic: 'آل عمران', nameSimple: 'Ali \'Imran', revelationPlace: 'madinah', versesCount: 200),
    QuranChapter(id: 4, nameArabic: 'النساء', nameSimple: 'An-Nisa', revelationPlace: 'madinah', versesCount: 176),
    QuranChapter(id: 5, nameArabic: 'المائدة', nameSimple: 'Al-Ma\'idah', revelationPlace: 'madinah', versesCount: 120),
    QuranChapter(id: 6, nameArabic: 'الأنعام', nameSimple: 'Al-An\'am', revelationPlace: 'makkah', versesCount: 165),
    QuranChapter(id: 7, nameArabic: 'الأعراف', nameSimple: 'Al-A\'raf', revelationPlace: 'makkah', versesCount: 206),
    QuranChapter(id: 8, nameArabic: 'الأنفال', nameSimple: 'Al-Anfal', revelationPlace: 'madinah', versesCount: 75),
    QuranChapter(id: 9, nameArabic: 'التوبة', nameSimple: 'At-Tawbah', revelationPlace: 'madinah', versesCount: 129),
    QuranChapter(id: 10, nameArabic: 'يونس', nameSimple: 'Yunus', revelationPlace: 'makkah', versesCount: 109),
    QuranChapter(id: 11, nameArabic: 'هود', nameSimple: 'Hud', revelationPlace: 'makkah', versesCount: 123),
    QuranChapter(id: 12, nameArabic: 'يوسف', nameSimple: 'Yusuf', revelationPlace: 'makkah', versesCount: 111),
    QuranChapter(id: 13, nameArabic: 'الرعد', nameSimple: 'Ar-Ra\'d', revelationPlace: 'madinah', versesCount: 43),
    QuranChapter(id: 14, nameArabic: 'إبراهيم', nameSimple: 'Ibrahim', revelationPlace: 'makkah', versesCount: 52),
    QuranChapter(id: 15, nameArabic: 'الحجر', nameSimple: 'Al-Hijr', revelationPlace: 'makkah', versesCount: 99),
    QuranChapter(id: 16, nameArabic: 'النحل', nameSimple: 'An-Nahl', revelationPlace: 'makkah', versesCount: 128),
    QuranChapter(id: 17, nameArabic: 'الإسراء', nameSimple: 'Al-Isra', revelationPlace: 'makkah', versesCount: 111),
    QuranChapter(id: 18, nameArabic: 'الكهف', nameSimple: 'Al-Kahf', revelationPlace: 'makkah', versesCount: 110),
    QuranChapter(id: 19, nameArabic: 'مريم', nameSimple: 'Maryam', revelationPlace: 'makkah', versesCount: 98),
    QuranChapter(id: 20, nameArabic: 'طه', nameSimple: 'Taha', revelationPlace: 'makkah', versesCount: 135),
    QuranChapter(id: 21, nameArabic: 'الأنبياء', nameSimple: 'Al-Anbiya', revelationPlace: 'makkah', versesCount: 112),
    QuranChapter(id: 22, nameArabic: 'الحج', nameSimple: 'Al-Hajj', revelationPlace: 'madinah', versesCount: 78),
    QuranChapter(id: 23, nameArabic: 'المؤمنون', nameSimple: 'Al-Mu\'minun', revelationPlace: 'makkah', versesCount: 118),
    QuranChapter(id: 24, nameArabic: 'النور', nameSimple: 'An-Nur', revelationPlace: 'madinah', versesCount: 64),
    QuranChapter(id: 25, nameArabic: 'الفرقان', nameSimple: 'Al-Furqan', revelationPlace: 'makkah', versesCount: 77),
    QuranChapter(id: 26, nameArabic: 'الشعراء', nameSimple: 'Ash-Shu\'ara', revelationPlace: 'makkah', versesCount: 227),
    QuranChapter(id: 27, nameArabic: 'النمل', nameSimple: 'An-Naml', revelationPlace: 'makkah', versesCount: 93),
    QuranChapter(id: 28, nameArabic: 'القصص', nameSimple: 'Al-Qasas', revelationPlace: 'makkah', versesCount: 88),
    QuranChapter(id: 29, nameArabic: 'العنكبوت', nameSimple: 'Al-\'Ankabut', revelationPlace: 'makkah', versesCount: 69),
    QuranChapter(id: 30, nameArabic: 'الروم', nameSimple: 'Ar-Rum', revelationPlace: 'makkah', versesCount: 60),
    QuranChapter(id: 31, nameArabic: 'لقمان', nameSimple: 'Luqman', revelationPlace: 'makkah', versesCount: 34),
    QuranChapter(id: 32, nameArabic: 'السجدة', nameSimple: 'As-Sajdah', revelationPlace: 'makkah', versesCount: 30),
    QuranChapter(id: 33, nameArabic: 'الأحزاب', nameSimple: 'Al-Ahzab', revelationPlace: 'madinah', versesCount: 73),
    QuranChapter(id: 34, nameArabic: 'سبأ', nameSimple: 'Saba', revelationPlace: 'makkah', versesCount: 54),
    QuranChapter(id: 35, nameArabic: 'فاطر', nameSimple: 'Fatir', revelationPlace: 'makkah', versesCount: 45),
    QuranChapter(id: 36, nameArabic: 'يس', nameSimple: 'Ya-Sin', revelationPlace: 'makkah', versesCount: 83),
    QuranChapter(id: 37, nameArabic: 'الصافات', nameSimple: 'As-Saffat', revelationPlace: 'makkah', versesCount: 182),
    QuranChapter(id: 38, nameArabic: 'ص', nameSimple: 'Sad', revelationPlace: 'makkah', versesCount: 88),
    QuranChapter(id: 39, nameArabic: 'الزمر', nameSimple: 'Az-Zumar', revelationPlace: 'makkah', versesCount: 75),
    QuranChapter(id: 40, nameArabic: 'غافر', nameSimple: 'Ghafir', revelationPlace: 'makkah', versesCount: 85),
    QuranChapter(id: 41, nameArabic: 'فصلت', nameSimple: 'Fussilat', revelationPlace: 'makkah', versesCount: 54),
    QuranChapter(id: 42, nameArabic: 'الشورى', nameSimple: 'Ash-Shuraa', revelationPlace: 'makkah', versesCount: 53),
    QuranChapter(id: 43, nameArabic: 'الزخرف', nameSimple: 'Az-Zukhruf', revelationPlace: 'makkah', versesCount: 89),
    QuranChapter(id: 44, nameArabic: 'الدخان', nameSimple: 'Ad-Dukhan', revelationPlace: 'makkah', versesCount: 59),
    QuranChapter(id: 45, nameArabic: 'الجاثية', nameSimple: 'Al-Jathiyah', revelationPlace: 'makkah', versesCount: 37),
    QuranChapter(id: 46, nameArabic: 'الأحقاف', nameSimple: 'Al-Ahqaf', revelationPlace: 'makkah', versesCount: 35),
    QuranChapter(id: 47, nameArabic: 'محمد', nameSimple: 'Muhammad', revelationPlace: 'madinah', versesCount: 38),
    QuranChapter(id: 48, nameArabic: 'الفتح', nameSimple: 'Al-Fath', revelationPlace: 'madinah', versesCount: 29),
    QuranChapter(id: 49, nameArabic: 'الحجرات', nameSimple: 'Al-Hujurat', revelationPlace: 'madinah', versesCount: 18),
    QuranChapter(id: 50, nameArabic: 'ق', nameSimple: 'Qaf', revelationPlace: 'makkah', versesCount: 45),
    QuranChapter(id: 51, nameArabic: 'الذاريات', nameSimple: 'Adh-Dhariyat', revelationPlace: 'makkah', versesCount: 60),
    QuranChapter(id: 52, nameArabic: 'الطور', nameSimple: 'At-Tur', revelationPlace: 'makkah', versesCount: 49),
    QuranChapter(id: 53, nameArabic: 'النجم', nameSimple: 'An-Najm', revelationPlace: 'makkah', versesCount: 62),
    QuranChapter(id: 54, nameArabic: 'القمر', nameSimple: 'Al-Qamar', revelationPlace: 'makkah', versesCount: 55),
    QuranChapter(id: 55, nameArabic: 'الرحمن', nameSimple: 'Ar-Rahman', revelationPlace: 'madinah', versesCount: 78),
    QuranChapter(id: 56, nameArabic: 'الواقعة', nameSimple: 'Al-Waqi\'ah', revelationPlace: 'makkah', versesCount: 96),
    QuranChapter(id: 57, nameArabic: 'الحديد', nameSimple: 'Al-Hadid', revelationPlace: 'madinah', versesCount: 29),
    QuranChapter(id: 58, nameArabic: 'المجادلة', nameSimple: 'Al-Mujadila', revelationPlace: 'madinah', versesCount: 22),
    QuranChapter(id: 59, nameArabic: 'الحشر', nameSimple: 'Al-Hashr', revelationPlace: 'madinah', versesCount: 24),
    QuranChapter(id: 60, nameArabic: 'الممتحنة', nameSimple: 'Al-Mumtahanah', revelationPlace: 'madinah', versesCount: 13),
    QuranChapter(id: 61, nameArabic: 'الصف', nameSimple: 'As-Saf', revelationPlace: 'madinah', versesCount: 14),
    QuranChapter(id: 62, nameArabic: 'الجمعة', nameSimple: 'Al-Jumu\'ah', revelationPlace: 'madinah', versesCount: 11),
    QuranChapter(id: 63, nameArabic: 'المنافقون', nameSimple: 'Al-Munafiqun', revelationPlace: 'madinah', versesCount: 11),
    QuranChapter(id: 64, nameArabic: 'التغابن', nameSimple: 'At-Taghabun', revelationPlace: 'madinah', versesCount: 18),
    QuranChapter(id: 65, nameArabic: 'الطلاق', nameSimple: 'At-Talaq', revelationPlace: 'madinah', versesCount: 12),
    QuranChapter(id: 66, nameArabic: 'التحريم', nameSimple: 'At-Tahrim', revelationPlace: 'madinah', versesCount: 12),
    QuranChapter(id: 67, nameArabic: 'الملك', nameSimple: 'Al-Mulk', revelationPlace: 'makkah', versesCount: 30),
    QuranChapter(id: 68, nameArabic: 'القلم', nameSimple: 'Al-Qalam', revelationPlace: 'makkah', versesCount: 52),
    QuranChapter(id: 69, nameArabic: 'الحاقة', nameSimple: 'Al-Haqqah', revelationPlace: 'makkah', versesCount: 52),
    QuranChapter(id: 70, nameArabic: 'المعارج', nameSimple: 'Al-Ma\'arij', revelationPlace: 'makkah', versesCount: 44),
    QuranChapter(id: 71, nameArabic: 'نوح', nameSimple: 'Nuh', revelationPlace: 'makkah', versesCount: 28),
    QuranChapter(id: 72, nameArabic: 'الجن', nameSimple: 'Al-Jinn', revelationPlace: 'makkah', versesCount: 28),
    QuranChapter(id: 73, nameArabic: 'المزمل', nameSimple: 'Al-Muzzammil', revelationPlace: 'makkah', versesCount: 20),
    QuranChapter(id: 74, nameArabic: 'المدثر', nameSimple: 'Al-Muddaththir', revelationPlace: 'makkah', versesCount: 56),
    QuranChapter(id: 75, nameArabic: 'القيامة', nameSimple: 'Al-Qiyamah', revelationPlace: 'makkah', versesCount: 40),
    QuranChapter(id: 76, nameArabic: 'الإنسان', nameSimple: 'Al-Insan', revelationPlace: 'madinah', versesCount: 31),
    QuranChapter(id: 77, nameArabic: 'المرسلات', nameSimple: 'Al-Mursalat', revelationPlace: 'makkah', versesCount: 50),
    QuranChapter(id: 78, nameArabic: 'النبأ', nameSimple: 'An-Naba', revelationPlace: 'makkah', versesCount: 40),
    QuranChapter(id: 79, nameArabic: 'النازعات', nameSimple: 'An-Nazi\'at', revelationPlace: 'makkah', versesCount: 46),
    QuranChapter(id: 80, nameArabic: 'عبس', nameSimple: '\'Abasa', revelationPlace: 'makkah', versesCount: 42),
    QuranChapter(id: 81, nameArabic: 'التكوير', nameSimple: 'At-Takwir', revelationPlace: 'makkah', versesCount: 29),
    QuranChapter(id: 82, nameArabic: 'الانفطار', nameSimple: 'Al-Infitar', revelationPlace: 'makkah', versesCount: 19),
    QuranChapter(id: 83, nameArabic: 'المطففين', nameSimple: 'Al-Mutaffifin', revelationPlace: 'makkah', versesCount: 36),
    QuranChapter(id: 84, nameArabic: 'الانشقاق', nameSimple: 'Al-Inshiqaq', revelationPlace: 'makkah', versesCount: 25),
    QuranChapter(id: 85, nameArabic: 'البروج', nameSimple: 'Al-Buruj', revelationPlace: 'makkah', versesCount: 22),
    QuranChapter(id: 86, nameArabic: 'الطارق', nameSimple: 'At-Tariq', revelationPlace: 'makkah', versesCount: 17),
    QuranChapter(id: 87, nameArabic: 'الأعلى', nameSimple: 'Al-A\'la', revelationPlace: 'makkah', versesCount: 19),
    QuranChapter(id: 88, nameArabic: 'الغاشية', nameSimple: 'Al-Ghashiyah', revelationPlace: 'makkah', versesCount: 26),
    QuranChapter(id: 89, nameArabic: 'الفجر', nameSimple: 'Al-Fajr', revelationPlace: 'makkah', versesCount: 30),
    QuranChapter(id: 90, nameArabic: 'البلد', nameSimple: 'Al-Balad', revelationPlace: 'makkah', versesCount: 20),
    QuranChapter(id: 91, nameArabic: 'الشمس', nameSimple: 'Ash-Shams', revelationPlace: 'makkah', versesCount: 15),
    QuranChapter(id: 92, nameArabic: 'الليل', nameSimple: 'Al-Layl', revelationPlace: 'makkah', versesCount: 21),
    QuranChapter(id: 93, nameArabic: 'الضحى', nameSimple: 'Ad-Duhaa', revelationPlace: 'makkah', versesCount: 11),
    QuranChapter(id: 94, nameArabic: 'الشرح', nameSimple: 'Ash-Sharh', revelationPlace: 'makkah', versesCount: 8),
    QuranChapter(id: 95, nameArabic: 'التين', nameSimple: 'At-Tin', revelationPlace: 'makkah', versesCount: 8),
    QuranChapter(id: 96, nameArabic: 'العلق', nameSimple: 'Al-\'Alaq', revelationPlace: 'makkah', versesCount: 19),
    QuranChapter(id: 97, nameArabic: 'القدر', nameSimple: 'Al-Qadr', revelationPlace: 'makkah', versesCount: 5),
    QuranChapter(id: 98, nameArabic: 'البينة', nameSimple: 'Al-Bayyinah', revelationPlace: 'madinah', versesCount: 8),
    QuranChapter(id: 99, nameArabic: 'الزلزلة', nameSimple: 'Az-Zalzalah', revelationPlace: 'madinah', versesCount: 8),
    QuranChapter(id: 100, nameArabic: 'العاديات', nameSimple: 'Al-\'Adiyat', revelationPlace: 'makkah', versesCount: 11),
    QuranChapter(id: 101, nameArabic: 'القارعة', nameSimple: 'Al-Qari\'ah', revelationPlace: 'makkah', versesCount: 11),
    QuranChapter(id: 102, nameArabic: 'التكاثر', nameSimple: 'At-Takathur', revelationPlace: 'makkah', versesCount: 8),
    QuranChapter(id: 103, nameArabic: 'العصر', nameSimple: 'Al-\'Asr', revelationPlace: 'makkah', versesCount: 3),
    QuranChapter(id: 104, nameArabic: 'الهمزة', nameSimple: 'Al-Humazah', revelationPlace: 'makkah', versesCount: 9),
    QuranChapter(id: 105, nameArabic: 'الفيل', nameSimple: 'Al-Fil', revelationPlace: 'makkah', versesCount: 5),
    QuranChapter(id: 106, nameArabic: 'قريش', nameSimple: 'Quraysh', revelationPlace: 'makkah', versesCount: 4),
    QuranChapter(id: 107, nameArabic: 'الماعون', nameSimple: 'Al-Ma\'un', revelationPlace: 'makkah', versesCount: 7),
    QuranChapter(id: 108, nameArabic: 'الكوثر', nameSimple: 'Al-Kawthar', revelationPlace: 'makkah', versesCount: 3),
    QuranChapter(id: 109, nameArabic: 'الكافرون', nameSimple: 'Al-Kafirun', revelationPlace: 'makkah', versesCount: 6),
    QuranChapter(id: 110, nameArabic: 'النصر', nameSimple: 'An-Nasr', revelationPlace: 'madinah', versesCount: 3),
    QuranChapter(id: 111, nameArabic: 'المسد', nameSimple: 'Al-Masad', revelationPlace: 'makkah', versesCount: 5),
    QuranChapter(id: 112, nameArabic: 'الإخلاص', nameSimple: 'Al-Ikhlas', revelationPlace: 'makkah', versesCount: 4),
    QuranChapter(id: 113, nameArabic: 'الفلق', nameSimple: 'Al-Falaq', revelationPlace: 'makkah', versesCount: 5),
    QuranChapter(id: 114, nameArabic: 'الناس', nameSimple: 'An-Nas', revelationPlace: 'makkah', versesCount: 6),
  ];
}

class VerseItem {
  final int id;
  final String verseKey;
  final String textUthmani;

  VerseItem({
    required this.id,
    required this.verseKey,
    required this.textUthmani,
  });

  static final RegExp _kasraDotlessYaRegex = RegExp(r'([\u0650])\u0649(?!\u0670|\u064B)');

  static String sanitizeUthmaniText(String text) {
    if (text.isEmpty) return text;
    var sanitized = text
        .replaceAll('فِى', 'فِي')
        .replaceAll('فِىٓ', 'فِيٓ')
        .replaceAll('وَفِى', 'وَفِي')
        .replaceAll('لَفِى', 'لَفِي')
        .replaceAll('فَفِى', 'فَفِي')
        .replaceAll('أَفِى', 'أَفِي')
        .replaceAll('شَىْءٍ', 'شَيْءٍ')
        .replaceAll('شَىْءً', 'شَيْئًا')
        .replaceAll('هِىَ', 'هِيَ');
    // Replace any remaining kasra + dotless ya with kasra + dotted ya
    sanitized = sanitized.replaceAllMapped(_kasraDotlessYaRegex, (match) => '${match.group(1)}\u064A');
    return sanitized;
  }

  factory VerseItem.fromJson(Map<String, dynamic> json) {
    final rawText = json['text_uthmani'] as String? ?? '';
    return VerseItem(
      id: json['id'] as int? ?? 0,
      verseKey: json['verse_key'] as String? ?? '',
      textUthmani: sanitizeUthmaniText(rawText),
    );
  }
}
