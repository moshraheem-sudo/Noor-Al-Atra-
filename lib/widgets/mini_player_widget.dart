import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../screens/worship_audios_screen.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AudioPlayerService(),
      builder: (context, _) {
        final service = AudioPlayerService();
        final track = service.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // إذا كان مسار دعاء/مناجاة/زيارات أو صوتيات، افتح نافذة الصوتيات مباشرة
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WorshipAudiosScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D281E) : const Color(0xFFE8F5E9),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFF1B5E20).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          service.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: const Color(0xFF10B981),
                          size: 34,
                        ),
                        onPressed: () => service.togglePlayPause(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => service.stop(),
                      ),
                    ],
                  ),
                  if (service.duration.inSeconds > 0) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (service.position.inMilliseconds / service.duration.inMilliseconds)
                          .clamp(0.0, 1.0),
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      minHeight: 2.5,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
