import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/foundation.dart';
import 'audio_player_manager.dart';
import 'audio_player_service.dart';

AudioHandler? _mediaHandler;

Future<void> initializeMediaAudio() async {
  if (_mediaHandler != null || !(Platform.isAndroid || Platform.isIOS)) return;
  try {
    _mediaHandler = await AudioService.init(
      builder: () => MediaAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'noor_media_playback',
        androidNotificationChannelName: 'مشغل صوتيات نور العترة',
        androidNotificationIcon: 'drawable/ic_notification',
        androidStopForegroundOnPause: false,
      ),
    );
  } catch (e) {
    debugPrint('Unable to initialize media controls: $e');
  }
}

/// OS controls and in-app controls share the same player and playback state.
class MediaAudioHandler extends BaseAudioHandler {
  MediaAudioHandler() {
    _manager.addListener(_publishState);
    _publishState();
  }

  final AudioPlayerManager _manager = AudioPlayerManager();
  final AudioPlayerService _service = AudioPlayerService();

  void _publishState() {
    final track = _manager.currentTrack;
    if (track == null) {
      mediaItem.add(null);
      playbackState
          .add(PlaybackState(processingState: AudioProcessingState.idle));
      return;
    }
    final item = MediaItem(
      id: track.url,
      title: track.title,
      artist: track.subtitle,
      album: track.category ?? 'نور العترة',
      duration: _manager.duration,
    );
    final previous = mediaItem.value;
    if (previous?.id != item.id || previous?.title != item.title ||
        previous?.artist != item.artist || previous?.duration != item.duration) {
      mediaItem.add(item);
    }
    final controls = <MediaControl>[
      if (_manager.canGoPrevious) MediaControl.skipToPrevious,
      _manager.isPlaying ? MediaControl.pause : MediaControl.play,
      MediaControl.stop,
      if (_manager.canGoNext) MediaControl.skipToNext,
    ];
    final processing = _service.isLoading
        ? AudioProcessingState.loading
        : _service.playerState == PlayerState.completed
            ? AudioProcessingState.completed
            : AudioProcessingState.ready;
    final old = playbackState.value;
    // The OS extrapolates position; publish on state/seek changes, not every tick.
    final elapsed = DateTime.now().difference(old.updateTime);
    final expected =
        old.updatePosition + (old.playing ? elapsed : Duration.zero);
    if (old.playing == _manager.isPlaying &&
        old.processingState == processing &&
        listEquals(old.controls, controls) &&
        (_manager.position - expected).inMilliseconds.abs() < 1000 &&
        old.repeatMode ==
            (_manager.isLooping
                ? AudioServiceRepeatMode.one
                : AudioServiceRepeatMode.none)) {
      return;
    }
    playbackState.add(PlaybackState(
      controls: controls,
      androidCompactActionIndices: [
        controls.indexWhere((c) =>
            c.action == MediaAction.play || c.action == MediaAction.pause),
        controls.indexOf(MediaControl.stop)
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward
      },
      processingState: processing,
      playing: _manager.isPlaying,
      updatePosition: _manager.position,
      repeatMode: _manager.isLooping
          ? AudioServiceRepeatMode.one
          : AudioServiceRepeatMode.none,
    ));
  }

  @override
  Future<void> play() => _manager.resume();
  @override
  Future<void> pause() => _manager.pause();
  @override
  Future<void> stop() async {
    await _manager.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _manager.seek(position);
  @override
  Future<void> fastForward() => _manager.forward10();
  @override
  Future<void> rewind() => _manager.replay10();
  @override
  Future<void> skipToNext() => _manager.nextTrack();
  @override
  Future<void> skipToPrevious() => _manager.previousTrack();
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (_manager.isLooping != (repeatMode == AudioServiceRepeatMode.one)) {
      _manager.toggleLoop();
    }
  }

  @override
  Future<void> onNotificationDeleted() => stop();

  void detach() => _manager.removeListener(_publishState);
}
