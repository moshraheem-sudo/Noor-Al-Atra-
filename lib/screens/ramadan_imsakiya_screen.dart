import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/city_location.dart';
import '../providers/prayer_provider.dart';
import '../services/data_service.dart';
import '../services/hijri_date_service.dart';
import '../services/kafeel_api_service.dart';
import '../services/settings_controller.dart';
import '../services/storage_service.dart';
import '../widgets/ramadan_poster_share_sheet.dart';

class RamadanDayData {
  final int dayNumber; // 1 to 30
  final String dayName; // الأحد، الإثنين...
  final DateTime gregorianDate;
  final String gregorianFormatted; // 18 شباط
  final String imsak; // 10 minutes before Fajr
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String sunset;
  final String maghrib;
  final String isha;
  final String midnight;
  final bool isToday;

  const RamadanDayData({
    required this.dayNumber,
    required this.dayName,
    required this.gregorianDate,
    required this.gregorianFormatted,
    required this.imsak,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.midnight,
    required this.isToday,
  });
}

class RamadanImsakiyaScreen extends StatefulWidget {
  final int? initialYear;

  const RamadanImsakiyaScreen({super.key, this.initialYear});

  @override
  State<RamadanImsakiyaScreen> createState() => _RamadanImsakiyaScreenState();
}

class _RamadanImsakiyaScreenState extends State<RamadanImsakiyaScreen> {
  late int _selectedHijriYear;
  late int _currentHijriYear;
  CityLocation? _selectedCity;
  List<RamadanDayData> _days = [];
  bool _isLoading = true;
  bool _isTableView = true; // true: جدول احترافي, false: بطاقات يومية

  @override
  void initState() {
    super.initState();
    final currentHijri = HijriDateService.getHijriDate();
    _currentHijriYear = (currentHijri['year'] as int?) ?? 1448;
    _selectedHijriYear = widget.initialYear ?? _currentHijriYear;

    // Load initial city from PrayerProvider or storage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prayerProv = context.read<PrayerProvider>();
      _selectedCity = prayerProv.selectedCity;
      _calculateImsakiya();
    });
  }

  void _calculateImsakiya() {
    setState(() => _isLoading = true);

    final city = _selectedCity ?? StorageService().getSavedCity() ?? CityLocation.defaultCity;
    final settings = SettingsController();

    // Determine timezone hours
    String tzParam = '+3';
    if (city.timezone.isNotEmpty) {
      String clean = city.timezone.trim();
      tzParam = clean.startsWith('+') || clean.startsWith('-') ? clean.split(':').first : '+$clean'.split(':').first;
    }
    final tzHours = double.tryParse(tzParam) ?? 3.0;

    // Calculate start of Ramadan for selected Hijri year
    final startOfRamadan = HijriDateService.hijriToGregorian(_selectedHijriYear, 9, 1);
    final now = DateTime.now();

    final List<RamadanDayData> list = [];

    for (int day = 1; day <= 30; day++) {
      final gDate = startOfRamadan.add(Duration(days: day - 1));
      final dayName = HijriDateService.weekdaysAr[gDate.weekday - 1];
      final monthName = HijriDateService.monthsGregorianAr[gDate.month - 1];
      final gFormatted = '${HijriDateService.toArabicDigits(gDate.day)} $monthName';

      final isToday = (now.year == gDate.year && now.month == gDate.month && now.day == gDate.day);

      final times = KafeelApiService.calculateJaafariPrayerTimes(
        date: gDate,
        latitude: city.latitude,
        longitude: city.longitude,
        timezone: tzHours,
        calcMethod: settings.calculationMethod,
        midnightMethod: settings.midnightMethod,
      );

      // User requirement: Imsak is ALWAYS strictly 10 minutes before Fajr
      final rawImsak = _subtract10Minutes(times.fajr);

      list.add(RamadanDayData(
        dayNumber: day,
        dayName: dayName,
        gregorianDate: gDate,
        gregorianFormatted: gFormatted,
        imsak: formatTo12Hour(rawImsak),
        fajr: formatTo12Hour(times.fajr),
        sunrise: formatTo12Hour(times.sunrise),
        dhuhr: formatTo12Hour(times.dhuhr),
        asr: formatTo12Hour(times.asr),
        sunset: formatTo12Hour(times.sunset),
        maghrib: formatTo12Hour(times.maghrib),
        isha: formatTo12Hour(times.isha),
        midnight: formatTo12Hour(times.midnight),
        isToday: isToday,
      ));
    }

    if (mounted) {
      setState(() {
        _days = list;
        _isLoading = false;
      });
    }
  }

  /// Converts 24-hour time string ("15:20", "05:30", "23:36") to 12-hour format ("03:20 م", "05:30 ص", "11:36 م")
  static String formatTo12Hour(String time24) {
    if (time24.isEmpty) return '';
    try {
      final parts = time24.trim().split(':');
      if (parts.length < 2) return time24;
      int h = int.parse(parts[0].trim());
      int m = int.parse(parts[1].trim());

      final bool isPm = (h >= 12 && h < 24);
      int h12 = h % 12;
      if (h12 == 0) h12 = 12;

      final suffix = isPm ? 'م' : 'ص';
      final hStr = h12.toString().padLeft(2, '0');
      final mStr = m.toString().padLeft(2, '0');
      return '$hStr:$mStr $suffix';
    } catch (_) {
      return time24;
    }
  }

  static String _subtract10Minutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      m -= 10;
      if (m < 0) {
        m += 60;
        h = (h - 1 + 24) % 24;
      }
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  void _onCitySelected(CityLocation newCity) {
    setState(() {
      _selectedCity = newCity;
    });
    _calculateImsakiya();
  }

  void _changeYear(int delta) {
    final newYear = _selectedHijriYear + delta;
    if (newYear >= 1435 && newYear <= 1455) {
      setState(() {
        _selectedHijriYear = newYear;
      });
      _calculateImsakiya();
    }
  }

  void _showCityPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCities = DataService().cities.isNotEmpty ? DataService().cities : [CityLocation.defaultCity];
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = allCities.where((c) {
              if (query.trim().isEmpty) return true;
              return c.nameAr.contains(query.trim()) ||
                  c.province.contains(query.trim()) ||
                  c.countryAr.contains(query.trim());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132238) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'اختر المحافظة أو المدينة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B3A57),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تُحسب مواقيت الإمساك والإفطار وفق إحداثيات كل منطقة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      textDirection: TextDirection.rtl,
                      onChanged: (v) => setSheetState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن محافظة (بغداد، كربلاء، النجف، البصرة...)',
                        hintStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      ),
                      itemBuilder: (context, idx) {
                        final city = filtered[idx];
                        final isSelected = (_selectedCity?.id == city.id);
                        return ListTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            _onCitySelected(city);
                          },
                          leading: Icon(
                            city.isHolyCity ? Icons.mosque_rounded : Icons.location_city_rounded,
                            color: isSelected
                                ? const Color(0xFFFBBF24)
                                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                          ),
                          title: Text(
                            city.displayName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                  : (isDark ? Colors.white : const Color(0xFF1B3A57)),
                            ),
                          ),
                          subtitle: Text(
                            'خط عرض: ${city.latitude.toStringAsFixed(2)} | خط طول: ${city.longitude.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                              : null,
                        );
                      },
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

  void _shareTodayImsakiya() {
    final city = _selectedCity ?? CityLocation.defaultCity;
    final todayItem = _days.firstWhere(
      (d) => d.isToday,
      orElse: () => _days.first,
    );

    final text = '''
🌙 إمساكية شهر رمضان المبارك (${HijriDateService.toArabicDigits(_selectedHijriYear)} هـ)
📍 ${city.displayName}
📅 اليوم ${HijriDateService.toArabicDigits(todayItem.dayNumber)} رمضان (${todayItem.dayName} - ${todayItem.gregorianFormatted})

🛑 الإمساك: ${todayItem.imsak}
🕌 الفجر: ${todayItem.fajr}
🌅 الشروق: ${todayItem.sunrise}
☀️ الظهر: ${todayItem.dhuhr}
🌤️ العصر: ${todayItem.asr}
🌇 الغروب: ${todayItem.sunset}
🍽️ المغرب (الإفطار): ${todayItem.maghrib}
🌌 العشاء: ${todayItem.isha}
⏳ منتصف الليل: ${todayItem.midnight}

وفق الحساب الفلكي الشرعي المعتمد لمركز الكفيل / العتبات المقدسة
تطبيق نور العترة ✨
''';

    Share.share(text.trim());
  }

  void _openPosterShareSheet() {
    if (_days.isEmpty) {
      _calculateImsakiya();
    }
    final city = _selectedCity ?? StorageService().getSavedCity() ?? CityLocation.defaultCity;
    RamadanPosterShareSheet.show(
      context,
      days: _days,
      city: city,
      hijriYear: _selectedHijriYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final city = _selectedCity ?? CityLocation.defaultCity;
    final isCurrentYear = (_selectedHijriYear == _currentHijriYear);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الإمساكية',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              tooltip: 'تغيير المدينة: ${city.nameAr}',
              onPressed: _showCityPickerSheet,
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'تنزيل الإمساكية',
              onPressed: _openPosterShareSheet,
            ),
            IconButton(
              icon: Icon(_isTableView ? Icons.view_agenda_rounded : Icons.table_chart_rounded),
              tooltip: _isTableView ? 'عرض البطاقات' : 'عرض الجدول',
              onPressed: () => setState(() => _isTableView = !_isTableView),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'مشاركة توقيت اليوم',
              onPressed: _shareTodayImsakiya,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 1. Header with Year selector
                  _buildControlsHeader(isDark, city, isCurrentYear),

                  // 2. Info / Tip banner (Imsak explanation)
                  _buildImsakRuleBanner(isDark),

                  // 3. Main Content (Table or Cards)
                  Expanded(
                    child: _isTableView
                        ? _buildInteractiveTable(isDark)
                        : _buildCardsView(isDark),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Top Controls: Year Navigator ---
  Widget _buildControlsHeader(bool isDark, CityLocation city, bool isCurrentYear) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16253B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            tooltip: 'السنة التالية',
            onPressed: () => _changeYear(1),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.nights_stay_rounded, color: Color(0xFFFBBF24), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'رمضان ${HijriDateService.toArabicDigits(_selectedHijriYear)} هـ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B3A57),
                    ),
                  ),
                ],
              ),
              if (isCurrentYear)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'السنة الهجرية الحالية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            tooltip: 'السنة السابقة',
            onPressed: () => _changeYear(-1),
          ),
        ],
      ),
    );
  }

  // --- Rule Banner: Imsak 10 mins before Fajr ---
  Widget _buildImsakRuleBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'وقت الإمساك الشرعي محتسب دائماً قبل أذان الفجر بـ ١٠ دقائق احترازاً.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Interactive Professional Table ---
  Widget _buildInteractiveTable(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 720),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowHeight: 46,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 48,
              horizontalMargin: 12,
              columnSpacing: 14,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1B324F) : const Color(0xFFF0F7FD),
              ),
              columns: [
                _buildDataColumn('اليوم / التاريخ', isDark),
                _buildDataColumn('رمضان', isDark),
                _buildDataColumn('الإمساك', isDark, isHighlight: true),
                _buildDataColumn('الفجر', isDark),
                _buildDataColumn('الشروق', isDark),
                _buildDataColumn('الظهر', isDark),
                _buildDataColumn('العصر', isDark),
                _buildDataColumn('الغروب', isDark),
                _buildDataColumn('المغرب', isDark, isIftar: true),
                _buildDataColumn('العشاء', isDark),
                _buildDataColumn('نصف الليل', isDark),
              ],
              rows: _days.map((item) {
                final isToday = item.isToday;
                final rowColor = isToday
                    ? (isDark
                        ? const Color(0xFF0F392B)
                        : const Color(0xFFDCFCE7))
                    : (item.dayNumber % 2 == 0
                        ? (isDark ? const Color(0xFF16253B) : const Color(0xFFF8FAFC))
                        : (isDark ? const Color(0xFF132238) : Colors.white));

                return DataRow(
                  color: WidgetStateProperty.all(rowColor),
                  cells: [
                    // اليوم والتاريخ الميلادي
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.dayName,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.white : const Color(0xFF1B3A57)),
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                              ],
                            ],
                          ),
                          Text(
                            item.gregorianFormatted,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // يوم رمضان
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          HijriDateService.toArabicDigits(item.dayNumber),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isToday
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF1B3A57)),
                          ),
                        ),
                      ),
                    ),

                    // الإمساك (أصفر ذهبي)
                    DataCell(
                      Text(
                        item.imsak,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),

                    // الفجر
                    DataCell(Text(item.fajr, style: _timeStyle(isDark))),

                    // الشروق
                    DataCell(Text(item.sunrise, style: _timeStyle(isDark, isMuted: true))),

                    // الظهر
                    DataCell(Text(item.dhuhr, style: _timeStyle(isDark))),

                    // العصر
                    DataCell(Text(item.asr, style: _timeStyle(isDark))),

                    // الغروب
                    DataCell(Text(item.sunset, style: _timeStyle(isDark, isMuted: true))),

                    // المغرب (وقت الإفطار المبارك)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.maghrib,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),

                    // العشاء
                    DataCell(Text(item.isha, style: _timeStyle(isDark))),

                    // منتصف الليل
                    DataCell(Text(item.midnight, style: _timeStyle(isDark, isMuted: true))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String title, bool isDark, {bool isHighlight = false, bool isIftar = false}) {
    Color textColor = isDark ? Colors.white : const Color(0xFF1B3A57);
    if (isHighlight) textColor = const Color(0xFFD97706);
    if (isIftar) textColor = const Color(0xFF10B981);

    return DataColumn(
      label: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  TextStyle _timeStyle(bool isDark, {bool isMuted = false}) {
    return TextStyle(
      fontFamily: 'Cairo',
      fontSize: 10.5,
      fontWeight: isMuted ? FontWeight.normal : FontWeight.w600,
      color: isMuted
          ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
          : (isDark ? Colors.white : const Color(0xFF1E293B)),
    );
  }

  // --- 2. Alternative Cards View ---
  Widget _buildCardsView(bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      itemCount: _days.length,
      itemBuilder: (context, idx) {
        final item = _days[idx];
        return _buildDayCard(item, isDark);
      },
    );
  }

  Widget _buildDayCard(RamadanDayData item, bool isDark) {
    final isToday = item.isToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isToday
            ? (isDark ? const Color(0xFF0F392B) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF16253B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0)),
          width: isToday ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header of card: Day name, Ramadan number, Gregorian date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${HijriDateService.toArabicDigits(item.dayNumber)} رمضان',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.dayName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF1B3A57),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    item.gregorianFormatted,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'اليوم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Highlights Row: Imsak & Maghrib (Iftar) - Clean and concise to prevent any overlap
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإمساك',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      Text(
                        item.imsak,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإفطار',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        item.maghrib,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          // Secondary Prayer Times Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniTime('الفجر', item.fajr, isDark),
              _buildMiniTime('الشروق', item.sunrise, isDark),
              _buildMiniTime('الظهر', item.dhuhr, isDark),
              _buildMiniTime('العصر', item.asr, isDark),
              _buildMiniTime('العشاء', item.isha, isDark),
              _buildMiniTime('نصف الليل', item.midnight, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTime(String label, String value, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 9.5,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
