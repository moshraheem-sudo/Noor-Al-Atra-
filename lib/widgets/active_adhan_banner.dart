import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/adhan_scheduler_service.dart';

/// Persistent playback controls shared by all main tabs whenever Adhan is playing,
/// allowing the user to immediately and effortlessly stop the Adhan sound in 1 tap.
class ActiveAdhanBanner extends StatefulWidget {
  final bool isDark;
  const ActiveAdhanBanner({super.key, required this.isDark});

  @override
  State<ActiveAdhanBanner> createState() => _ActiveAdhanBannerState();
}

class _ActiveAdhanBannerState extends State<ActiveAdhanBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdhanSchedulerService().isPlayingAdhanNotifier,
      builder: (context, isPlaying, _) {
        if (!isPlaying) return const SizedBox.shrink();

        return ValueListenableBuilder<String?>(
          valueListenable: AdhanSchedulerService().currentAdhanPrayerNotifier,
          builder: (context, prayerName, _) {
            final displayName = (prayerName != null && prayerName.isNotEmpty)
                ? prayerName
                : 'الصلاة';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF064E3B),
                    Color(0xFF0F766E),
                    Color(0xFF042F2E),
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated pulsing speaker / mosque icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        border: Border.all(
                            color: const Color(0xFFF59E0B), width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: Color(0xFFFDE68A),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & status text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'أذان $displayName المبارك 🕌',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              AdhanSchedulerService().isVolumeLoweredNotifier,
                          builder: (context, isLow, _) {
                            return Text(
                              isLow
                                  ? 'صوت الأذان مخفّض الآن 🔉 • مستمر بهدوء'
                                  : 'صوت الأذان مرفوع الآن • حيّ على الصلاة',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isLow
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFD1FAE5),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Volume Reduction / Restoration Button
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        AdhanSchedulerService().isVolumeLoweredNotifier,
                    builder: (context, isLow, _) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            AdhanSchedulerService().toggleAdhanVolume();
                            final sm = ScaffoldMessenger.of(context);
                            sm.hideCurrentSnackBar();
                            sm.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      isLow
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_down_rounded,
                                      color: Colors.amberAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isLow
                                            ? 'تمت إعادة رفع صوت الأذان 🔊'
                                            : 'تم خفض صوت الأذان 🔉 (الأذان مستمر بهدوء)',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF0F172A),
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(11),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLow
                                    ? const [
                                        Color(0xFF059669),
                                        Color(0xFF047857)
                                      ]
                                    : const [
                                        Color(0xFF0284C7),
                                        Color(0xFF0369A1)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: (isLow
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF0284C7))
                                      .withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLow
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_down_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isLow ? 'رفع الصوت' : 'خفض الصوت',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  // STOP button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        AdhanSchedulerService().stopAdhan();
                        final sm = ScaffoldMessenger.of(context);
                        sm.hideCurrentSnackBar();
                        sm.showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.stop_circle_rounded,
                                    color: Colors.amberAccent, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'تم إيقاف صوت الأذان ⏹',
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF0F172A),
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626)
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stop_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 3),
                            Text(
                              'إيقاف',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
