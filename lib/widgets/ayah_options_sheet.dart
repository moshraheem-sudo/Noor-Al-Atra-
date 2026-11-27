import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quran_chapter.dart';
import '../models/quran_sajdah.dart';
import '../models/tafseer_model.dart';
import '../screens/tafseer/tafseer_reader_screen.dart';
import 'quran_verse_share_sheet.dart';

/// نافذة خيارات الآية (ModalBottomSheet)
/// توفر استماع منفرد، استماع متواصل، نسخ، مشاركة نص/بطاقة، حفظ العلامة، ومشاركة ملف الصوت
class AyahOptionsSheet extends StatelessWidget {
  final QuranChapter chapter;
  final int ayahNum;
  final String verseText;
  final String reciterName;
  final String reciterPath;
  final int juzNum;
  final VoidCallback onPlaySingle;
  final VoidCallback onPlayContinuous;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  const AyahOptionsSheet({
    super.key,
    required this.chapter,
    required this.ayahNum,
    required this.verseText,
    required this.reciterName,
    required this.reciterPath,
    required this.juzNum,
    required this.onPlaySingle,
    required this.onPlayContinuous,
    this.isBookmarked = false,
    required this.onBookmark,
  });

  static void show(
    BuildContext context, {
    required QuranChapter chapter,
    required int ayahNum,
    required String verseText,
    required String reciterName,
    required String reciterPath,
    required int juzNum,
    required VoidCallback onPlaySingle,
    required VoidCallback onPlayContinuous,
    bool isBookmarked = false,
    required VoidCallback onBookmark,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AyahOptionsSheet(
        chapter: chapter,
        ayahNum: ayahNum,
        verseText: verseText,
        reciterName: reciterName,
        reciterPath: reciterPath,
        juzNum: juzNum,
        onPlaySingle: onPlaySingle,
        onPlayContinuous: onPlayContinuous,
        isBookmarked: isBookmarked,
        onBookmark: onBookmark,
      ),
    );
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? arabicDigits[d] : c;
    }).join();
  }

  String get _audioUrl {
    final s = chapter.id.toString().padLeft(3, '0');
    final a = ayahNum.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciterPath/$s$a.mp3';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arabicAyah = _toArabicDigits(ayahNum);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Header: Surah & Ayah Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFD4AF37),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'سورة ${chapter.nameArabic} - الآية $arabicAyah',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Sajdah Info Banner if applicable
              Builder(builder: (context) {
                final sajdah = QuranSajdahInfo.getSajdah(chapter.id, ayahNum);
                if (sajdah == null) return const SizedBox.shrink();
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sajdah.isObligatory
                        ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.22 : 0.12)
                        : const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.22 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sajdah.isObligatory ? const Color(0xFFEF4444) : const Color(0xFFD4AF37),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: sajdah.isObligatory ? const Color(0xFFEF4444) : const Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('۩', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sajdah.isObligatory ? 'سجدة تلاوة واجبة (عزائم)' : 'سجدة تلاوة مستحبة',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: sajdah.isObligatory ? const Color(0xFFEF4444) : (isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309)),
                              ),
                            ),
                            Text(
                              sajdah.isObligatory
                                  ? 'يجب السجود لله تعالى عند قراءة أو سماع هذه الآية المباركة'
                                  : 'يستحب السجود لله تعالى عند قراءة أو سماع هذه الآية المباركة',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // 4. Action Options List (6 Required Options)
              // 1) استماع لهذه الآية
              _buildOptionTile(
                context: context,
                isDark: isDark,
                icon: Icons.play_circle_outline_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'استماع لهذه الآية',
                subtitle: 'تلاوة منفردة للآية بصوت $reciterName',
                onTap: () {
                  Navigator.pop(context);
                  onPlaySingle();
                },
              ),

              // 2) استماع متواصل من هذه الآية
              _buildOptionTile(
                context: context,
                isDark: isDark,
                icon: Icons.playlist_play_rounded,
                iconColor: const Color(0xFFD4AF37),
                title: 'استماع متواصل من هذه الآية',
                subtitle: 'بدء التلاوة المستمرة مع التظليل والانتقال التلقائي',
                onTap: () {
                  Navigator.pop(context);
                  onPlayContinuous();
                },
              ),

              // 3) نسخ نص الآية للذاكرة
              _buildOptionTile(
                context: context,
                isDark: isDark,
                icon: Icons.copy_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'نسخ نص الآية',
                subtitle: 'نسخ الآية الكريمة إلى الحافظة',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(
                    text: '$verseText ﴿$arabicAyah﴾ [سورة ${chapter.nameArabic}: $ayahNum]',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0D9488),
                      content: Text('تم نسخ الآية الكريمة إلى الحافظة بنجاح 📋'),
                    ),
                  );
                },
              ),

              // 4) مشاركة الآية كصورة
              _buildOptionTile(
                context: context,
                isDark: isDark,
                icon: Icons.share_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'مشاركة الآية كصورة',
                subtitle: 'تصميم بطاقة مصحف فاخرة ومشاركتها كصورة أو نص',
                onTap: () {
                  Navigator.pop(context);
                  QuranVerseShareSheet.show(
                    context,
                    surahName: chapter.nameArabic,
                    ayahNum: ayahNum,
                    ayahText: verseText,
                    juz: juzNum,
                  );
                },
              ),

              // 5) حفظ في العلامات المرجعية / إزالة من العلامات
              _buildOptionTile(
                context: context,
                isDark: isDark,
                icon: isBookmarked ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
                iconColor: isBookmarked ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                title: isBookmarked ? 'إزالة من العلامات المرجعية' : 'حفظ في العلامات المرجعية',
                subtitle: isBookmarked
                    ? 'حذف الآية من قائمة العلامات المحفوظة'
                    : 'تثبيت علامة القراءة الحالية عند هذه الآية وتظليلها',
                onTap: () {
                  Navigator.pop(context);
                  onBookmark();
                },
              ),

              // 6) مشاركة الآية كصوت
              _buildOptionTile(
                context: context,
                isDark: isDark,
                icon: Icons.audio_file_outlined,
                iconColor: const Color(0xFF2563EB),
                title: 'مشاركة الآية كصوت',
                subtitle: 'تحميل ومشاركة ملف التلاوة الصوتية للآية بصوت $reciterName',
                onTap: () {
                  Navigator.pop(context);
                  _shareAyahAudio(context);
                },
              ),

              // 7) تفسير الآية (الميزان والصافي)
              _buildOptionTile(
                context: context,
                isDark: isDark,
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF059669),
                title: 'تفسير الآية',
                subtitle: 'عرض تفسير الآية في تفسير الميزان أو تفسير الصافي',
                onTap: () {
                  Navigator.pop(context);
                  _showTafseerChoiceDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTafseerChoiceDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF059669), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر التفسير المعتمد',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'سورة ${chapter.nameArabic} • الآية ${_toArabicDigits(ayahNum)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Choice 1: الميزان في تفسير القرآن
                _buildTafseerChoiceTile(
                  context: context,
                  isDark: isDark,
                  type: TafseerType.almizan,
                  themeColor: const Color(0xFF0284C7),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TafseerReaderScreen(
                          type: TafseerType.almizan,
                          surahNumber: chapter.id,
                          initialAyahNumber: ayahNum,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Choice 2: تفسير الصافي
                _buildTafseerChoiceTile(
                  context: context,
                  isDark: isDark,
                  type: TafseerType.safi,
                  themeColor: const Color(0xFF059669),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TafseerReaderScreen(
                          type: TafseerType.safi,
                          surahNumber: chapter.id,
                          initialAyahNumber: ayahNum,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTafseerChoiceTile({
    required BuildContext context,
    required bool isDark,
    required TafseerType type,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: themeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.author,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: themeColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareAyahAudio(BuildContext context) async {
    final arabicAyah = _toArabicDigits(ayahNum);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'جارٍ تجهيز وتحميل تلاوة الآية ($arabicAyah) كملف صوتي... 🎧',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final safeReciter = reciterPath.replaceAll(RegExp(r'[^\w\d]'), '_');
      final s = chapter.id.toString().padLeft(3, '0');
      final a = ayahNum.toString().padLeft(3, '0');
      final audioFile = File('${tempDir.path}/ayah_${s}_${a}_$safeReciter.mp3');

      if (!await audioFile.exists() || await audioFile.length() < 1024) {
        final response = await http.get(Uri.parse(_audioUrl));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await audioFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('تعذر تحميل الملف الصوتي (${response.statusCode})');
        }
      }

      messenger.hideCurrentSnackBar();

      await Share.shareXFiles(
        [
          XFile(
            audioFile.path,
            mimeType: 'audio/mpeg',
            name: 'سورة_${chapter.nameArabic}_آية_$arabicAyah.mp3',
          ),
        ],
        text: 'تلاوة سورة ${chapter.nameArabic} - الآية $arabicAyah بصوت $reciterName 🎧\n﴿ $verseText ﴾',
        subject: 'تلاوة سورة ${chapter.nameArabic} - الآية $arabicAyah',
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('تعذر تحميل ومشاركة ملف الصوت: $e'),
        ),
      );
    }
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF16202C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
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
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
