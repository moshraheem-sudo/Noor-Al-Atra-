import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Verify all 12 Hijri months exist in worship_data.json with authentic titles', () {
    final file = File('assets/data/worship_data.json');
    expect(file.existsSync(), true);

    final Map<String, dynamic> data = json.decode(file.readAsStringSync());

    const expectedKeys = [
      'aamal_muharram',
      'aamal_safar',
      'aamal_rabi1',
      'aamal_rabi2',
      'aamal_jumada1',
      'aamal_jumada2',
      'aamal_rajab',
      'aamal_shaban',
      'aamal_ramadan',
      'aamal_shawwal',
      'aamal_dhul_qada',
      'aamal_dhul_hijjah',
    ];

    for (final key in expectedKeys) {
      expect(data.containsKey(key), true, reason: 'Key $key must exist');
      final list = data[key] as List<dynamic>;
      expect(list.isNotEmpty, true, reason: 'Key $key must have items');
      for (final item in list) {
        expect(item['title'] != null && (item['title'] as String).isNotEmpty, true);
        expect(item['text'] != null, true);
      }
    }

    // Verify specific titles matching screenshots
    final muharram = data['aamal_muharram'] as List;
    final muharramTitles = muharram.map((e) => e['title']).toList();
    expect(muharramTitles.contains('أعمال الليلة الاولى - محرم الحرام'), true);
    expect(muharramTitles.contains('أعمال اليوم الأول - محرم الحرام'), true);
    expect(muharramTitles.contains('أعمال اليوم التاسع - محرم الحرام (تاسوعاء)'), true);
    expect(muharramTitles.contains('أعمال اليوم العاشر - محرم الحرام (عاشوراء)'), true);

    final ramadan = data['aamal_ramadan'] as List;
    final ramadanTitles = ramadan.map((e) => e['title']).toList();
    expect(ramadanTitles.contains('خطبة النبي (ص) في استقبال شهر رمضان'), true);
    expect(ramadanTitles.contains('دعوات الأيام المشهورة لشهر رمضان'), true);
    expect(ramadanTitles.contains('صلوات ليالي شهر رمضان'), true);
    expect(ramadanTitles.contains('أعمال أسحار شهر رمضان المبارك'), true);
    expect(ramadan.length, 29);

    final shawwal = data['aamal_shawwal'] as List;
    final shawwalTitles = shawwal.map((e) => e['title']).toList();
    expect(shawwalTitles.contains('أعمال الليلة الأولى من شوال (ليلة عيد الفطر)'), true);
    expect(shawwalTitles.contains('أعمال اليوم الأول من شوال (يوم عيد الفطر)'), true);
    expect(shawwalTitles.contains('صلاة عيد الفطر السعيد وأدعيتها'), true);
    expect(shawwalTitles.contains('خطبة عيد الفطر لأمير المؤمنين (عليه السلام)'), true);
    expect(shawwalTitles.contains('زيارة الإمام الحسين (ع) في عيدي الفطر والأضحى'), true);
    expect(shawwal.length, 7);

    final safar = data['aamal_safar'] as List;
    final safarTitles = safar.map((e) => e['title']).toList();
    expect(safarTitles.contains('أعمال اليوم الأول - صفر'), true);
    expect(safarTitles.contains('أعمال اليوم الثالث - صفر'), true);
    expect(safarTitles.contains('أعمال يوم العشرين - صفر (يوم الأربعين)'), true);

    final rabi1 = data['aamal_rabi1'] as List;
    final rabi1Titles = rabi1.map((e) => e['title']).toList();
    expect(rabi1Titles.contains('أعمال اليوم الأول - ربيع الأول'), true);
    expect(rabi1Titles.contains('صلاة الليالي البيض - ربيع الأول (13 و 14 و 15)'), true);
    expect(rabi1Titles.contains('أعمال اليوم السابع عشر - ربيع الأول'), true);

    final rajab = data['aamal_rajab'] as List;
    final rajabTitles = rajab.map((e) => e['title']).toList();
    expect(rajabTitles.contains('أعمال اليوم الاول - رجب'), true);
    expect(rajabTitles.contains('أعمال ليلة الرغائب'), true);

    final dhulQada = data['aamal_dhul_qada'] as List;
    final dhulQadaTitles = dhulQada.map((e) => e['title']).toList();
    expect(dhulQadaTitles.contains('الأعمال العامة - ذو القعدة (صلاة التوبة)'), true);
    expect(dhulQadaTitles.contains('أعمال اليوم الأول - ذو القعدة (ولادة السيدة المعصومة ع)'), true);
    expect(dhulQadaTitles.contains('اليوم الحادي عشر - ذو القعدة (ولادة الإمام الرضا ع)'), true);
    expect(dhulQadaTitles.contains('اللّيلة الخامسة عشرة - ذو القعدة'), true);
    expect(dhulQadaTitles.contains('اليوم الثّالِثُ والعِشرون - ذو القعدة (زيارة الرضا ع)'), true);
    expect(dhulQadaTitles.contains('أعمال الليلة الخامسة والعشرين - ذو القعدة (ليلة دحو الأرض)'), true);
    expect(dhulQadaTitles.contains('أعمال اليوم الخامس والعشرين - ذو القعدة (يوم دحو الأرض)'), true);
    expect(dhulQadaTitles.contains('اليوم الأخير من شهر ذي القعدة (شهادة الإمام الجواد ع)'), true);
    expect(dhulQada.length, 8);

    final dhulHijjah = data['aamal_dhul_hijjah'] as List;
    final dhulHijjahTitles = dhulHijjah.map((e) => e['title']).toList();
    expect(dhulHijjahTitles.contains('أعمال العشرة الأولى من شهر ذي الحجة (الأيام المعلومات)'), true);
    expect(dhulHijjahTitles.contains('أعمال اليوم الأول من ذي الحجة (زواج النورين)'), true);
    expect(dhulHijjahTitles.contains('أعمال اليوم السابع من ذي الحجة (شهادة الإمام الباقر عليه السلام)'), true);
    expect(dhulHijjahTitles.contains('أعمال يوم التروية (8 ذو الحجة)'), true);
    expect(dhulHijjahTitles.contains('أعمال ليلة عرفة (الليلة التاسعة من ذي الحجة)'), true);
    expect(dhulHijjahTitles.contains('أعمال يوم عرفة (9 ذو الحجة)'), true);
    expect(dhulHijjahTitles.contains('أعمال ليلة عيد الأضحى المبارك (الليلة العاشرة من ذي الحجة)'), true);
    expect(dhulHijjahTitles.contains('أعمال يوم عيد الأضحى المبارك (10 ذو الحجة)'), true);
    expect(dhulHijjahTitles.contains('أعمال ليلة عيد الغدير الأغر (الليلة الثامنة عشرة من ذي الحجة)'), true);
    expect(dhulHijjahTitles.contains('أعمال يوم عيد الغدير الأغر (18 ذو الحجة - عيد الله الأكبر)'), true);
    expect(dhulHijjahTitles.contains('أعمال يوم المباهلة والتصدق بالخاتم (24 ذو الحجة)'), true);
    expect(dhulHijjahTitles.contains('أعمال اليوم الخامس والعشرين من ذي الحجة (نزول سورة هل أتى)'), true);
    expect(dhulHijjahTitles.contains('أعمال اليوم الأخير من شهر ذي الحجة (خاتمة السنة الهجرية)'), true);
    expect(dhulHijjah.length, 13);
  });
}
