import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worship_item.dart';
import '../services/settings_controller.dart';
import 'worship_detail_screen.dart';
import 'qibla_compass_screen.dart';
import 'worship_category_detail_screen.dart';

class RamadanSubListScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<WorshipItem> items;

  const RamadanSubListScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
  });

  @override
  State<RamadanSubListScreen> createState() => _RamadanSubListScreenState();
}

class _RamadanSubListScreenState extends State<RamadanSubListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmerald = context.watch<SettingsController>().themePalette == AppThemePalette.emeraldGreen;

    final filteredItems = _searchQuery.trim().isEmpty
        ? widget.items
        : widget.items.where((i) => i.title.contains(_searchQuery) || i.text.contains(_searchQuery)).toList();

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
            // Background geometric watermark
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
                      Icons.favorite_border_rounded,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    constraints: const BoxConstraints(),
                    tooltip: 'المفضلة',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorshipCategoryDetailScreen(
                            title: 'الأدعية والزيارات المفضلة',
                            categoryKey: 'favorites',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SafeArea(
                top: false,
                bottom: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Items list
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                'لم يتم العثور على نتائج للبحث',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                MediaQuery.of(context).padding.bottom + 48,
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5.5),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
                                          // Title
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
                            ),
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
