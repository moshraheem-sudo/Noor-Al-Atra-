class PrayerTimesModel {
  final String imsak;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String sunset;
  final String maghrib;
  final String isha;
  final String midnight;
  final String dateGregorian;
  final String dateHijri;
  final String source; // "مركز الكفيل" or "Aladhan"

  PrayerTimesModel({
    required this.imsak,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.midnight,
    required this.dateGregorian,
    required this.dateHijri,
    required this.source,
  });

  Map<String, String> get asMap => {
        'الإمساك': imsak,
        'الفجر': fajr,
        'الشروق': sunrise,
        'الظهر': dhuhr,
        'العصر': asr,
        'الغروب': sunset,
        'المغرب': maghrib,
        'العشاء': isha,
        'منتصف الليل': midnight,
      };

  static PrayerTimesModel fallback() {
    return PrayerTimesModel(
      imsak: '04:18',
      fajr: '04:32',
      sunrise: '05:54',
      dhuhr: '11:57',
      asr: '15:22',
      sunset: '17:58',
      maghrib: '18:13',
      isha: '19:00',
      midnight: '23:15',
      dateGregorian: '2026-09-25',
      dateHijri: '13 ربيع الآخر 1448 هـ',
      source: 'مركز الكفيل للثقافة والإعلام',
    );
  }
}
