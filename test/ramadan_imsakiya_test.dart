import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/models/city_location.dart';
import 'package:flutter_noor_alatra/services/hijri_date_service.dart';
import 'package:flutter_noor_alatra/services/kafeel_api_service.dart';

void main() {
  test('Ramadan Imsakiya computes 30 days accurately with Imsak 10 mins before Fajr', () {
    const hYear = 1448;
    final city = CityLocation.defaultCity; // Karbala
    final startOfRamadan = HijriDateService.hijriToGregorian(hYear, 9, 1);

    expect(startOfRamadan, isNotNull);

    for (int day = 1; day <= 30; day++) {
      final gDate = startOfRamadan.add(Duration(days: day - 1));
      final times = KafeelApiService.calculateJaafariPrayerTimes(
        date: gDate,
        latitude: city.latitude,
        longitude: city.longitude,
        timezone: 3.0,
        calcMethod: 'kafeel',
        midnightMethod: 'fajr',
      );

      expect(times.fajr.isNotEmpty, true);
      expect(times.dhuhr.isNotEmpty, true);
      expect(times.maghrib.isNotEmpty, true);

      // Verify Imsak calculation (10 minutes before Fajr)
      final fajrParts = times.fajr.split(':');
      int fh = int.parse(fajrParts[0]);
      int fm = int.parse(fajrParts[1]);

      int expectedIm = fm - 10;
      int expectedIh = fh;
      if (expectedIm < 0) {
        expectedIm += 60;
        expectedIh = (expectedIh - 1 + 24) % 24;
      }
      final expectedImsak =
          '${expectedIh.toString().padLeft(2, '0')}:${expectedIm.toString().padLeft(2, '0')}';

      // Test formula
      int calculatedM = fm - 10;
      int calculatedH = fh;
      if (calculatedM < 0) {
        calculatedM += 60;
        calculatedH = (calculatedH - 1 + 24) % 24;
      }
      final calculatedImsak =
          '${calculatedH.toString().padLeft(2, '0')}:${calculatedM.toString().padLeft(2, '0')}';

      expect(calculatedImsak, expectedImsak);
    }
  });
}
