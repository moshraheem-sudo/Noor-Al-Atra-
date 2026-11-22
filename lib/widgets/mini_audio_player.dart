import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_manager.dart';
import '../services/settings_controller.dart';
import 'full_audio_player_sheet.dart';

class MiniAudioPlayer extends StatelessWidget {
  final double? bottomPadding;
  final bool autoBottomInset;

  const MiniAudioPlayer({
    super.key,
    this.bottomPadding,
    this.autoBottomInset = false,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    SettingsController? settings;
    try {
      settings = context.watch<SettingsController>();
    } catch (_) {}

    final isEmerald = settings?.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings?.themePalette == AppThemePalette.royalDark;
    final isDark = isEmerald || isRoyalDark || Theme.of(context).brightness == Brightness.dark;
    final player = AudioPlayerManager();

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final track = player.currentTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        // Only display in Quran context if this is a Quran track
        final isQuranTrack = track.category == 'quran_surah' ||
            track.category == 'quran_verse' ||
            player.currentSurahId != null;
        if (!isQuranTrack) {
          return const SizedBox.shrink();
        }

        final isPlaying = player.isPlaying;
        final surahTitle = track.title.isNotEmpty ? track.title : (player.currentSurahName ?? 'القرآن الكريم');
        final reciterSubtitle = track.subtitle.isNotEmpty ? track.subtitle : (player.currentReciter?.name ?? 'القارئ');
        final position = player.position;
        final duration = player.duration;

        final bottomInset = MediaQuery.of(context).padding.bottom;
        final effectiveBottom = bottomPadding ??
            (autoBottomInset
                ? (bottomInset > 0 ? bottomInset : 14.0) + 12.0
                : 4.0);

        Color cardBg;
        Color cardBorder;
        Color artworkBg;
        Color progressColor;

        if (isEmerald) {
          cardBg = const Color(0xFF082216);
          cardBorder = const Color(0xFF14452F);
          artworkBg = const Color(0xFF04140D);
          progressColor = const Color(0xFF10B981);
        } else if (isDark) {
          cardBg = const Color(0xFF1E2433);
          cardBorder = const Color(0xFF334155);
          artworkBg = const Color(0xFF1E3A5F);
          progressColor = const Color(0xFF38BDF8);
        } else {
          cardBg = const Color(0xFFF3F2FD);
          cardBorder = const Color(0xFFE2E0FA);
          artworkBg = const Color(0xFF1B3A57);
          progressColor = const Color(0xFF0284C7);
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 4,
            bottom: effectiveBottom,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => FullAudioPlayerSheet.show(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // 1. Right Square Artwork with Headphones Icon (Child 0 in RTL)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: artworkBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.headphones_rounded,
                              color: Color(0xFFD4AF37),
                              size: 24,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 2. Surah Title & Reciter Name
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surahTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reciterSubtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // 3. Counter (e.g. 01:44)
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // 4. Play / Pause button
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: isDark ? Colors.white : const Color(0xFF1B3A57),
                            size: 26,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => player.togglePlayPause(),
                        ),

                        // 5. Close button
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => player.stop(),
                        ),
                      ],
                    ),
                    if (duration.inMilliseconds > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0),
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 2.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
