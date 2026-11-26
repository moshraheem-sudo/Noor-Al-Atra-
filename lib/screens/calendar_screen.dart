import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/hijri_date_service.dart';
import '../services/settings_controller.dart';
import '../models/hijri_event.dart';
import 'qibla_compass_screen.dart';
import 'worship_screen.dart';
import 'worship_category_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _currentHijriYear;
  late int _currentHijriMonth;
  int? _selectedDay;

  // Real today Hijri info
  late int _todayYear;
  late int _todayMonth;
  late int _todayDay;

  @override
  void initState() {
    super.initState();
    HijriDateService.dateNotifier.addListener(_onHijriDateUpdated);
    _refreshCurrentHijriDate();
  }

  void _onHijriDateUpdated() {
    if (mounted) {
      _refreshCurrentHijriDate();
    }
  }

  void _refreshCurrentHijriDate() {
    final today = HijriDateService.getHijriDate();
    setState(() {
      _todayYear = today['year'] as int? ?? 1448;
      _todayMonth = today['month'] as int? ?? 4;
      _todayDay = today['day'] as int? ?? 15;

      _currentHijriYear = _todayYear;
      _currentHijriMonth = _todayMonth;
      _selectedDay = _todayDay;
    });
  }

  @override
  void dispose() {
    HijriDateService.dateNotifier.removeListener(_onHijriDateUpdated);
    super.dispose();
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_currentHijriMonth == 1) {
        _currentHijriMonth = 12;
        _currentHijriYear--;
      } else {
        _currentHijriMonth--;
      }
      if (_currentHijriYear == _todayYear && _currentHijriMonth == _todayMonth) {
        _selectedDay = _todayDay;
      } else {
        _selectedDay = 1;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_currentHijriMonth == 12) {
        _currentHijriMonth = 1;
        _currentHijriYear++;
      } else {
        _currentHijriMonth++;
      }
      if (_currentHijriYear == _todayYear && _currentHijriMonth == _todayMonth) {
        _selectedDay = _todayDay;
      } else {
        _selectedDay = 1;
      }
    });
  }

  void _resetToToday() {
    setState(() {
      _currentHijriYear = _todayYear;
      _currentHijriMonth = _todayMonth;
      _selectedDay = _todayDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings.themePalette == AppThemePalette.royalDark;
    final isDark = isEmerald || isRoyalDark;
    final bool canPop = Navigator.canPop(context);

    // Events for current viewed month
    final allEvents = DataService().events;
    final monthEvents = allEvents
        .where((e) => e.month == _currentHijriMonth)
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    // First Gregorian date of current Hijri month
    final gStart = HijriDateService.hijriToGregorian(_currentHijriYear, _currentHijriMonth, 1);
    final totalDays = HijriDateService.getDaysInHijriMonth(_currentHijriYear, _currentHijriMonth);
    // Sunday is column 0 in Arabic week (7 % 7 = 0)
    final startColumn = gStart.weekday % 7;

    final monthName = HijriDateService.monthsHijriAr[_currentHijriMonth - 1];
    final yearFormatted = HijriDateService.toArabicDigits(_currentHijriYear);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isEmerald
                ? [const Color(0xFF04140D), const Color(0xFF071C13), const Color(0xFF030E09)]
                : (isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF090D16)]
                    : [const Color(0xFFEBF7FD), const Color(0xFFE2F3F9), const Color(0xFFDCF0F9)]),
          ),
        ),
        child: Stack(
          children: [
            // Islamic geometric watermark pattern in upper screen background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 380,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CalendarGeometricWatermarkPainter(
                    lineColor: isDark
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFF0284C7).withOpacity(0.08),
                    goldColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFD4AF37).withOpacity(0.06),
                  ),
                ),
              ),
            ),
            Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: canPop ? 0 : 14,
        leading: canPop
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: 'رجوع',
              )
            : null,
        title: Row(
                  children: [
                    // App Logo Circle with golden border
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.25,
                          child: Image.asset(
                            'assets/images/icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/ic_app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.mosque, color: Color(0xFFE5C882), size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'نور العترة',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Qibla button with compass
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QiblaCompassScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0C4A6E).withOpacity(0.35) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF0284C7).withOpacity(0.5) : const Color(0xFFBAE6FD),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.explore_outlined, size: 16, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text(
                            'القبلة',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search button
                  IconButton(
                    icon: const Icon(Icons.search, size: 23),
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorshipScreen()),
                      );
                    },
                  ),

                  // Favorites button
                  IconButton(
                    icon: const Icon(Icons.favorite, size: 23),
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    constraints: const BoxConstraints(),
                    tooltip: 'المفضلة',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorshipCategoryDetailScreen(
                            title: 'المفضلة',
                            categoryKey: 'favorites',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: RefreshIndicator(
                color: const Color(0xFF0284C7),
                onRefresh: () async {
                  await HijriDateService.syncHijriFromRepository(force: true);
                  _refreshCurrentHijriDate();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 20),
                  children: [
                  // Page Title: "التقويم"
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 12),
                      child: Text(
                        'التقويم',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),

                  // 1. Calendar Card
                  _buildCalendarCard(
                    context: context,
                    isDark: isDark,
                    monthName: monthName,
                    yearFormatted: yearFormatted,
                    startColumn: startColumn,
                    totalDays: totalDays,
                    gStart: gStart,
                    monthEvents: monthEvents,
                  ),

                  const SizedBox(height: 24),

                  // 2. Events Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'أحداث هذا الشهر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                      ),
                      if (_currentHijriMonth != _todayMonth || _currentHijriYear != _todayYear)
                        InkWell(
                          onTap: _resetToToday,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'العودة لليوم',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 3. Events List for this month
                  if (monthEvents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'لا توجد مناسبات مسجلة في شهر $monthName',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  else
                    ...monthEvents.map((ev) {
                      final isSelectedDayEvent = (_selectedDay == ev.day);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelectedDayEvent
                                ? (isDark
                                    ? const Color(0xFF1E3A5F).withOpacity(0.4)
                                    : const Color(0xFFE0F2FE).withOpacity(0.7))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Indicator Dot (Green for joyful/birth, Red for martyrdom/sadness)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  width: 8.5,
                                  height: 8.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ev.isMartyrdom
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF22C55E),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (ev.isMartyrdom ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Event Title Text
                              Expanded(
                                child: Text(
                                  '${HijriDateService.toArabicDigits(ev.day)} $monthName - ${ev.name}',
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelectedDayEvent ? FontWeight.w800 : FontWeight.w600,
                                    height: 1.45,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  /// Builds the white calendar card matching the attached design
  Widget _buildCalendarCard({
    required BuildContext context,
    required bool isDark,
    required String monthName,
    required String yearFormatted,
    required int startColumn,
    required int totalDays,
    required DateTime gStart,
    required List<HijriEvent> monthEvents,
  }) {
    // Weekday abbreviations: Sunday (ح) to Saturday (س)
    const weekHeaders = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

    final totalCells = startColumn + totalDays;
    final rowCount = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation header: < ربيع الآخر ١٤٤٨ > + Sync button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Right arrow in RTL: > (moves forward in month)
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
                splashRadius: 20,
                onPressed: _goToNextMonth,
              ),

              // Month & Year title + manual sync button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$monthName $yearFormatted',
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.sync_rounded, size: 20),
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    tooltip: 'تحديث التقويم الهجري من المستودع',
                    splashRadius: 18,
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('جارٍ التحقق من التقويم الهجري وتحديثه...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      await HijriDateService.syncHijriFromRepository(force: true);
                      _refreshCurrentHijriDate();
                    },
                  ),
                ],
              ),

              // Left arrow in RTL: < (moves backward in month)
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
                splashRadius: 20,
                onPressed: _goToPreviousMonth,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Weekdays Row: ح  ن  ث  ر  خ  ج  س
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: weekHeaders.map((header) {
                return Expanded(
                  child: Center(
                    child: Text(
                      header,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Days Grid
          for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (int colIndex = 0; colIndex < 7; colIndex++)
                    Expanded(
                      child: _buildDayCell(
                        cellIndex: rowIndex * 7 + colIndex,
                        startColumn: startColumn,
                        totalDays: totalDays,
                        gStart: gStart,
                        monthEvents: monthEvents,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds an individual day cell in the calendar grid
  Widget _buildDayCell({
    required int cellIndex,
    required int startColumn,
    required int totalDays,
    required DateTime gStart,
    required List<HijriEvent> monthEvents,
    required bool isDark,
  }) {
    final dayNum = cellIndex - startColumn + 1;

    // Empty cell before day 1 or after total days
    if (dayNum < 1 || dayNum > totalDays) {
      return const SizedBox(height: 48);
    }

    final gDate = gStart.add(Duration(days: dayNum - 1));
    final isSelected = (_selectedDay == dayNum);
    final isToday = (_currentHijriYear == _todayYear &&
        _currentHijriMonth == _todayMonth &&
        dayNum == _todayDay);

    final dayEvents = monthEvents.where((e) => e.day == dayNum).toList();
    final hasMartyrdom = dayEvents.any((e) => e.isMartyrdom);
    final hasCelebration = dayEvents.any((e) => !e.isMartyrdom);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDay = dayNum;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular container for date numbers
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF1E3A8A) // Dark navy circle matching screenshot!
                    : (isToday
                        ? (isDark ? const Color(0xFF0C4A6E).withOpacity(0.4) : const Color(0xFFE0F2FE))
                        : Colors.transparent),
                border: (!isSelected && isToday)
                    ? Border.all(color: const Color(0xFF0284C7), width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Hijri Day Number (prominent)
                  Text(
                    HijriDateService.toArabicDigits(dayNum),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? const Color(0xFF0284C7)
                              : (isDark ? Colors.white : const Color(0xFF1E293B))),
                    ),
                  ),

                  // 2. Gregorian Day Number (small inside the cell, as requested)
                  Text(
                    '${gDate.day}',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      color: isSelected
                          ? Colors.white.withOpacity(0.75)
                          : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),

            // Event indicator dot(s) below the cell
            const SizedBox(height: 2),
            if (dayEvents.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasMartyrdom)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEF4444), // Red for martyrdom
                      ),
                    ),
                  if (hasCelebration)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22C55E), // Green for joyful/birth
                      ),
                    ),
                ],
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for authentic subtle Islamic Geometry lines in the background
class _CalendarGeometricWatermarkPainter extends CustomPainter {
  final Color lineColor;
  final Color goldColor;

  _CalendarGeometricWatermarkPainter({required this.lineColor, required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final goldPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, 90);

    // Radii of concentric geometry
    final radii = [55.0, 95.0, 140.0, 190.0, 240.0];

    for (final r in radii) {
      canvas.drawCircle(center, r, linePaint);
    }

    // 16 radiating lines
    for (int i = 0; i < 16; i++) {
      final angle = i * pi / 8;
      final p1 = Offset(center.dx + 40 * cos(angle), center.dy + 40 * sin(angle));
      final p2 = Offset(center.dx + 260 * cos(angle), center.dy + 260 * sin(angle));
      canvas.drawLine(p1, p2, (i % 2 == 0) ? goldPaint : linePaint);
    }

    // 8-pointed and 16-pointed star polygons
    _drawStar(canvas, center, 8, 95, 60, goldPaint);
    _drawStar(canvas, center, 8, 140, 88, linePaint);
    _drawStar(canvas, center, 16, 190, 150, linePaint);
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerRadius, double innerRadius, Paint paint) {
    final path = Path();
    final double step = pi / points;
    for (int i = 0; i < 2 * points; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final angle = i * step;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CalendarGeometricWatermarkPainter oldDelegate) => false;
}
