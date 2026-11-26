import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/worship_provider.dart';
import '../services/settings_controller.dart';
import '../services/voice_search_service.dart';
import 'worship_detail_screen.dart';
import 'worship_category_detail_screen.dart';
import 'prayer_times_screen.dart';
import 'worship_audios_screen.dart';
import 'tasbeeh_screen.dart';
import 'rakaat_counter_screen.dart';
import 'qibla_compass_screen.dart';
import 'ramadan_imsakiya_screen.dart';
import 'wallpapers_screen.dart';
import '../features/sharia_inquiries/screens/sharia_search_screen.dart';

class WorshipGridItem {
  final String title;
  final String assetPath;
  final IconData fallbackIcon;
  final Widget Function(BuildContext) screenBuilder;

  const WorshipGridItem({
    required this.title,
    required this.assetPath,
    required this.fallbackIcon,
    required this.screenBuilder,
  });
}

class WorshipScreen extends StatefulWidget {
  final String? initialCategoryKey;

  const WorshipScreen({super.key, this.initialCategoryKey});

  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  static final List<WorshipGridItem> _worshipGridItems = [
    // 0. المجيب للاستفتاءات الشرعية (في البداية)
    WorshipGridItem(
      title: 'المجيب',
      assetPath: '',
      fallbackIcon: Icons.question_answer_rounded,
      screenBuilder: (_) => const ShariaSearchScreen(),
    ),
    // 1. مواقيت الصلاة
    WorshipGridItem(
      title: 'مواقيت الصلاة',
      assetPath: 'assets/images/worship/prayer_times.png',
      fallbackIcon: Icons.access_time_filled_rounded,
      screenBuilder: (_) => const PrayerTimesScreen(),
    ),
    // 2. الإمساكية
    WorshipGridItem(
      title: 'الإمساكية',
      assetPath: 'assets/images/worship/sawm.png',
      fallbackIcon: Icons.nights_stay_rounded,
      screenBuilder: (_) => const RamadanImsakiyaScreen(),
    ),
    // 2. صوتيات
    WorshipGridItem(
      title: 'صوتيات',
      assetPath: 'assets/images/worship/audios.png',
      fallbackIcon: Icons.headset_mic_rounded,
      screenBuilder: (_) => const WorshipAudiosScreen(),
    ),
    // 3. أذكار
    WorshipGridItem(
      title: 'أذكار',
      assetPath: 'assets/images/worship/azkar.png',
      fallbackIcon: Icons.auto_awesome_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'أذكار',
        categoryKey: 'azkarList',
      ),
    ),
    // 4. مناجاة
    WorshipGridItem(
      title: 'مناجاة',
      assetPath: 'assets/images/worship/munajat.png',
      fallbackIcon: Icons.volunteer_activism_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'المناجاة',
        tabs: [
          WorshipTabItem(title: 'المناجاة', categoryKey: 'munajat'),
          WorshipTabItem(title: 'التسبيحات', categoryKey: 'tasbeehat'),
        ],
      ),
    ),
    // 5. الزيارات
    WorshipGridItem(
      title: 'الزيارات',
      assetPath: 'assets/images/worship/ziyarat.png',
      fallbackIcon: Icons.mosque_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'الزيارات',
        tabs: [
          WorshipTabItem(title: 'الزيارات العامة', categoryKey: 'ziyarats'),
          WorshipTabItem(title: 'زيارات أيام الأسبوع', categoryKey: 'ziyaratsOfDays'),
        ],
      ),
    ),
    // 6. الأدعية
    WorshipGridItem(
      title: 'الأدعية',
      assetPath: 'assets/images/worship/duas.png',
      fallbackIcon: Icons.menu_book_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'الادعية',
        tabs: [
          WorshipTabItem(title: 'الأدعية العامة', categoryKey: 'generalPrayers'),
          WorshipTabItem(title: 'أدعية الأيام', categoryKey: 'dailyPrayers'),
          WorshipTabItem(title: 'الصلوات على الحجج الطاهرين', categoryKey: 'salawatsOnHujaj'),
        ],
      ),
    ),
    // 7. الصحيفة السجادية
    WorshipGridItem(
      title: 'الصحيفة السجادية',
      assetPath: 'assets/images/worship/sahifa.png',
      fallbackIcon: Icons.import_contacts_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'الصحيفة السجادية',
        categoryKey: 'sahifaSajjadiya',
      ),
    ),
    // 8. الصلاة
    WorshipGridItem(
      title: 'الصلاة',
      assetPath: 'assets/images/worship/salah.png',
      fallbackIcon: Icons.accessibility_new_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'الصلاة',
        tabs: [
          WorshipTabItem(title: 'الصلوات المستحبة', categoryKey: 'obligatoryAndRecommendedPrayers'),
          WorshipTabItem(title: 'صلوات وأدعية الأئمة', categoryKey: 'ahlAlBaytPrayers'),
        ],
      ),
    ),
    // 9. أحكام الصوم
    WorshipGridItem(
      title: 'أحكام الصوم',
      assetPath: 'assets/images/worship/sawm.png',
      fallbackIcon: Icons.wb_twilight_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'أحكام الصوم',
        categoryKey: 'fastingRules',
      ),
    ),
    // 10. أحكام الحج
    WorshipGridItem(
      title: 'أحكام الحج',
      assetPath: 'assets/images/worship/hajj.png',
      fallbackIcon: Icons.explore_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'أحكام الحج',
        categoryKey: 'hajjRules',
      ),
    ),
    // 11. الأعمال
    WorshipGridItem(
      title: 'الأعمال',
      assetPath: 'assets/images/worship/aamal.png',
      fallbackIcon: Icons.calendar_month_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'الاعمال',
        tabs: [
          WorshipTabItem(title: 'محرم الحرام', categoryKey: 'aamal_muharram'),
          WorshipTabItem(title: 'صفر', categoryKey: 'aamal_safar'),
          WorshipTabItem(title: 'ربيع الأول', categoryKey: 'aamal_rabi1'),
          WorshipTabItem(title: 'ربيع الآخر', categoryKey: 'aamal_rabi2'),
          WorshipTabItem(title: 'جمادى الأولى', categoryKey: 'aamal_jumada1'),
          WorshipTabItem(title: 'جمادى الآخرة', categoryKey: 'aamal_jumada2'),
          WorshipTabItem(title: 'رجب', categoryKey: 'aamal_rajab'),
          WorshipTabItem(title: 'شعبان', categoryKey: 'aamal_shaban'),
          WorshipTabItem(title: 'شهر رمضان', categoryKey: 'aamal_ramadan'),
          WorshipTabItem(title: 'شوال', categoryKey: 'aamal_shawwal'),
          WorshipTabItem(title: 'ذو القعدة', categoryKey: 'aamal_dhul_qada'),
          WorshipTabItem(title: 'ذو الحجة', categoryKey: 'aamal_dhul_hijjah'),
        ],
      ),
    ),
    // 12. تعقيبات الصلاة
    WorshipGridItem(
      title: 'تعقيبات الصلاة',
      assetPath: 'assets/images/worship/taqibat.png',
      fallbackIcon: Icons.format_list_bulleted_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'تعقيبات الصلاة',
        categoryKey: 'taqeebat',
      ),
    ),
    // 13. المسبحة
    WorshipGridItem(
      title: 'المسبحة',
      assetPath: 'assets/images/worship/misbaha.png',
      fallbackIcon: Icons.radio_button_checked_rounded,
      screenBuilder: (_) => const TasbeehScreen(),
    ),
    // 14. الأدعية المختارة
    WorshipGridItem(
      title: 'الأدعية المختارة',
      assetPath: 'assets/images/worship/selected_duas.png',
      fallbackIcon: Icons.star_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'الأدعية المختارة',
        categoryKey: 'concisePrayers',
      ),
    ),
    // 15. عداد الركع
    WorshipGridItem(
      title: 'عداد الركع',
      assetPath: 'assets/images/worship/rakat_counter.png',
      fallbackIcon: Icons.touch_app_rounded,
      screenBuilder: (_) => const RakaatCounterScreen(),
    ),
    // 16. صلوات أهل البيت
    WorshipGridItem(
      title: 'صلوات أهل البيت',
      assetPath: 'assets/images/worship/salawat.png',
      fallbackIcon: Icons.favorite_rounded,
      screenBuilder: (_) => const WorshipCategoryDetailScreen(
        title: 'صلوات أهل البيت',
        categoryKey: 'salawatsOnHujaj',
      ),
    ),
    // 17. الخلفيات الإسلامية
    WorshipGridItem(
      title: 'خلفيات',
      assetPath: 'assets/images/worship/wallpapers.png',
      fallbackIcon: Icons.wallpaper_rounded,
      screenBuilder: (_) => const WallpapersScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCategoryByKey(widget.initialCategoryKey!);
      });
    }
  }

  void _openCategoryByKey(String key) {
    if (key == 'favorites') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WorshipCategoryDetailScreen(
            title: 'المفضلة',
            categoryKey: 'favorites',
          ),
        ),
      );
      return;
    }
    for (final item in _worshipGridItems) {
      if (item.title.contains(key) ||
          key.contains(item.title) ||
          (key.toLowerCase().contains('taq') && item.title == 'تعقيبات الصلاة')) {
        Navigator.push(context, MaterialPageRoute(builder: item.screenBuilder));
        return;
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorshipProvider>();
    final settings = context.watch<SettingsController>();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings.themePalette == AppThemePalette.royalDark;
    final isDark = isEmerald || isRoyalDark;
    final isSearching = provider.searchQuery.trim().isNotEmpty;
    final searchResults = provider.searchResults;

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
            // Background subtle watermark
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 350,
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
                automaticallyImplyLeading: false,
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
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Qibla button
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
                  IconButton(
                    icon: const Icon(Icons.search_rounded, size: 22),
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, size: 22),
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    constraints: const BoxConstraints(),
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
              body: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  // 1. Search Field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => provider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'ابحث في كافة الأدعية والزيارات والأعمال...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 22),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSearching)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    provider.setSearchQuery('');
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.mic, color: Color(0xFF0284C7), size: 20),
                                tooltip: 'البحث الصوتي',
                                onPressed: () async {
                                  final spoken = await VoiceSearchService.startVoiceSearch(
                                    context,
                                    prompt: 'تحدث باسم الدعاء أو العمل...',
                                  );
                                  if (spoken != null && spoken.isNotEmpty) {
                                    _searchCtrl.text = spoken;
                                    provider.setSearchQuery(spoken);
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  ),

                  // 2. Search mode content & Worship Category Grid
                  if (isSearching) ...[
                    // A. Matching Category Windows (if any match the query)
                    Builder(builder: (context) {
                      final cleanQ = _searchCtrl.text.trim();
                      final matchingCategories = _worshipGridItems.where((item) {
                        return item.title.contains(cleanQ);
                      }).toList();

                      if (matchingCategories.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            child: Text(
                              'الأقسام المطابقة (${matchingCategories.length})',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE1EFF7),
                                ),
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: matchingCategories.length,
                                itemBuilder: (context, index) => _buildGridCard(matchingCategories[index], isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),

                    // B. Matching Duas & Texts Search Results
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Text(
                        'الأدعية والزيارات المطابقة (${searchResults.length})',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    if (searchResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Center(
                          child: Text(
                            'لم يتم العثور على أدعية أو زيارات مطابقة',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(searchResults.length, (index) {
                        final item = searchResults[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorshipDetailScreen(item: item),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1B3A57),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 14,
                                    color: Color(0xFF0284C7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 16),
                    // Section title for all main categories so they are never lost
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Text(
                        'كافة الأقسام والنوافذ',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                        ),
                      ),
                    ),
                  ],

                  // 3. The 16 Worship Icons Grid (4 columns) - Opens Dedicated Window on Tap
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE1EFF7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _worshipGridItems.length,
                        itemBuilder: (context, index) {
                          return _buildGridCard(_worshipGridItems[index], isDark);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(WorshipGridItem item, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: item.screenBuilder),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular icon container with double border & edge-to-edge icon fitting
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFDCEAF5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF16202C) : Colors.white,
              ),
              child: ClipOval(
                child: item.assetPath.isEmpty
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: isDark
                                  ? const [Color(0xFF064E3B), Color(0xFF0F172A)]
                                  : const [Color(0xFFE0F2FE), Color(0xFFF0FDF4)],
                            ),
                          ),
                          child: Icon(
                            item.fallbackIcon,
                            size: 28,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF1B3A57),
                          ),
                        ),
                      )
                    : Image.asset(
                        item.assetPath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            item.fallbackIcon,
                            size: 28,
                            color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Worship Title text
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: isDark ? Colors.white : const Color(0xFF1B3A57),
            ),
          ),
        ],
      ),
    );
  }
}

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

    final center = Offset(size.width / 2, 80);
    final radii = [50.0, 90.0, 135.0, 180.0];

    for (final r in radii) {
      canvas.drawCircle(center, r, linePaint);
    }

    for (int i = 0; i < 16; i++) {
      final angle = i * pi / 8;
      final p1 = Offset(center.dx + 35 * cos(angle), center.dy + 35 * sin(angle));
      final p2 = Offset(center.dx + 220 * cos(angle), center.dy + 220 * sin(angle));
      canvas.drawLine(p1, p2, (i % 2 == 0) ? goldPaint : linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicGeometricWatermarkPainter oldDelegate) => false;
}
