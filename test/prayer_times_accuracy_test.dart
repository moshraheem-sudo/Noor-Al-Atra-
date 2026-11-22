import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/models/city_location.dart';
import 'package:flutter_noor_alatra/services/kafeel_api_service.dart';

void main() {
  test('Verify prayer times for Samarra match official Jaafari reference table exactly', () {
    final samarra = CityLocation(
      id: 'samarra',
      nameAr: 'سامراء المقدسة',
      nameEn: 'Samarra',
      countryAr: 'العراق',
      latitude: 34.1983,
      longitude: 43.8742,
      timezone: '+3',
      isHolyCity: true,
      province: 'صلاح الدين',
    );

    final times = KafeelApiService.calculateJaafariPrayerTimes(
      date: DateTime(2026, 10, 5),
      latitude: samarra.latitude,
      longitude: samarra.longitude,
      timezone: 3.0,
      calcMethod: 'kafeel',
      midnightMethod: 'fajr',
    );

    // Exact match with official calendar reference for Samarra on 2026-10-05:
    expect(times.fajr, '04:39', reason: 'صلاة الصبح / الفجر');
    expect(times.sunrise, '06:02', reason: 'الشروق');
    expect(times.dhuhr, '11:53', reason: 'صلاة الظهر');
    expect(times.asr, '15:13', reason: 'صلاة العصر (03:13 م)');
    expect(times.sunset, '17:44', reason: 'الغروب (05:44 م)');
    expect(times.maghrib, '17:59', reason: 'صلاة المغرب (05:59 م)');
    expect(times.isha, '18:47', reason: 'صلاة العشاء (06:47 م)');
    expect(times.midnight, '23:11', reason: 'منتصف الليل الشرعي (11:11 م)');
  });
}
