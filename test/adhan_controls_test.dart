import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_noor_alatra/models/prayer_times.dart';
import 'package:flutter_noor_alatra/services/settings_controller.dart';
import 'package:flutter_noor_alatra/services/app_notification_service.dart';
import 'package:flutter_noor_alatra/services/adhan_scheduler_service.dart';
import 'package:flutter_noor_alatra/widgets/active_adhan_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications =
      MethodChannel('dexterous.com/flutter/local_notifications');
  final pending = <int, Map<dynamic, dynamic>>{};
  final audioCalls = <String>[];
  final notificationCalls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Completer<void>? playbackGate;
  Completer<void>? playbackEntered;
  Completer<void>? scheduleGate;
  Completer<void>? scheduleEntered;

  setUpAll(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(notifications, (call) async {
      notificationCalls.add(call);
      final args = call.arguments;
      switch (call.method) {
        case 'initialize':
        case 'requestPermissions':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {'notificationLaunchedApp': false};
        case 'zonedSchedule':
          if (scheduleGate != null) {
            scheduleEntered?.complete();
            await scheduleGate!.future;
            scheduleGate = null;
          }
          pending[args['id'] as int] = args as Map;
          return null;
        case 'show':
          if (playbackGate != null) {
            playbackEntered!.complete();
            await playbackGate!.future;
          }
          return null;
        case 'cancel':
          pending.remove(args is int ? args : args['id']);
          return null;
      }
      return null;
    });
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events'
    ]) {
      messenger.setMockMethodCallHandler(
          MethodChannel(name), (_) async => null);
    }
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      audioCalls.add(call.method);
      if (call.method == 'create') {
        final id = call.arguments['playerId'];
        messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.example.flutter_noor_alatra/wakelock'),
        (_) async => true);
    SharedPreferences.setMockInitialValues({});
    await SettingsController().init();
    await AppNotificationService().init();
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> scheduleTomorrow() =>
      AppNotificationService().schedulePrayerAlarmsAndReminders(
          prayerTimes: PrayerTimesModel.fallback(),
          date: DateTime.now().add(const Duration(days: 1)));

  test(
      'disabling prayers removes existing OS schedules; re-enabling restores only that prayer',
      () async {
    await scheduleTomorrow();
    expect(
        pending.values.where((p) => p['payload'] == 'adhan_fajr'), isNotEmpty);
    for (final prayer in [
      'fajr',
      'sunrise',
      'dhuhr',
      'asr',
      'maghrib',
      'isha'
    ]) {
      await SettingsController().setPrayerNotification(prayer, false);
    }
    expect(pending, isEmpty);
    audioCalls.clear();
    await AdhanSchedulerService().playAdhan(prayerName: 'الفجر');
    expect(audioCalls.where((method) => method == 'resume'), isEmpty);
    expect(AdhanSchedulerService().isPlayingAdhan, false);
    await SettingsController().setPrayerNotification('fajr', true);
    expect(
        pending.values
            .where((p) => (p['payload'] as String).startsWith('adhan_'))
            .map((p) => p['payload']),
        ['adhan_fajr']);
  });

  test('disable wins over an older schedule still in flight', () async {
    scheduleGate = Completer<void>();
    scheduleEntered = Completer<void>();
    final scheduling = scheduleTomorrow();
    await scheduleEntered!.future;
    final disabling = SettingsController().setPrayerNotification('fajr', false);
    scheduleGate!.complete();
    await Future.wait([scheduling, disabling]);
    expect(pending, isEmpty);
  });

  test('turning reminders off removes them without disabling the adhan',
      () async {
    await SettingsController().setPrayerNotification('fajr', true);
    await SettingsController().setNotifyPrePrayer15Min(true);
    expect(
        pending.values
            .where((p) => (p['payload'] as String).startsWith('approaching_')),
        isNotEmpty);
    await SettingsController().setNotifyPrePrayer15Min(false);
    expect(
        pending.values
            .where((p) => (p['payload'] as String).startsWith('approaching_')),
        isEmpty);
    expect(
        pending.values.where((p) => p['payload'] == 'adhan_fajr'), isNotEmpty);
  });

  test(
      'iOS registers stop action and notification body tap stops the owning player',
      () async {
    final initialization =
        notificationCalls.firstWhere((c) => c.method == 'initialize');
    expect(initialization.arguments.toString(), contains('adhan_controls'));
    expect(initialization.arguments.toString(), contains('stop_adhan'));
    audioCalls.clear();
    final complete = Completer<void>();
    messenger.handlePlatformMessage(
        notifications.name,
        const StandardMethodCodec().encodeMethodCall(
            const MethodCall('didReceiveNotificationResponse', {
          'notificationResponseType': 0,
          'id': 4099,
          'payload': 'adhan_fajr',
        })),
        (_) => complete.complete());
    await complete.future;
    await Future<void>.delayed(Duration.zero);
    expect(audioCalls, contains('stop'));
    expect(AdhanSchedulerService().isPlayingAdhan, false);
    expect(
        pending.values.where((p) => p['payload'] == 'adhan_fajr'), isNotEmpty);
  });

  test('explicit notification stop action also stops audio', () async {
    audioCalls.clear();
    final complete = Completer<void>();
    messenger.handlePlatformMessage(
        notifications.name,
        const StandardMethodCodec().encodeMethodCall(
            const MethodCall('didReceiveNotificationResponse', {
          'notificationResponseType': 1,
          'actionId': 'stop_adhan',
          'id': 4099,
          'payload': 'adhan_fajr',
        })),
        (_) => complete.complete());
    await complete.future;
    await Future<void>.delayed(Duration.zero);
    expect(audioCalls, contains('stop'));
  });

  test(
      'stop during audio preparation prevents delayed playback from restarting',
      () async {
    playbackGate = Completer<void>();
    playbackEntered = Completer<void>();
    final playing =
        AdhanSchedulerService().playAdhan(prayerName: 'الفجر (تجربة الأذان)');
    await playbackEntered!.future;
    audioCalls.clear();
    await AdhanSchedulerService().stopAdhan();
    playbackGate!.complete();
    await playing;
    playbackGate = null;
    expect(audioCalls, contains('stop'));
    expect(audioCalls, isNot(contains('resume')));
    expect(AdhanSchedulerService().isPlayingAdhan, false);
  });

  testWidgets('stop card works without an OS notification', (tester) async {
    final scheduler = AdhanSchedulerService();
    scheduler.isPlayingAdhanNotifier.value = true;
    scheduler.currentAdhanPrayerNotifier.value = 'الفجر';
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ActiveAdhanBanner(isDark: false))));
    expect(find.text('إيقاف'), findsOneWidget);
    await tester.tap(find.text('إيقاف'));
    await tester.pump();
    expect(scheduler.isPlayingAdhan, false);
    expect(find.text('إيقاف'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}
