import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/worship_item.dart';
import '../screens/worship_detail_screen.dart';
import '../screens/worship_category_detail_screen.dart';
import '../screens/worship_screen.dart';
import '../screens/tasbeeh_screen.dart';

class HomeActionCards extends StatelessWidget {
  const HomeActionCards({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Day of the week in Arabic
    final now = DateTime.now();
    const weekdays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    final weekdayAr = weekdays[now.weekday - 1];

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final row2Bg = isDark ? const Color(0xFF1E2E40) : const Color(0xFFEFF6FF);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final row2BorderColor = isDark ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFFBFDBFE);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      children: [
        // -------------------------------------------------------------
        // الصف الأول: 3 بطاقات يومية ديناميكية (زيارة | دعاء | تسبيح)
        // -------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              // 1. زيارة اليوم
              Expanded(
                child: _buildSmallDailyCard(
                  title: 'زيارة $weekdayAr',
                  imageAsset: 'assets/images/ic_worship_ziyarat_3d.png',
                  bgColor: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => _openDailyWorship(context, 'زيارة يوم $weekdayAr', 'ziyaratsOfDays'),
                ),
              ),
              const SizedBox(width: 8),

              // 2. دعاء اليوم
              Expanded(
                child: _buildSmallDailyCard(
                  title: 'دعاء $weekdayAr',
                  imageAsset: 'assets/images/ic_worship_dua_3d.png',
                  bgColor: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => _openDailyWorship(context, 'دعاء يوم $weekdayAr', 'dailyPrayers'),
                ),
              ),
              const SizedBox(width: 8),

              // 3. تسبيح اليوم
              Expanded(
                child: _buildSmallDailyCard(
                  title: 'تسبيح $weekdayAr',
                  imageAsset: 'assets/images/ic_worship_munajat_3d.png',
                  bgColor: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => _openDailyWorship(context, 'تسبيح يوم $weekdayAr', 'tasbeehat'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // -------------------------------------------------------------
        // الصف الثاني: بطاقتان متجاورتان (تعقيبات الصلاة | المسبحة الإلكترونية)
        // -------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              // 1. تعقيبات الصلاة
              Expanded(
                child: _buildMediumActionCard(
                  title: 'تعقيبات الصلاة',
                  subtitle: 'الفرائض اليومية',
                  imageAsset: 'assets/images/ic_worship_taqibat_3d.png',
                  bgColor: row2Bg,
                  borderColor: row2BorderColor,
                  textColor: isDark ? Colors.white : const Color(0xFF0369A1),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorshipCategoryDetailScreen(
                          title: 'تعقيبات الصلاة',
                          categoryKey: 'taqeebat',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),

              // 2. المسبحة
              Expanded(
                child: _buildMediumActionCard(
                  title: 'المسبحة',
                  subtitle: 'تسبيح الزهراء (ع)',
                  imageAsset: 'assets/images/ic_worship_misbaha_3d.png',
                  bgColor: row2Bg,
                  borderColor: row2BorderColor,
                  textColor: isDark ? Colors.white : const Color(0xFF0369A1),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TasbeehScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallDailyCard({
    required String title,
    required String imageAsset,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_stories,
                          size: 22,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediumActionCard({
    required String title,
    required String subtitle,
    required String imageAsset,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFBAE6FD),
                    width: 1.1,
                  ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.star,
                        size: 20,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDailyWorship(BuildContext context, String targetTitle, String categoryKey) {
    WorshipItem? matched;

    // Search in primary category first
    final catList = DataService().getItemsByCategory(categoryKey);
    for (final item in catList) {
      if (item.title.contains(targetTitle) || targetTitle.contains(item.title)) {
        matched = item;
        break;
      }
    }

    // Search in all categories as fallback
    if (matched == null) {
      for (final list in DataService().worshipData.values) {
        for (final item in list) {
          if (item.title.contains(targetTitle) || targetTitle.contains(item.title)) {
            matched = item;
            break;
          }
        }
        if (matched != null) break;
      }
    }

    if (matched != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorshipDetailScreen(item: matched!)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorshipScreen(initialCategoryKey: categoryKey)),
      );
    }
  }
}