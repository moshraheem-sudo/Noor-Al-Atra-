import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/services/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SettingsController defaults to general muezzin for all prayers', () async {
    final settings = SettingsController();
    await settings.init();

    expect(settings.selectedMuezzin, 'الحاج عامر الكاظمي');
    expect(settings.getMuezzinForPrayer('fajr'), 'الحاج عامر الكاظمي');
    expect(settings.getMuezzinForPrayer('صلاة الفجر'), 'الحاج عامر الكاظمي');
    expect(settings.getMuezzinForPrayer('dhuhr'), 'الحاج عامر الكاظمي');
    expect(settings.getMuezzinForPrayer('صلاة الظهر'), 'الحاج عامر الكاظمي');
  });

  test('SettingsController customizes muezzin per prayer correctly and persists', () async {
    final settings = SettingsController();
    await settings.init();

    // Customize Fajr to Usama Karbalaei
    await settings.setPrayerMuezzin('fajr', 'الحاج أسامة الكربلائي');
    // Customize Dhuhr to Amer Kazemi
    await settings.setPrayerMuezzin('dhuhr', 'الحاج عامر الكاظمي');
    // Customize Asr to Rafea Ameri
    await settings.setPrayerMuezzin('asr', 'المقرئ رافع العامري');

    expect(settings.getMuezzinForPrayer('fajr'), 'الحاج أسامة الكربلائي');
    expect(settings.getMuezzinForPrayer('صلاة الفجر'), 'الحاج أسامة الكربلائي');
    expect(settings.getMuezzinForPrayer('dhuhr'), 'الحاج عامر الكاظمي');
    expect(settings.getMuezzinForPrayer('asr'), 'المقرئ رافع العامري');
    // Maghrib wasn't customized, should fallback to general
    expect(settings.getMuezzinForPrayer('maghrib'), 'الحاج عامر الكاظمي');

    // Reset Fajr back to default
    await settings.setPrayerMuezzin('fajr', null);
    expect(settings.getMuezzinForPrayer('fajr'), 'الحاج عامر الكاظمي');
  });
}
