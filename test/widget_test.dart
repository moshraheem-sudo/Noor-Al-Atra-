import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/services/hijri_date_service.dart';
import 'package:flutter_noor_alatra/models/prayer_times.dart';
import 'package:flutter_noor_alatra/widgets/quran_verse_share_sheet.dart';

void main() {
  test('HijriDateService returns accurate Shia Najaf lunar date for Sep 25, 2026', () {
    final hijri = HijriDateService.getHijriDate(DateTime(2026, 9, 25));
    expect(hijri['day'], 13);
    expect(hijri['monthName'], 'ربيع الآخر');
    expect(hijri['year'], 1448);
    expect(hijri['shortFormatted'], '13 ربيع الآخر 1448 هـ');
  });

  test('HijriDateService hijriToGregorian and getDaysInHijriMonth work accurately', () {
    final gDate = HijriDateService.hijriToGregorian(1448, 4, 15);
    expect(gDate.year, 2026);
    expect(gDate.month, 9);
    expect(gDate.day, 27);

    final days = HijriDateService.getDaysInHijriMonth(1448, 4);
    expect(days, 29);

    final arabicDigits = HijriDateService.toArabicDigits(15);
    expect(arabicDigits, '١٥');
  });

  test('HijriDateService provides daily deeds for Friday', () {
    final deeds = HijriDateService.getDeedsForDay(DateTime(2026, 9, 25)); // Friday
    expect(deeds.isNotEmpty, true);
    expect(deeds.any((d) => d['title'] == 'دعاء يوم الجمعة'), true);
    expect(deeds.any((d) => d['title'] == 'زيارة يوم الجمعة'), true);
  });

  test('PrayerTimesModel fallback returns expected default times', () {
    final model = PrayerTimesModel.fallback();
    expect(model.dhuhr, '11:57');
    expect(model.fajr, '04:32');
    expect(model.dateHijri, '13 ربيع الآخر 1448 هـ');
  });

  testWidgets('QuranVerseShareSheet renders successfully with interactive controls and action buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuranVerseShareSheet(
            surahName: 'البقرة',
            ayahNum: 186,
            ayahText: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
          ),
        ),
      ),
    );

    expect(find.text('شارك الآية كصورة'), findsOneWidget);
    expect(find.text('إظهار البسملة أعلى الصورة'), findsOneWidget);
    expect(find.text('إضافة صدق الله العلي العظيم'), findsOneWidget);
    expect(find.text('مشاركة الصورة'), findsOneWidget);
    expect(find.text('تحميل الصورة'), findsOneWidget);
  });
}

