import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../screens/prayer_times_screen.dart';
import '../services/hijri_date_service.dart';

class CollapsibleHomePrayerCard extends StatefulWidget {
  final VoidCallback onOpenPrayerTimes;

  const CollapsibleHomePrayerCard({super.key, required this.onOpenPrayerTimes});

  @override
  State<CollapsibleHomePrayerCard> createState() => _CollapsibleHomePrayerCardState();
}

class _CollapsibleHomePrayerCardState extends State<CollapsibleHomePrayerCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final times = prayer.prayerTimes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rawNextTime = times != null ? _getNextPrayerTime(prayer, times) : '11:57';
    final parsedTime = _split12HourTime(rawNextTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E88E5).withOpacity(0.35) : const Color(0xFFBFDBFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Row: "مواقيت الصلاة >" button on right, City selector on left (in RTL)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Right in RTL: "مواقيت الصلاة >" button
                    InkWell(
                      onTap: widget.onOpenPrayerTimes,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDDEBF7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2A5A84), size: 11),
                            const SizedBox(width: 5),
                            Text(
                              'مواقيت الصلاة',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2A5A84),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Left in RTL: City selector badge "📍 كربلاء المقدسة"
                    Flexible(
                      child: InkWell(
                        onTap: () => _showCityPicker(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F1FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFF90CAF9),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF), size: 15),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  prayer.selectedCity.nameAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Main Clickable Area to Expand/Collapse
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      children: [
                        // 2. Middle Row: Next Prayer & Big Bold Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Right in RTL: Dot + الصلاة القادمة + صلاة الظهر
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'الصلاة القادمة',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'صلاة ${prayer.nextPrayerName}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),

                            // Left in RTL: Big Time "11:57 ص"
                            Text.rich(
                              TextSpan(
                                text: parsedTime['time'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                children: [
                                  TextSpan(
                                    text: ' ${parsedTime['suffix']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 3. Bottom Row: "طي الصلوات ^" or "الصلوات الخمس v" on right, countdown badge on left
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Right in RTL: Expand/Collapse toggle
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'طي الصلوات' : 'الصلوات الخمس',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                                ),
                              ],
                            ),

                            // Left in RTL: Countdown badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF1F7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFD1DDE8),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'متبقي ${prayer.timeUntilNextPrayer}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 4. Horizontal Progress Line (dark blue on right in RTL)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    height: 3.5,
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.38,
                        child: Container(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Expanded 8 Prayers Grid (matching the exact 2-column layout in Image 1)
          if (_isExpanded && times != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),

                  // Header of expanded section: "13 ربيع الآخر 1448 هـ" on right, "مواقيت اليوم: [اسم المدينة]" on left
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        HijriDateService.getHijriDate()['shortFormatted'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'مواقيت اليوم • ${prayer.selectedCity.nameAr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 1: Right = صلاة الفجر, Left = الشروق
                  Row(
                    children: [
                      Expanded(
                        child: _prayerBox(
                          'صلاة الفجر',
                          times.fajr,
                          isCurrent: prayer.nextPrayerName == 'الفجر',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _prayerBox(
                          'الشروق',
                          times.sunrise,
                          isCurrent: prayer.nextPrayerName == 'الشروق',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Right = صلاة الظهر, Left = صلاة العصر
                  Row(
                    children: [
                      Expanded(
                        child: _prayerBox(
                          'صلاة الظهر',
                          times.dhuhr,
                          isCurrent: prayer.nextPrayerName == 'الظهر',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _prayerBox(
                          'صلاة العصر',
                          times.asr,
                          isCurrent: prayer.nextPrayerName == 'العصر',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Right = الغروب, Left = صلاة المغرب
                  Row(
                    children: [
                      Expanded(
                        child: _prayerBox(
                          'الغروب',
                          times.sunset,
                          isCurrent: false,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _prayerBox(
                          'صلاة المغرب',
                          times.maghrib,
                          isCurrent: prayer.nextPrayerName == 'المغرب',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 4: Right = صلاة العشاء, Left = منتصف الليل
                  Row(
                    children: [
                      Expanded(
                        child: _prayerBox(
                          'صلاة العشاء',
                          times.isha,
                          isCurrent: prayer.nextPrayerName == 'العشاء',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _prayerBox(
                          'منتصف الليل',
                          times.midnight,
                          isCurrent: false,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getNextPrayerTime(PrayerProvider prayer, dynamic times) {
    switch (prayer.nextPrayerName) {
      case 'الفجر':
        return times.fajr;
      case 'الشروق':
        return times.sunrise;
      case 'الظهر':
        return times.dhuhr;
      case 'العصر':
        return times.asr;
      case 'المغرب':
        return times.maghrib;
      case 'العشاء':
        return times.isha;
      default:
        return times.dhuhr;
    }
  }

  Map<String, String> _split12HourTime(String time24) {
    final parts = time24.split(':');
    if (parts.length >= 2) {
      int h = int.tryParse(parts[0].trim()) ?? 12;
      final m = parts[1].trim().padLeft(2, '0');
      final suffix = h >= 12 ? 'م' : 'ص';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      final hStr = h.toString().padLeft(2, '0');
      return {
        'time': '$hStr:$m',
        'suffix': suffix,
      };
    }
    return {
      'time': time24,
      'suffix': '',
    };
  }

  Widget _prayerBox(String name, String time, {required bool isCurrent, required bool isDark}) {
    final parsed = _split12HourTime(time);

    final bgColor = isCurrent
        ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDCEBF7))
        : (isDark ? const Color(0xFF0F172A) : Colors.transparent);

    final borderColor = isCurrent
        ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF7DB3E0))
        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0));

    final textColor = isCurrent
        ? (isDark ? Colors.white : const Color(0xFF1E3A8A))
        : (isDark ? Colors.white70 : const Color(0xFF334155));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isCurrent ? 1.4 : 1.0),
      ),
      child: Row(
        children: [
          // Right in RTL: Name (with indicator dot if active)
          if (isCurrent) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
          ],
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: textColor,
                fontSize: 10.5,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Left in RTL: Formatted Time (e.g. 04:32 ص)
          Text(
            '${parsed['time']} ${parsed['suffix']}',
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    PrayerTimesScreen.showCityPicker(context);
  }
}
