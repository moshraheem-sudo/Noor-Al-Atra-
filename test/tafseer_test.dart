import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/models/tafseer_model.dart';
import 'package:flutter_noor_alatra/models/quran_chapter.dart';

void main() {
  group('Tafseer Models Tests', () {
    test('TafseerType metadata is correct', () {
      expect(TafseerType.almizan.displayName, 'الميزان في تفسير القرآن');
      expect(TafseerType.almizan.author, contains('الطباطبائي'));
      expect(TafseerType.almizan.dbFileName, 'tafsir_almizan_ar.db');

      expect(TafseerType.safi.displayName, 'تفسير الصافي');
      expect(TafseerType.safi.author, contains('الفيض الكاشاني'));
      expect(TafseerType.safi.dbFileName, 'tafsir_safi_ar.db');

      expect(TafseerType.fromId('almizan'), TafseerType.almizan);
      expect(TafseerType.fromId('safi'), TafseerType.safi);
    });

    test('TafseerEntry handles single ayah and ayah ranges correctly', () {
      const single = TafseerEntry(
        contentId: 1,
        type: TafseerType.safi,
        surahNumber: 1,
        startAyah: 1,
        endAyah: 1,
        content: 'تفسير البسملة',
        surahName: 'الفاتحة',
      );
      expect(single.isAyahRange, false);
      expect(single.ayahRangeText, 'الآية 1');
      expect(single.containsAyah(1), true);
      expect(single.containsAyah(2), false);

      const range = TafseerEntry(
        contentId: 2,
        type: TafseerType.almizan,
        surahNumber: 1,
        startAyah: 1,
        endAyah: 5,
        content: 'بيان الآيات من ١ إلى ٥',
        surahName: 'الفاتحة',
      );
      expect(range.isAyahRange, true);
      expect(range.ayahRangeText, 'الآيات 1 - 5');
      expect(range.containsAyah(1), true);
      expect(range.containsAyah(3), true);
      expect(range.containsAyah(5), true);
      expect(range.containsAyah(6), false);
    });

    test('TafseerFavorite serializes and deserializes cleanly', () {
      final fav = TafseerFavorite(
        id: 'almizan_2_255',
        type: TafseerType.almizan,
        surahNumber: 2,
        ayahNumber: 255,
        startAyah: 255,
        endAyah: 257,
        surahName: 'البقرة',
        snippet: 'الله لا إله إلا هو الحي القيوم',
        savedAt: DateTime(2026, 11, 27, 18, 0),
      );

      final jsonMap = fav.toJson();
      final restored = TafseerFavorite.fromJson(jsonMap);

      expect(restored.id, 'almizan_2_255');
      expect(restored.type, TafseerType.almizan);
      expect(restored.surahNumber, 2);
      expect(restored.ayahNumber, 255);
      expect(restored.startAyah, 255);
      expect(restored.endAyah, 257);
      expect(restored.surahName, 'البقرة');
      expect(restored.snippet, 'الله لا إله إلا هو الحي القيوم');
    });

    test('TafseerReadingPosition serializes and deserializes cleanly', () {
      final pos = TafseerReadingPosition(
        type: TafseerType.safi,
        surahNumber: 12,
        ayahNumber: 4,
        surahName: 'يوسف',
        updatedAt: DateTime(2026, 11, 27, 18, 15),
      );

      final jsonMap = pos.toJson();
      final restored = TafseerReadingPosition.fromJson(jsonMap);

      expect(restored.type, TafseerType.safi);
      expect(restored.surahNumber, 12);
      expect(restored.ayahNumber, 4);
      expect(restored.surahName, 'يوسف');
    });

    test('QuranChapter.getChapterById returns correct Surah', () {
      expect(QuranChapter.getChapterById(1)?.nameArabic, 'الفاتحة');
      expect(QuranChapter.getChapterById(2)?.nameArabic, 'البقرة');
      expect(QuranChapter.getChapterById(114)?.nameArabic, 'الناس');
      expect(QuranChapter.getChapterById(0), isNull);
      expect(QuranChapter.getChapterById(115), isNull);
    });
  });
}
