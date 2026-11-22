class QuranSajdahInfo {
  final int surahId;
  final int ayahNumber;
  final bool isObligatory; // true = واجبة, false = مستحبة
  final List<String> keywords; // الكلمات الدالة لوضع الخط فوقها / تحتها
  final String note;

  const QuranSajdahInfo({
    required this.surahId,
    required this.ayahNumber,
    required this.isObligatory,
    required this.keywords,
    required this.note,
  });

  String get typeText => isObligatory ? 'سجدة تلاوة واجبة' : 'سجدة تلاوة مستحبة';
  String get shortBadge => isObligatory ? 'سجدة واجبة' : 'سجدة مستحبة';

  /// قائمة جميع سجدات القرآن الكريم (٤ واجبة و ١١ مستحبة)
  static const List<QuranSajdahInfo> allSajdahs = [
    // --- السجدات الواجبة (العزائم الأربعة) ---
    QuranSajdahInfo(
      surahId: 32, // السجدة
      ayahNumber: 15,
      isObligatory: true,
      keywords: ['وهم لا يستكبرون', 'لا يستكبرون', 'خروا سجدا', 'سجدا'],
      note: 'سورة السجدة - الآية 15 (سجدة واجبة)',
    ),
    QuranSajdahInfo(
      surahId: 41, // فصلت
      ayahNumber: 37,
      isObligatory: true,
      keywords: ['تعبدون', 'اياه تعبدون', 'واسجدوا لله'],
      note: 'سورة فصلت - الآية 37 (سجدة واجبة)',
    ),
    QuranSajdahInfo(
      surahId: 53, // النجم
      ayahNumber: 62,
      isObligatory: true,
      keywords: ['فاسجدوا لله واعبدوا', 'فاسجدوا لله', 'واعبدوا'],
      note: 'سورة النجم - الآية 62 (سجدة واجبة)',
    ),
    QuranSajdahInfo(
      surahId: 96, // العلق
      ayahNumber: 19,
      isObligatory: true,
      keywords: ['واسجد واقترب', 'واسجد', 'واقترب'],
      note: 'سورة العلق - الآية 19 (سجدة واجبة)',
    ),

    // --- السجدات المستحبة (١١ سجدة) ---
    QuranSajdahInfo(
      surahId: 7, // الأعراف
      ayahNumber: 206,
      isObligatory: false,
      keywords: ['وله يسجدون', 'يسجدون'],
      note: 'سورة الأعراف - الآية 206 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 13, // الرعد
      ayahNumber: 15,
      isObligatory: false,
      keywords: ['وظلالهم بالغدو والاصال', 'بالغدو والاصال', 'يسجد من في السماوات'],
      note: 'سورة الرعد - الآية 15 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 16, // النحل
      ayahNumber: 50,
      isObligatory: false,
      keywords: ['ويفعلون ما يؤمرون', 'ما يؤمرون', 'يخافون ربهم'],
      note: 'سورة النحل - الآية 50 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 17, // الإسراء
      ayahNumber: 109,
      isObligatory: false,
      keywords: ['ويزيدهم خشوعا', 'خشوعا', 'يخرون للاذقان'],
      note: 'سورة الإسراء - الآية 109 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 19, // مريم
      ayahNumber: 58,
      isObligatory: false,
      keywords: ['وخروا سجدا وبكيا', 'خروا سجدا وبكيا', 'سجدا وبكيا'],
      note: 'سورة مريم - الآية 58 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 22, // الحج - السجدة الأولى
      ayahNumber: 18,
      isObligatory: false,
      keywords: ['ان الله يفعل ما يشاء', 'يفعل ما يشاء', 'يسجد له من في السماوات'],
      note: 'سورة الحج - الآية 18 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 22, // الحج - السجدة الثانية
      ayahNumber: 77,
      isObligatory: false,
      keywords: ['لعلكم تفلحون', 'واسجدوا واعبدوا ربكم', 'واسجدوا'],
      note: 'سورة الحج - الآية 77 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 25, // الفرقان
      ayahNumber: 60,
      isObligatory: false,
      keywords: ['وزادهم نفورا', 'نفورا', 'اسجدوا للرحمن'],
      note: 'سورة الفرقان - الآية 60 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 27, // النمل
      ayahNumber: 26,
      isObligatory: false,
      keywords: ['رب العرش العظيم', 'العرش العظيم', 'الله لا اله الا هو'],
      note: 'سورة النمل - الآية 26 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 38, // ص
      ayahNumber: 24,
      isObligatory: false,
      keywords: ['وخر راكعا واناب', 'خر راكعا واناب', 'راكعا واناب'],
      note: 'سورة ص - الآية 24 (سجدة مستحبة)',
    ),
    QuranSajdahInfo(
      surahId: 84, // الانشقاق
      ayahNumber: 21,
      isObligatory: false,
      keywords: ['لا يسجدون', 'واذا قري عليهم القران لا يسجدون'],
      note: 'سورة الانشقاق - الآية 21 (سجدة مستحبة)',
    ),
  ];

  /// جلب معلومات السجدة برقم السورة ورقم الآية إن وجدت
  static QuranSajdahInfo? getSajdah(int surahId, int ayahNumber) {
    for (final s in allSajdahs) {
      if (s.surahId == surahId && s.ayahNumber == ayahNumber) {
        return s;
      }
    }
    return null;
  }

  /// هل الآية تحتوي على سجدة؟
  static bool isSajdahAyah(int surahId, int ayahNumber) {
    return getSajdah(surahId, ayahNumber) != null;
  }
}
