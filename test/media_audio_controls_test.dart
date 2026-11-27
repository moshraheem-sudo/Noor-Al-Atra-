import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_noor_alatra/services/audio_player_service.dart';
import 'package:flutter_noor_alatra/services/audio_player_manager.dart';
import 'package:flutter_noor_alatra/services/media_audio_handler.dart';
import 'package:flutter_noor_alatra/services/quran_audio_download_service.dart';
import 'package:flutter_noor_alatra/models/reciter.dart';
import 'package:flutter_noor_alatra/widgets/mini_audio_player.dart';
import 'package:flutter_noor_alatra/widgets/full_audio_player_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  String? playerId;
  Future<void> emit(String event, [Object? value]) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage('xyz.luan/audioplayers/events/$playerId',
      const StandardMethodCodec().encodeSuccessEnvelope({'event': event, 'value': value}), (_) => done.complete());
    await done.future;
  }
  final first = AudioTrackInfo(title: 'دعاء الصباح', subtitle: 'أحمد الفتلاوي', url: 'https://example.com/morning.mp3', category: 'دعاء');
  final second = AudioTrackInfo(title: 'دعاء الافتتاح', subtitle: 'أحمد الفتلاوي', url: 'https://example.com/opening.mp3', category: 'دعاء');

  setUpAll(() {
    for (final name in ['xyz.luan/audioplayers.global', 'xyz.luan/audioplayers.global/events']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async {
      calls.add(call);
      if (call.method == 'create') {
        playerId = call.arguments['playerId'];
        messenger.setMockMethodCallHandler(MethodChannel('xyz.luan/audioplayers/events/$playerId'), (_) async => null);
      }
      if (call.method == 'setSourceUrl') {
        await emit('audio.onPrepared', true);
        await emit('audio.onDuration', 180000);
      }
      if (call.method == 'getDuration') return 180000;
      if (call.method == 'getCurrentPosition') return 0;
      if (call.method == 'seek') await emit('audio.onSeekComplete');
      return null;
    });
  });

  tearDown(() async { await AudioPlayerManager().stop(); });

  test('worship playback clears stale Quran metadata and next/previous use its playlist', () async {
    final manager = AudioPlayerManager();
    await manager.playSurah(surahId: 3, reciter: ReciterItem.popularReciters.first);
    expect(manager.currentSurahId, 3);
    // Direct playback is still used by other worship screens.
    await AudioPlayerService().playTrack(first);
    expect(manager.currentSurahId, isNull);
    expect(manager.currentSurahName, isNull);
    expect(manager.currentTrack?.title, 'دعاء الصباح');
    await manager.stop();
    await manager.playPlaylist([first, second], 0);
    expect(manager.canGoNext, true);
    await manager.nextTrack();
    expect(manager.currentTrack?.url, second.url);
    await manager.previousTrack();
    expect(manager.currentTrack?.url, first.url);
  });

  test('system media controls update the same player and metadata duration', () async {
    final handler = MediaAudioHandler();
    addTearDown(handler.detach);
    final manager = AudioPlayerManager();
    await manager.playPlaylist([first, second], 0);
    expect(handler.mediaItem.value?.title, first.title);
    expect(handler.mediaItem.value?.duration, const Duration(minutes: 3));
    expect(handler.playbackState.value.playing, true);
    await handler.pause();
    expect(manager.isPlaying, false);
    await handler.play();
    expect(manager.isPlaying, true);
    await handler.seek(const Duration(seconds: 25));
    expect(manager.position, const Duration(seconds: 25));
    await handler.skipToNext();
    expect(manager.currentTrack?.url, second.url);
    expect(handler.mediaItem.value?.title, second.title);
    await handler.stop();
    expect(manager.currentTrack, isNull);
    expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
  });

  test('repeat applies to worship audio and stop clears sleep timer', () async {
    final manager = AudioPlayerManager();
    await manager.playPlaylist([first, second], 0);
    manager.toggleLoop();
    calls.clear();
    await emit('audio.onComplete');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls.where((c) => c.method == 'setSourceUrl'), isNotEmpty);
    expect(manager.currentTrack?.url, first.url);
    manager.toggleLoop();
    manager.setSleepTimer(15);
    await manager.stop();
    expect(manager.sleepTimerMinutes, isNull);
  });

  test('playlist advances to next track on completion and stops after last track', () async {
    final manager = AudioPlayerManager();
    await manager.playPlaylist([first, second], 0);
    await emit('audio.onComplete');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(manager.currentTrack?.url, second.url);
    await emit('audio.onComplete');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(manager.currentTrack, isNull);
  });

  test('switching reciter style for same surah switches playback to the new style', () async {
    final manager = AudioPlayerManager();
    final reciter = ReciterItem.popularReciters[1];
    final hafs = ReciterStyle(id: 1, name: 'حفص عن عاصم - مرتل', server: 'https://server10.mp3quran.net/minsh/', surahList: '1,2');
    final mujawad = ReciterStyle(id: 2, name: 'المصحف المجود', server: 'https://server10.mp3quran.net/minsh_mjwd/', surahList: '1,2');

    await manager.playSurah(surahId: 1, reciter: reciter, style: hafs);
    expect(manager.currentStyle?.id, 1);
    expect(manager.currentTrack?.url, '${hafs.server}001.mp3');
    expect(manager.currentTrack?.subtitle, contains('حفص عن عاصم'));

    await manager.playSurah(surahId: 1, reciter: reciter, style: mujawad);
    expect(manager.currentStyle?.id, 2);
    expect(manager.currentTrack?.url, '${mujawad.server}001.mp3');
    expect(manager.currentTrack?.subtitle, contains('المجود'));
  });

  test('download service isolates surah state per reciter style', () {
    final downloads = QuranAudioDownloadService();
    expect(downloads.isSurahDownloaded(112, 1, styleId: 1), false);
    expect(downloads.isSurahDownloaded(112, 1, styleId: 2), false);
    expect(downloads.getCachedDownloadedCount(112, styleId: 1), 0);
    expect(downloads.getCachedDownloadedCount(112, styleId: 2), 0);
  });

  testWidgets('one shared card opens the worship sheet above an accessible navigation bar', (tester) async {
    await tester.runAsync(() => AudioPlayerManager().playPlaylist([first, second], 0));
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: const Text('محتوى التبويب'),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniAudioPlayer(),
        TextButton(onPressed: () {}, child: const Text('الإعدادات')),
      ]),
    )));
    expect(find.byType(MiniAudioPlayer), findsOneWidget);
    expect(find.text(first.title), findsOneWidget);
    expect(find.text('الإعدادات').hitTestable(), findsOneWidget);
    await tester.tap(find.text(first.title));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FullAudioPlayerSheet), findsOneWidget);
    expect(find.text('مشغل الصوتيات'), findsOneWidget);
    expect(find.text('مشغل القرآن'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => AudioPlayerManager().stop());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('full controls fit a small screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => AudioPlayerManager().playPlaylist([first, second], 0));
    await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)), child: child!),
      home: const Scaffold(body: FullAudioPlayerSheet())));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => AudioPlayerManager().stop());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
