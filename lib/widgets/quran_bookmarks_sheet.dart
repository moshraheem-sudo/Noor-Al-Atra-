import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quran_bookmark.dart';
import '../models/quran_chapter.dart';
import '../providers/quran_provider.dart';
import '../screens/quran_reader_screen.dart';
import '../services/hijri_date_service.dart';
import 'ayah_number_symbol.dart';

class QuranBookmarksSheet extends StatelessWidget {
  final void Function(QuranBookmark bookmark)? onSelectBookmark;

  const QuranBookmarksSheet({super.key, this.onSelectBookmark});

  static void show(
    BuildContext context, {
    void Function(QuranBookmark bookmark)? onSelectBookmark,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => QuranBookmarksSheet(onSelectBookmark: onSelectBookmark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quran = context.watch<QuranProvider>();
    final bookmarks = quran.bookmarks;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Header matching screenshot: Title on right, Count badge on left
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Right: Title (Child 0 in RTL)
                    Text(
                      'العلامات المحفوظة',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),

                    // Left: Count Badge (Child 1 in RTL)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${HijriDateService.toArabicDigits(bookmarks.length)} علامة',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Bookmarks List or Empty State
              if (bookmarks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF283548) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bookmark_border_rounded,
                          size: 38,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد علامات مرجعية محفوظة حتى الآن',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يمكنك حفظ أي آية بالضغط عليها داخل السورة واختيار "حفظ في العلامات المرجعية"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final b = bookmarks[index];
                      final ayahNumStr = HijriDateService.toArabicDigits(b.ayahNum);

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16202C) : const Color(0xFFFBFDFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(context);
                              if (onSelectBookmark != null) {
                                onSelectBookmark!(b);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuranReaderScreen(
                                      surahId: b.surahId,
                                      initialAyah: b.ayahNumber,
                                      initialPage: b.pageNumber,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Row: Surah & Ayah on right, Delete trash icon on left
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Right: Title (e.g. "البقرة — الآية 5")
                                      Text(
                                        '${b.surahName} — الآية $ayahNumStr',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),

                                      // Left: Delete trash icon (matches red trash in screenshot)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 19,
                                          color: Colors.redAccent,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'حذف من العلامات المحفوظة',
                                        onPressed: () {
                                          quran.removeBookmark(b.surahId, b.ayahNum);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تم حذف علامة سورة ${b.surahName} الآية $ayahNumStr'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 7),

                                  // Middle: Verse Text with authentic Mushaf Uthmani drawing
                                  Builder(
                                    builder: (context) {
                                      final rawVerse = b.exactVerseText.isNotEmpty ? b.exactVerseText : b.verseText;
                                      final displayVerse = VerseItem.sanitizeUthmaniText(rawVerse.trim());

                                      return Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                                : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF334155).withValues(alpha: 0.5)
                                                  : const Color(0xFFE2E8F0),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: displayVerse,
                                                  style: TextStyle(
                                                    fontFamily: 'AmiriQuran',
                                                    fontFamilyFallback: const [
                                                      'UthmanicHafs',
                                                      'Amiri',
                                                      'Traditional Arabic',
                                                      'Cairo',
                                                      'sans-serif',
                                                    ],
                                                    fontSize: 18.0,
                                                    height: 2.2,
                                                    wordSpacing: 1.5,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.normal,
                                                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const TextSpan(text: ' '),
                                                WidgetSpan(
                                                  alignment: PlaceholderAlignment.middle,
                                                  child: AyahNumberSymbol(
                                                    ayahNumber: b.ayahNumber,
                                                    size: 24.0,
                                                    backgroundColor: Colors.transparent,
                                                    symbolColor: const Color(0xFFD4AF37),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 8),

                                  // Bottom Row: Formatted Date/Time matching screenshot:
                                  // "تاريخ الحفظ: 27 سبتمبر 2026 • 05:35 ص"
                                  Text(
                                    b.formattedDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }
}
