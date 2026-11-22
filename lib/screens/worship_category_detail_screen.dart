import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worship_item.dart';
import '../services/data_service.dart';
import '../services/settings_controller.dart';
import '../providers/worship_provider.dart';
import 'worship_detail_screen.dart';
import 'qibla_compass_screen.dart';
import 'ramadan_sub_list_screen.dart';
import '../models/ramadan_section.dart';
import '../services/ramadan_aamal_service.dart';

class WorshipTabItem {
  final String title;
  final String categoryKey;

  const WorshipTabItem({
    required this.title,
    required this.categoryKey,
  });
}

class WorshipCategoryDetailScreen extends StatefulWidget {
  final String title;
  final String? categoryKey;
  final List<WorshipTabItem>? tabs;

  const WorshipCategoryDetailScreen({
    super.key,
    required this.title,
    this.categoryKey,
    this.tabs,
  });

  @override
  State<WorshipCategoryDetailScreen> createState() => _WorshipCategoryDetailScreenState();
}

class _WorshipCategoryDetailScreenState extends State<WorshipCategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    if (widget.tabs != null && widget.tabs!.isNotEmpty) {
      _tabController = TabController(length: widget.tabs!.length, vsync: this);
      _tabController!.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTabs = widget.tabs != null && widget.tabs!.isNotEmpty;

    final isEmerald = context.watch<SettingsController>().themePalette == AppThemePalette.emeraldGreen;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isEmerald
                ? [const Color(0xFF04140D), const Color(0xFF082216), const Color(0xFF030E09)]
                : (isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF090D16)]
                    : [const Color(0xFFEBF7FD), const Color(0xFFE2F3F9), const Color(0xFFDCF0F9)]),
          ),
        ),
        child: Stack(
          children: [
            // Background watermark
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
                scrolledUnderElevation: 0,
                centerTitle: false,
                titleSpacing: 2,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'رجوع',
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  onPressed: () => Navigator.pop(context),
                ),
                title: _showSearch
                    ? TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث في ${widget.title}...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Search toggle button
                  IconButton(
                    icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 20),
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    tooltip: _showSearch ? 'إغلاق البحث' : 'بحث',
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                  ),
                  // Favorite button
                  IconButton(
                    icon: Icon(
                      widget.categoryKey == 'favorites' ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: widget.categoryKey == 'favorites' ? Colors.redAccent : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    constraints: const BoxConstraints(),
                    tooltip: 'المفضلة',
                    onPressed: () {
                      if (widget.categoryKey != 'favorites') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorshipCategoryDetailScreen(
                              title: 'الأدعية والزيارات المفضلة',
                              categoryKey: 'favorites',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SafeArea(
                top: false,
                bottom: true,
                child: Column(
                  children: [
                    // Tabs bar if multiple tabs exist (matches Month tabs & Section tabs)
                    if (hasTabs)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          indicator: BoxDecoration(
                            color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.65) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.7) : const Color(0xFFBAE6FD),
                              width: 1.2,
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: isDark ? Colors.white : const Color(0xFF0284C7),
                          unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          tabs: widget.tabs!.map((t) => Tab(text: t.title)).toList(),
                        ),
                      ),

                    // Content List
                    Expanded(
                      child: hasTabs
                          ? TabBarView(
                              controller: _tabController,
                              children: widget.tabs!.map((tabItem) {
                                return _buildCategoryItemList(tabItem.categoryKey, isDark);
                              }).toList(),
                            )
                          : _buildCategoryItemList(widget.categoryKey ?? '', isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItemList(String categoryKey, bool isDark) {
    if (categoryKey == 'aamal_ramadan') {
      return _buildRamadanCategoryList(isDark);
    }

    final provider = context.watch<WorshipProvider>();
    final List<WorshipItem> rawItems;
    if (categoryKey == 'favorites') {
      final allItems = <WorshipItem>[];
      DataService().worshipData.values.forEach(allItems.addAll);
      rawItems = allItems.where((item) => provider.favorites.contains(item.title)).toList();
    } else {
      rawItems = DataService().getItemsByCategory(categoryKey);
    }

    final items = _searchQuery.trim().isEmpty
        ? rawItems
        : rawItems.where((i) => i.title.contains(_searchQuery) || i.text.contains(_searchQuery)).toList();

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryKey == 'favorites' ? Icons.favorite_border_rounded : Icons.menu_book_rounded,
                size: 48,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'لم يتم العثور على نتائج للبحث'
                    : (categoryKey == 'favorites'
                        ? 'لم تقم بإضافة أي دعاء أو عمل إلى المفضلة بعد ❤️'
                        : 'لا توجد نصوص مسجلة في هذا القسم حالياً'),
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 48,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorshipDetailScreen(
                    item: item,
                    showAudio: !categoryKey.startsWith('aamal_') &&
                        categoryKey != 'azkarList' &&
                        !categoryKey.contains('azkar') &&
                        !categoryKey.contains('adhkar') &&
                        categoryKey != 'salawatsOnHujaj' &&
                        !categoryKey.contains('salawat') &&
                        categoryKey != 'sahifaSajjadiya' &&
                        !categoryKey.contains('sahifa') &&
                        categoryKey != 'tasbeehat' &&
                        categoryKey != 'taqeebat' &&
                        !categoryKey.contains('rules'),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Number badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.35) : const Color(0xFFF0F7FB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRamadanCategoryList(bool isDark) {
    final sections = RamadanAamalService().getSections();

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim();
      final matchingSubItems = <MapEntry<RamadanSection, WorshipItem>>[];
      final matchingSections = <RamadanSection>[];

      for (final section in sections) {
        if (section.title.contains(query)) {
          matchingSections.add(section);
        }
        for (final item in section.items) {
          if (item.title.contains(query) || item.text.contains(query)) {
            matchingSubItems.add(MapEntry(section, item));
          }
        }
      }

      if (matchingSubItems.isEmpty && matchingSections.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'لم يتم العثور على نتائج للبحث في أعمال شهر رمضان',
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 48),
        children: [
          if (matchingSections.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'الأقسام الرئيسية المطابقة (${matchingSections.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
              ),
            ),
            ...matchingSections.asMap().entries.map((e) => _buildRamadanSectionCard(e.value, isDark, e.key)),
            const SizedBox(height: 12),
          ],
          if (matchingSubItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'الأدعية والأعمال المطابقة (${matchingSubItems.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
              ),
            ),
            ...matchingSubItems.asMap().entries.map((e) => _buildRamadanSubItemCard(e.value.key, e.value.value, isDark, e.key)),
          ],
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 48),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return _buildRamadanSectionCard(section, isDark, index);
      },
    );
  }

  Widget _buildRamadanSectionCard(RamadanSection section, bool isDark, int index) {
    final hasSub = section.hasSubItems;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () {
          if (hasSub) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RamadanSubListScreen(
                  title: section.title,
                  subtitle: section.subtitle,
                  items: section.items,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorshipDetailScreen(
                  item: section.items.first,
                  showAudio: false,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular number badge (دائرة الترقيم الموحدة)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.35) : const Color(0xFFF0F7FB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    if (section.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        section.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRamadanSubItemCard(RamadanSection parentSection, WorshipItem item, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorshipDetailScreen(
                item: item,
                showAudio: false,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular number badge (دائرة الترقيم الموحدة)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.35) : const Color(0xFFF0F7FB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parentSection.title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Background painter for subtle geometric watermark
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
