import 'package:flutter/material.dart';
import '../services/audio_player_manager.dart';

class FullAudioPlayerSheet extends StatefulWidget {
  const FullAudioPlayerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FullAudioPlayerSheet(),
    );
  }

  @override
  State<FullAudioPlayerSheet> createState() => _FullAudioPlayerSheetState();
}

class _FullAudioPlayerSheetState extends State<FullAudioPlayerSheet> {
  double? _dragValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final player = AudioPlayerManager();

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final position = player.position;
        final duration = player.duration;
        final isPlaying = player.isPlaying;
        final isQuran = player.currentTrack?.category == 'quran_surah' || player.currentSurahId != null;
        final trackTitle = player.currentSurahName ?? player.currentTrack?.title ?? 'القرآن الكريم';
        final reciterName = player.currentReciter?.name ?? player.currentTrack?.subtitle ?? 'القارئ';

        final maxDuration = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
        final currentPos = (_dragValue ?? position.inMilliseconds.toDouble()).clamp(0.0, maxDuration);

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Top Drag Handle & Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      isQuran ? 'مشغل القرآن' : 'مشغل الصوتيات',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1B3A57),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                      color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Album Art Card matching Image 3
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E3A5F), const Color(0xFF2A2E45)]
                        : [const Color(0xFFE0F2FE), const Color(0xFFFCE7F3)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isQuran ? Icons.menu_book_rounded : Icons.mic_rounded,
                      size: 48,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isQuran ? 'القرآن الكريم' : (player.currentTrack?.category ?? 'صوتيات نور العترة'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1B3A57),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Surah / Audio Title & Reciter Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  trackTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B3A57),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                reciterName,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                ),
              ),

              const SizedBox(height: 28),

              // Progress Bar & Durations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57),
                        inactiveTrackColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F1F6),
                        thumbColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57),
                        overlayColor: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57)).withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: currentPos,
                        max: maxDuration,
                        onChanged: (val) {
                          setState(() => _dragValue = val);
                        },
                        onChangeEnd: (val) {
                          player.seek(Duration(milliseconds: val.toInt()));
                          setState(() => _dragValue = null);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 7 Media Controls matching Image 3 exactly
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. Sleep Timer
                    IconButton(
                      icon: Icon(
                        Icons.timer_outlined,
                        color: player.sleepTimerMinutes != null
                            ? const Color(0xFF0284C7)
                            : (isDark ? Colors.white70 : const Color(0xFF1B3A57)),
                        size: 22,
                      ),
                      tooltip: 'مؤقت النوم',
                      onPressed: () => _showSleepTimerDialog(context, player, isDark),
                    ),

                    // 2. Skip Previous Surah
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                        size: 26,
                      ),
                      tooltip: 'السورة السابقة',
                      onPressed: () => player.playPreviousSurah(),
                    ),

                    // 3. Replay 10s
                    IconButton(
                      icon: Icon(
                        Icons.replay_10_rounded,
                        color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                        size: 26,
                      ),
                      tooltip: 'إرجاع 10 ثوانٍ',
                      onPressed: () => player.replay10(),
                    ),

                    // 4. Big Main Play / Pause Circle Button
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57)).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          size: 36,
                        ),
                        onPressed: () => player.togglePlayPause(),
                      ),
                    ),

                    // 5. Forward 10s
                    IconButton(
                      icon: Icon(
                        Icons.forward_10_rounded,
                        color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                        size: 26,
                      ),
                      tooltip: 'تقديم 10 ثوانٍ',
                      onPressed: () => player.forward10(),
                    ),

                    // 6. Skip Next Surah
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                        size: 26,
                      ),
                      tooltip: 'السورة التالية',
                      onPressed: () => player.playNextSurah(),
                    ),

                    // 7. Repeat / Loop
                    IconButton(
                      icon: Icon(
                        Icons.repeat_rounded,
                        color: player.isLooping
                            ? const Color(0xFF0284C7)
                            : (isDark ? Colors.white70 : const Color(0xFF1B3A57)),
                        size: 24,
                      ),
                      tooltip: 'تكرار التلاوة',
                      onPressed: () => player.toggleLoop(),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context, AudioPlayerManager player, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'مؤقت النوم',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1B3A57),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mins in [15, 30, 45, 60])
                ListTile(
                  title: Text('$mins دقيقة', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: player.sleepTimerMinutes == mins
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1B3A57))
                      : null,
                  onTap: () {
                    player.setSleepTimer(mins);
                    Navigator.pop(ctx);
                  },
                ),
              if (player.sleepTimerMinutes != null)
                ListTile(
                  title: const Text('إيقاف المؤقت', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onTap: () {
                    player.cancelSleepTimer();
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
