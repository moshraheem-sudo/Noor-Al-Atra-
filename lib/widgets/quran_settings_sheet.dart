import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quran_chapter.dart';
import '../providers/quran_provider.dart';
import '../services/hijri_date_service.dart';
import 'ayah_number_symbol.dart';

/// نافذة إعدادات القراءة والمصحف الشريف
/// تتيح التبديل الفوري بين «النمط الكلاسيكي الحالي» و «نمط مصحف المدينة بالرسم العثماني»
/// مع التحكم بحجم الخط، واختيار القارئ، والتحميل، والتنقل.
class QuranSettingsSheet extends StatefulWidget {
  final QuranChapter currentChapter;
  final int currentJuz;
  final bool isKhatmaActive;
  final VoidCallback onOpenReciters;
  final VoidCallback onDownloadSurah;
  final VoidCallback onOpenNavigation;
  final VoidCallback onOpenBookmarks;

  const QuranSettingsSheet({
    super.key,
    required this.currentChapter,
    required this.currentJuz,
    required this.isKhatmaActive,
    required this.onOpenReciters,
    required this.onDownloadSurah,
    required this.onOpenNavigation,
    required this.onOpenBookmarks,
  });

  static Future<void> show(
    BuildContext context, {
    required QuranChapter currentChapter,
    required int currentJuz,
    required bool isKhatmaActive,
    required VoidCallback onOpenReciters,
    required VoidCallback onDownloadSurah,
    required VoidCallback onOpenNavigation,
    required VoidCallback onOpenBookmarks,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.88,
        ),
        child: QuranSettingsSheet(
          currentChapter: currentChapter,
          currentJuz: currentJuz,
          isKhatmaActive: isKhatmaActive,
          onOpenReciters: onOpenReciters,
          onDownloadSurah: onDownloadSurah,
          onOpenNavigation: onOpenNavigation,
          onOpenBookmarks: onOpenBookmarks,
        ),
      ),
    );
  }

  @override
  State<QuranSettingsSheet> createState() => _QuranSettingsSheetState();
}

class _QuranSettingsSheetState extends State<QuranSettingsSheet> {
  double? _dragFontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quran = context.watch<QuranProvider>();
    final displayFontSize = _dragFontSize ?? quran.fontSize;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إعدادات قراءة المصحف',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'سورة ${widget.currentChapter.nameArabic} • الجزء ${HijriDateService.toArabicDigits(widget.currentJuz)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. التحكم بحجم الخط
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16202C) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'حجم خط المصحف:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          '${HijriDateService.toArabicDigits(displayFontSize.toInt())} نقطة',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF0284C7)),
                          onPressed: () {
                            final next = (displayFontSize - 1).clamp(16.0, 36.0);
                            setState(() => _dragFontSize = null);
                            quran.setFontSize(next);
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: displayFontSize,
                            min: 16.0,
                            max: 36.0,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (v) {
                              setState(() => _dragFontSize = v);
                            },
                            onChangeEnd: (v) {
                              _dragFontSize = null;
                              quran.setFontSize(v);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0284C7)),
                          onPressed: () {
                            final next = (displayFontSize + 1).clamp(16.0, 36.0);
                            setState(() => _dragFontSize = null);
                            quran.setFontSize(next);
                          },
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                style: TextStyle(
                                  fontSize: displayFontSize * 0.88,
                                  fontFamily: quran.isUthmanicMode ? 'AmiriQuran' : 'Cairo',
                                  fontFamilyFallback: const [
                                    'UthmanicHafs',
                                    'Amiri',
                                    'Traditional Arabic',
                                    'sans-serif',
                                  ],
                                  height: 1.8,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: AyahNumberSymbol(
                                  ayahNumber: 1,
                                  size: (displayFontSize * 1.25).clamp(20.0, 48.0),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 5. Select Reciter Card
              _settingsTile(
                isDark: isDark,
                icon: Icons.record_voice_over_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'القارئ: ${quran.selectedReciter.name}',
                subtitle: 'تحديد القارئ المعتمد لتلاوة وتحميل السورة',
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'تغيير',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenReciters();
                },
              ),

              const SizedBox(height: 10),

              // 6. Download Full Surah MP3 Card
              _settingsTile(
                isDark: isDark,
                icon: Icons.cloud_download_outlined,
                iconColor: const Color(0xFF059669),
                title: 'تحميل صوت كامل للسورة (MP3)',
                subtitle: 'حفظ تلاوة سورة ${widget.currentChapter.nameArabic} للاستماع أوفلاين',
                trailingWidget: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF059669)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDownloadSurah();
                },
              ),

              const SizedBox(height: 10),

              // 7. Navigation: Juz List in Khatma mode vs Surah Index in normal mode
              _settingsTile(
                isDark: isDark,
                icon: widget.isKhatmaActive ? Icons.auto_stories_rounded : Icons.menu_book_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: widget.isKhatmaActive ? 'أجزاء الختمة القرآنية (٣٠ جزء)' : 'فهرس السور الكريمة',
                subtitle: widget.isKhatmaActive
                    ? 'الانتقال بين أجزاء الختمة ومتابعة تقدمك'
                    : 'الانتقال إلى أي سورة أخرى من سور القرآن الـ ١١٤',
                trailingWidget: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF7C3AED)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenNavigation();
                },
              ),

              const SizedBox(height: 10),

              // 8. Saved Bookmarks List Card
              _settingsTile(
                isDark: isDark,
                icon: Icons.bookmark_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'العلامات المحفوظة',
                subtitle: 'عرض كافة الآيات المحفوظة والانتقال إليها',
                trailingWidget: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFD97706)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenBookmarks();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _settingsTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailingWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16202C) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            trailingWidget,
          ],
        ),
      ),
    );
  }
}
