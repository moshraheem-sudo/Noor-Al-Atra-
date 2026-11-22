import 'dart:async';
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/hijri_date_service.dart';
import '../models/hijri_event.dart';
import '../main.dart';

class AutoScrollingEventsBanner extends StatefulWidget {
  const AutoScrollingEventsBanner({super.key});

  @override
  State<AutoScrollingEventsBanner> createState() => _AutoScrollingEventsBannerState();
}

class _AutoScrollingEventsBannerState extends State<AutoScrollingEventsBanner> {
  Timer? _timer;
  int _currentIndex = 0;
  List<_UpcomingEventDisplay> _events = [];

  @override
  void initState() {
    super.initState();
    _events = _calculateUpcomingEvents();
    _startAutoRotation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRotation() {
    _timer?.cancel();
    if (_events.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _events.length;
      });
    });
  }

  List<_UpcomingEventDisplay> _calculateUpcomingEvents() {
    final rawEvents = DataService().events;
    final hijriNow = HijriDateService.getHijriDate();
    final curDay = (hijriNow['day'] as int?) ?? 14;
    final curMonth = (hijriNow['month'] as int?) ?? 4;
    final now = DateTime.now();

    const monthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];

    int curDayOfYear = 0;
    for (int i = 0; i < curMonth - 1 && i < 12; i++) {
      curDayOfYear += monthLengths[i];
    }
    curDayOfYear += curDay;

    final list = <_UpcomingEventDisplay>[];

    for (final ev in rawEvents) {
      int evDayOfYear = 0;
      for (int i = 0; i < ev.month - 1 && i < 12; i++) {
        evDayOfYear += monthLengths[i];
      }
      evDayOfYear += ev.day;

      int daysRemaining;
      if (evDayOfYear >= curDayOfYear) {
        daysRemaining = evDayOfYear - curDayOfYear;
      } else {
        daysRemaining = (354 - curDayOfYear) + evDayOfYear;
      }

      final targetDate = now.add(Duration(days: daysRemaining));
      final gMonthName = HijriDateService.monthsGregorianAr[targetDate.month - 1];
      final gDateStr = '${targetDate.day} $gMonthName ${targetDate.year}';
      final hDateStr = '${ev.day} ${HijriEvent.getMonthName(ev.month)}';
      final remText = daysRemaining == 0 ? 'متبقي 0 يوم (اليوم)' : 'متبقي $daysRemaining يوم';

      list.add(
        _UpcomingEventDisplay(
          title: ev.name,
          hijriDate: hDateStr,
          gregorianDate: '$gDateStr م',
          remainingText: remText,
          daysRemaining: daysRemaining,
          isMartyrdom: ev.isMartyrdom,
        ),
      );
    }

    if (list.isEmpty) {
      list.add(
        _UpcomingEventDisplay(
          title: 'ولادة السيدة زينب الكبرى (عليها السلام)',
          hijriDate: '5 جمادى الأولى',
          gregorianDate: '16 أكتوبر 2026 م',
          remainingText: 'متبقي 21 يوم',
          daysRemaining: 21,
          isMartyrdom: false,
        ),
      );
    }

    // Sort by nearest upcoming days
    list.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_events.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = _events[_currentIndex % _events.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162534) : const Color(0xFFEFF6FC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? const Color(0xFF0284C7).withValues(alpha: 0.35)
                : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              MainNavigationScreen.switchTab(context, 1);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header: «الأحداث»
                  Text(
                    '«الأحداث»',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 2. Rotating Event Details
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentIndex),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Event Title
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),

                          // Bottom line: [التاريخ الهجري] | [التاريخ الميلادي] م | متبقي [X] يوم
                          Text(
                            '${item.hijriDate} • ${item.gregorianDate} • ${item.remainingText}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventDisplay {
  final String title;
  final String hijriDate;
  final String gregorianDate;
  final String remainingText;
  final int daysRemaining;
  final bool isMartyrdom;

  _UpcomingEventDisplay({
    required this.title,
    required this.hijriDate,
    required this.gregorianDate,
    required this.remainingText,
    required this.daysRemaining,
    required this.isMartyrdom,
  });
}
