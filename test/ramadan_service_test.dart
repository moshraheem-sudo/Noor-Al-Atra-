import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/models/worship_item.dart';
import 'package:flutter_noor_alatra/services/data_service.dart';
import 'package:flutter_noor_alatra/services/ramadan_aamal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RamadanAamalService splits all sections correctly', () async {
    final file = File('assets/data/worship_data.json');
    final Map<String, dynamic> data = json.decode(file.readAsStringSync());
    DataService().worshipData = {};
    data.forEach((key, value) {
      if (value is List) {
        DataService().worshipData[key] = value.map((item) {
          final map = item as Map<String, dynamic>;
          return WorshipItem.fromJson(map, categoryKey: key);
        }).toList();
      }
    });

    final sections = RamadanAamalService().getSections();
    expect(sections.isNotEmpty, true);
    print('Loaded ${sections.length} sections for Ramadan:');
    for (var s in sections) {
      print('  Section: ${s.title} (items: ${s.items.length})');
      for (var it in s.items) {
        expect(it.title.isNotEmpty, true);
        expect(it.text.isNotEmpty, true);
      }
    }

    final sahar = sections.firstWhere((s) => s.id == 'sahar');
    expect(sahar.items.length, 8);
    expect(sahar.items.any((i) => i.title.contains('البهاء')), true);
    expect(sahar.items.any((i) => i.title.contains('الثمالي')), true);
    final idrisItem = sahar.items.firstWhere((i) => i.title.contains('إدريس'));
    expect(idrisItem.text.contains('سُبْحانَكَ لا إِلهَ إِلاّ أَنْتَ يا رَبَّ كُلِّ شَيْءٍ وَوارِثَهُ'), true);

    final day1 = sections.firstWhere((s) => s.id == 'day1');
    expect(day1.items.length, 7);
    final day1Dua44 = day1.items.firstWhere((i) => i.title.contains('الرابع والأربعون'));
    print('day1Dua44 title: ${day1Dua44.title}');
    print('day1Dua44 text: ${day1Dua44.text.substring(0, 200.clamp(0, day1Dua44.text.length))}');
    expect(day1Dua44.text.contains('الصحيفة'), true);


    final salawat = sections.firstWhere((s) => s.id == 'salawat');
    expect(salawat.items.length >= 25, true);

    final daily = sections.firstWhere((s) => s.id == 'daily_duas');
    expect(daily.items.length >= 30, true);

  });
}
