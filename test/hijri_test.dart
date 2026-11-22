import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/services/hijri_date_service.dart';

void main() {
  test('Verify Hijri calculation matches repository anchor for 1448 AH', () {
    // Anchor date in repo: 2026-09-13 is 1 Rabi' al-Thani 1448 AH
    final anchorHijri = HijriDateService.getHijriDate(DateTime(2026, 9, 13));
    expect(anchorHijri['day'], 1);
    expect(anchorHijri['month'], 4);
    expect(anchorHijri['year'], 1448);
    expect(anchorHijri['monthName'], 'ربيع الآخر');

    // 20 days later: 2026-10-03 is 21 Rabi' al-Thani 1448 AH
    final oct3Hijri = HijriDateService.getHijriDate(DateTime(2026, 10, 3));
    expect(oct3Hijri['day'], 21);
    expect(oct3Hijri['month'], 4);
    expect(oct3Hijri['year'], 1448);
    expect(oct3Hijri['monthName'], 'ربيع الآخر');
    expect(oct3Hijri['weekday'], 'السبت');
  });
}
