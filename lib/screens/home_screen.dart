import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../services/hijri_date_service.dart';
import '../models/quran_chapter.dart';
import '../models/worship_item.dart';
import '../services/settings_controller.dart';
import '../widgets/collapsible_prayer_card.dart';
import '../widgets/home_action_cards.dart';
import '../widgets/auto_scrolling_events_banner.dart';
import '../widgets/ayah_number_symbol.dart';
import '../widgets/quran_verse_share_sheet.dart';
import 'prayer_times_screen.dart';
import 'qibla_compass_screen.dart';
import 'worship_detail_screen.dart';
import 'worship_screen.dart';
import 'worship_category_detail_screen.dart';
import 'quran_reader_screen.dart';
import '../features/sharia_inquiries/screens/sharia_search_screen.dart';
import '../widgets/battery_permission_dialog.dart';
import '../services/adhan_scheduler_service.dart';
import '../services/app_update_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isQabasExpanded = true;
  Timer? _qabasTimer;
  int _qabasIndex = 0;
  final GlobalKey _verseCardKey = GlobalKey();

  // Selected Daily Quran Verse
  int _qabasSurahId = 13;
  int _qabasAyahNum = 28;
  String _qabasSurahName = 'الرعد';
  int _qabasJuz = 13;
  String _qabasAyahText = 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ';

  final List<Map<String, dynamic>> _sampleAyahs = [
    {
      'surahId': 13,
      'surahName': 'الرعد',
      'ayahNum': 28,
      'juz': 13,
      'text': 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    },
    {
      'surahId': 94,
      'surahName': 'الشرح',
      'ayahNum': 5,
      'juz': 30,
      'text': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا • إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    },
    {
      'surahId': 93,
      'surahName': 'الضحى',
      'ayahNum': 5,
      'juz': 30,
      'text': 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ',
    },
    {
      'surahId': 36,
      'surahName': 'يس',
      'ayahNum': 58,
      'juz': 23,
      'text': 'سَلَامٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ',
    },
    {
      'surahId': 48,
      'surahName': 'الفتح',
      'ayahNum': 1,
      'juz': 26,
      'text': 'إِنَّا فَتَحْنَا لَكَ فَتْحًا مُّبِينًا',
    },
    {
      'surahId': 2,
      'surahName': 'البقرة',
      'ayahNum': 152,
      'juz': 2,
      'text': 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    },
    {
      'surahId': 2,
      'surahName': 'البقرة',
      'ayahNum': 186,
      'juz': 2,
      'text': 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
    },
    {
      'surahId': 20,
      'surahName': 'طه',
      'ayahNum': 114,
      'juz': 16,
      'text': 'فَتَعَالَى اللَّهُ الْمَلِكُ الْحَقُّ ۗ وَقُل رَّبِّ زِدْنِي عِلْمًا',
    },
    {
      'surahId': 21,
      'surahName': 'الأنبياء',
      'ayahNum': 87,
      'juz': 17,
      'text': 'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
    },
    {
      'surahId': 65,
      'surahName': 'الطلاق',
      'ayahNum': 3,
      'juz': 28,
      'text': 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ ۚ إِنَّ اللَّهَ بَالِغُ أَمْرِهِ',
    },
    {
      'surahId': 59,
      'surahName': 'الحشر',
      'ayahNum': 22,
      'juz': 28,
      'text': 'هُوَ اللَّهُ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ ۖ عَالِمُ الْغَيْبِ وَالشَّهَادَةِ ۖ هُوَ الرَّحْمَٰنُ الرَّحِيمُ',
    },
    {
      'surahId': 76,
      'surahName': 'الإنسان',
      'ayahNum': 8,
      'juz': 29,
      'text': 'وَيُطْعِمُونَ الطَّعَامَ عَلَىٰ حُبِّهِ مِسْكِينًا وَيَتِيمًا وَأَسِيرًا',
    },
    {
      'surahId': 97,
      'surahName': 'القدر',
      'ayahNum': 1,
      'juz': 30,
      'text': 'إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ',
    },
    {
      'surahId': 108,
      'surahName': 'الكوثر',
      'ayahNum': 1,
      'juz': 30,
      'text': 'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ • فَصَلِّ لِرَبِّكَ وَانْحَرْ',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HijriDateService.dateNotifier.addListener(_onHijriDateUpdated);
    AdhanSchedulerService().syncAdhanPlayingState();
    _startQabasAutoRotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BatteryPermissionDialog.checkAndShow(context);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          AppUpdateService.checkUpdateSilently(context);
        }
      });
    });
  }

  void _onHijriDateUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    HijriDateService.dateNotifier.removeListener(_onHijriDateUpdated);
    WidgetsBinding.instance.removeObserver(this);
    _qabasTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdhanSchedulerService().syncAdhanPlayingState();
    }
  }

  /// Automatically rotates verses every 7 to 10 seconds based on verse text length
  void _startQabasAutoRotation() {
    _qabasTimer?.cancel();
    final durationSeconds = _qabasAyahText.length > 55 ? 10 : 7;
    _qabasTimer = Timer(Duration(seconds: durationSeconds), () {
      if (!mounted) return;
      _advanceQabasAyah();
      _startQabasAutoRotation();
    });
  }

  void _advanceQabasAyah() {
    _qabasIndex = (_qabasIndex + 1) % _sampleAyahs.length;
    final next = _sampleAyahs[_qabasIndex];
    setState(() {
      _qabasSurahId = next['surahId'];
      _qabasSurahName = next['surahName'];
      _qabasAyahNum = next['ayahNum'];
      _qabasJuz = next['juz'];
      _qabasAyahText = next['text'];
    });
  }

  void _openQuranAtQabasAyah() {
    final chapter = QuranChapter.allChapters.firstWhere(
      (c) => c.id == _qabasSurahId,
      orElse: () => QuranChapter.allChapters.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          chapter: chapter,
          initialAyah: _qabasAyahNum,
        ),
      ),
    );
  }

  void _refreshQabasAyah() {
    _advanceQabasAyah();
    _startQabasAutoRotation();
  }




  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings.themePalette == AppThemePalette.royalDark;
    final isDark = isEmerald || isRoyalDark;

    // Real Hijri & Gregorian Dates (strictly governed by verified HijriDateService & repository)
    final hijriInfo = HijriDateService.getHijriDate();
    final hijriStr = hijriInfo['formatted'] as String;
    final gregorianStr = HijriDateService.getGregorianFormatted();

    // Today's deeds list
    final dailyDeeds = HijriDateService.getDeedsForDay();
    final primaryDeedTitle = dailyDeeds.isNotEmpty ? dailyDeeds.first['title']! : 'دعاء يوم الجمعة';

    return Container(
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
          // Subtle Islamic geometric watermark pattern in upper screen background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _IslamicGeometricWatermarkPainter(
                  lineColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFF0284C7).withValues(alpha: 0.08),
                  goldColor: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFD4AF37).withValues(alpha: 0.06),
                ),
              ),
            ),
          ),

          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 14,
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
                          color: Colors.black.withValues(alpha: 0.12),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              actions: [
                // "القبلة" button with compass
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
                      color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.35) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore_outlined, size: 15, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text(
                          'القبلة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
                // Favorite button (Heart)
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
            body: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF0284C7),
                    onRefresh: () async {
                      await HijriDateService.syncHijriFromRepository(force: true);
                      if (mounted) setState(() {});
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                // 1. Salawat Banner (شريط الصلاة على محمد وآل محمد)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E28) : Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ الطَّيِّبِينَ الطَّاهِرِينَ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                ),

                // 2. Hijri & Gregorian Date Card (بطاقة التقويم المحدثة تلقائياً)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132D29).withValues(alpha: 0.7) : const Color(0xFFE5F8F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2DD4BF).withValues(alpha: 0.4) : const Color(0xFF80DFD2),
                      width: 1.2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => MainNavigationScreen.switchTab(context, 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          children: [
                      // Top Hijri Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mosque, color: Color(0xFF00BFA5), size: 17),
                              const SizedBox(width: 8),
                              Text(
                                hijriStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF134E48) : const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'هجري',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0D9488),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      // Bottom Gregorian Row (No divider line)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, color: isDark ? Colors.white60 : Colors.grey.shade600, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                gregorianStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'ميلادي',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.normal,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

                // 3. Today's Deed Card (أعمال اليوم متغيرة حسب اليوم وتفتح قائمة الأعمال) - ألوان متطابقة مع بطاقة مواقيت الصلاة
                if (settings.showDailyDeedsBanner) ...[
                  InkWell(
                    onTap: () => _showDailyDeedsSheet(context, dailyDeeds, hijriInfo['weekday'] as String),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E28) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E88E5).withValues(alpha: 0.35) : const Color(0xFFBFDBFE),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F1FC),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF),
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أعمال اليوم (${hijriInfo['weekday']})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  primaryDeedTitle,
                                  textAlign: TextAlign.justify,
                                  softWrap: true,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDDEBF7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2A5A84), size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  'عرض الكل',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2A5A84),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // 4. Collapsible Prayer Times Card (مواقيت الصلاة القابلة للتوسع إلى 8 مواقيت)
                if (settings.showPrayerCard) ...[
                  CollapsibleHomePrayerCard(
                    onOpenPrayerTimes: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
                      );
                    },
                  ),
                ],

                // 4.5. "المجيب" Card (البحث في المسائل والأجوبة الشرعية)
                if (settings.showAlmojibCard) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShariaSearchScreen()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E28) : const Color(0xFFEAF6FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F766E).withValues(alpha: 0.4)
                              : const Color(0xFFBAE6FD),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF10B981).withValues(alpha: 0.16)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.question_answer_rounded,
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المجيب • اسأل عن المسائل الشرعية',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ابحث عن الفتاوى والأجوبة المنشورة وفق مدرسة أهل البيت (ع)',
                                  textAlign: TextAlign.justify,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    height: 1.35,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 14,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'بحث',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // 5. "قبس من كلام الله" Card (تتغير تلقائياً كل 7-10 ثوانٍ)
                if (settings.showQabasBanner) ...[
                  Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E28) : const Color(0xFFDEF2F4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F766E).withValues(alpha: 0.4) : const Color(0xFFA6E3DC),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: [
                        // Header row: Book icon + قبس من كلام الله + refresh + badge + collapse
                        Row(
                          children: [
                            // Right in RTL: Book icon + "قبس من كلام الله"
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book, color: Color(0xFFC09040), size: 19),
                                const SizedBox(width: 5),
                                Text(
                                  'قبس من كلام الله',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F4C5C),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Refresh button
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 19),
                              color: isDark ? Colors.white70 : const Color(0xFF0F766E),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _refreshQabasAyah,
                            ),
                            const SizedBox(width: 8),

                            // Collapse / Expand toggle
                            IconButton(
                              icon: Icon(
                                _isQabasExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                                size: 21,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _isQabasExpanded = !_isQabasExpanded),
                            ),
                          ],
                        ),

                        if (_isQabasExpanded) ...[
                          const SizedBox(height: 12),

                          // Inner Frame Box with RepaintBoundary for high-res image export
                          InkWell(
                            onTap: _openQuranAtQabasAyah,
                            borderRadius: BorderRadius.circular(14),
                            child: RepaintBoundary(
                              key: _verseCardKey,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFC9A86A).withValues(alpha: 0.7),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Top page info: Surah & Juz
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'سورة $_qabasSurahName',
                                          style: const TextStyle(
                                            color: Color(0xFFB88E4C),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'الجزء $_qabasJuz',
                                          style: const TextStyle(
                                            color: Color(0xFFB88E4C),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Divider(color: Color(0xFFEBE0CC), height: 20, thickness: 1),

                                    // Ayah Text with smooth transition & ornamental end circle at the end of the verse
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      child: Padding(
                                        key: ValueKey('$_qabasSurahId:$_qabasAyahNum'),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: _qabasAyahText,
                                                style: TextStyle(
                                                  fontFamily: 'Amiri',
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.normal,
                                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                                  height: 2.25,
                                                  letterSpacing: 0.1,
                                                  wordSpacing: 1.2,
                                                ),
                                              ),
                                              const TextSpan(text: ' '),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.middle,
                                                child: AyahNumberSymbol(
                                                  ayahNumber: _qabasAyahNum,
                                                  size: 28.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Buttons: "مشاركة كصورة", "نسخ النص"
                          Row(
                            children: [
                              // Right button: مشاركة كصورة
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    QuranVerseShareSheet.show(
                                      context,
                                      surahName: _qabasSurahName,
                                      ayahNum: _qabasAyahNum,
                                      ayahText: _qabasAyahText,
                                      juz: _qabasJuz,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7EFFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE8D4F5), width: 1),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.share_outlined, size: 15, color: Color(0xFF9333EA)),
                                        SizedBox(width: 6),
                                        Text(
                                          'مشاركة كصورة',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B21A8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Left button: نسخ النص
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                      text: '$_qabasAyahText [سورة $_qabasSurahName: $_qabasAyahNum]',
                                    ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم نسخ الآية المباركة إلى الحافظة 📋')),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7EFFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE8D4F5), width: 1),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.copy_outlined, size: 15, color: Color(0xFFB88E4C)),
                                        SizedBox(width: 6),
                                        Text(
                                          'نسخ النص',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B21A8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Hint footer
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_outlined, size: 13, color: Color(0xFFB89E70)),
                              SizedBox(width: 4),
                              Text(
                                'اضغط على البطاقة لفتح الآية في القرآن الكريم',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB89E70)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ],

                const SizedBox(height: 12),
                const HomeActionCards(),
                if (settings.showEventsCard) ...[
                  const SizedBox(height: 12),
                  const AutoScrollingEventsBanner(),
                ],
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays modal sheet with all organized deeds for today
  void _showDailyDeedsSheet(BuildContext context, List<Map<String, String>> deeds, String weekday) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أعمال وأدعية يوم $weekday المبارك',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: deeds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final d = deeds[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFF1E88E5), size: 18),
                      ),
                      title: Text(
                        d['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        d['desc']!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openDeedDetail(context, d['title']!, d['category']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDeedDetail(BuildContext context, String title, String categoryKey) {
    final list = DataService().worshipData[categoryKey] ?? [];
    final item = list.firstWhere(
      (w) => w.title.contains(title) || title.contains(w.title),
      orElse: () => list.isNotEmpty
          ? list.first
          : WorshipItem(title: title, text: 'نص $title المبارك', categoryKey: categoryKey),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorshipDetailScreen(item: item)),
    );
  }
}

// Custom Painter for authentic subtle Islamic Geometry lines in the background
class _IslamicGeometricWatermarkPainter extends CustomPainter {
  final Color lineColor;
  final Color goldColor;

  _IslamicGeometricWatermarkPainter({required this.lineColor, required this.goldColor});

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

    // 8-pointed star polygons
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
  bool shouldRepaint(covariant _IslamicGeometricWatermarkPainter oldDelegate) => false;
}
