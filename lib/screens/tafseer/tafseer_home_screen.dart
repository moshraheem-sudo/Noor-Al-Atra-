import 'package:flutter/material.dart';
import '../../models/tafseer_model.dart';
import '../../repositories/tafseer_repository.dart';
import 'tafseer_about_sheet.dart';
import 'tafseer_comparison_screen.dart';
import 'tafseer_favorites_screen.dart';
import 'tafseer_muqadimah_screen.dart';
import 'tafseer_reader_screen.dart';
import 'tafseer_search_screen.dart';
import 'tafseer_surah_list_screen.dart';

class TafseerHomeScreen extends StatefulWidget {
  const TafseerHomeScreen({super.key});

  @override
  State<TafseerHomeScreen> createState() => _TafseerHomeScreenState();
}

class _TafseerHomeScreenState extends State<TafseerHomeScreen> {
  TafseerReadingPosition? _lastPosition;
  bool _isLoading = true;

  bool _isMizanDownloaded = false;
  bool _isSafiDownloaded = false;
  TafseerType? _downloadingType;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await TafseerRepository().init();
      final pos = TafseerRepository().getLastReadingPosition();
      final mizanDl = await TafseerRepository().isDownloaded(TafseerType.almizan);
      final safiDl = await TafseerRepository().isDownloaded(TafseerType.safi);
      if (mounted) {
        setState(() {
          _lastPosition = pos;
          _isMizanDownloaded = mizanDl;
          _isSafiDownloaded = safiDl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tafseer initial data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startDownload(TafseerType type) async {
    if (_downloadingType != null) return;
    setState(() {
      _downloadingType = type;
      _downloadProgress = 0.0;
    });

    try {
      await TafseerRepository().downloadTafseer(
        type,
        onProgress: (p, received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = p;
            });
          }
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text('تم اكتمال تحميل ${type.shortName} بنجاح ✓'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('تعذر تحميل التفسير. يرجى التحقق من الاتصال بالإنترنت: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingType = null;
          _downloadProgress = 0.0;
        });
        await _loadInitialData();
      }
    }
  }

  Future<void> _confirmDelete(TafseerType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('حذف ${type.shortName}؟'),
          content: Text('سيتم حذف ملف البيانات من الهاتف لتوفير مساحة التخزين (${type.downloadSizeText}). يمكنك إعادة تحميله في أي وقت.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف الملف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await TafseerRepository().deleteTafseer(type);
      await _loadInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف ملف ${type.shortName} بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'تفسير القرآن الكريم',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.5),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'عن التفاسير والترخيص',
            onPressed: () => TafseerAboutSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'المفضلة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TafseerFavoritesScreen()),
              ).then((_) => _loadInitialData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'البحث في التفاسير',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TafseerSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF059669)),
                    SizedBox(height: 16),
                    Text('جاري فتح مكتبة التفسير...', style: TextStyle(fontSize: 13)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Resume Last Reading Card (if available)
                    if (_lastPosition != null) ...[
                      _buildResumeReadingCard(context, isDark, _lastPosition!),
                      const SizedBox(height: 14),
                    ],

                    // 2. Search Shortcut Card
                    _buildQuickSearchCard(context, isDark),
                    const SizedBox(height: 16),

                    // Section Title: "التفاسير المعتمدة"
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'التفاسير المعتمدة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Tafseer Al-Mizan Card
                    _buildMainTafseerCard(
                      context: context,
                      isDark: isDark,
                      type: TafseerType.almizan,
                      themeColor: const Color(0xFF0284C7),
                      isDownloaded: _isMizanDownloaded,
                      isDownloading: _downloadingType == TafseerType.almizan,
                      downloadProgress: _downloadProgress,
                    ),
                    const SizedBox(height: 14),

                    // 4. Tafseer Al-Safi Card
                    _buildMainTafseerCard(
                      context: context,
                      isDark: isDark,
                      type: TafseerType.safi,
                      themeColor: const Color(0xFF059669),
                      isDownloaded: _isSafiDownloaded,
                      isDownloading: _downloadingType == TafseerType.safi,
                      downloadProgress: _downloadProgress,
                    ),
                    const SizedBox(height: 16),

                    // 5. Comparison & Features Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            isDark: isDark,
                            icon: Icons.compare_arrows_rounded,
                            iconColor: const Color(0xFFD4AF37),
                            title: 'مقارنة التفسيرين',
                            subtitle: 'مقارنة الميزان والصافي معاً',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TafseerComparisonScreen(),
                                ),
                              ).then((_) => _loadInitialData());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            isDark: isDark,
                            icon: Icons.bookmark_added_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            title: 'التفاسير المحفوظة',
                            subtitle: 'قائمة الآيات المفضلة',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TafseerFavoritesScreen(),
                                ),
                              ).then((_) => _loadInitialData());
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResumeReadingCard(BuildContext context, bool isDark, TafseerReadingPosition pos) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A5F), const Color(0xFF0F2744)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TafseerReaderScreen(
                  type: pos.type,
                  surahNumber: pos.surahNumber,
                  initialAyahNumber: pos.ayahNumber,
                ),
              ),
            ).then((_) => _loadInitialData());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_edu_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متابعة القراءة • ${pos.type.shortName}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'سورة ${pos.surahName} : الآية ${pos.ayahNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF0284C7)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSearchCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TafseerSearchScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ابحث في التفسير أو باسم السورة والآية...',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'بحث',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTafseerCard({
    required BuildContext context,
    required bool isDark,
    required TafseerType type,
    required Color themeColor,
    required bool isDownloaded,
    required bool isDownloading,
    required double downloadProgress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                bottom: BorderSide(
                  color: themeColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: themeColor, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        type.shortAuthor,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                ),
                // Muqadimah Icon Button
                IconButton(
                  icon: const Icon(Icons.menu_book_outlined, size: 20),
                  tooltip: 'المقدمة الأصلية',
                  color: themeColor,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TafseerMuqadimahScreen(type: type),
                      ),
                    );
                  },
                ),
                if (isDownloaded)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red.withValues(alpha: 0.7)),
                    tooltip: 'حذف لتوفير مساحة',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _confirmDelete(type),
                  ),
              ],
            ),
          ),

          // Body: Badges + Concise Summary (No long descriptions)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Wrap for Badges (Prevents ANY overflow)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type == TafseerType.almizan ? '٢٠ مجلداً • تحليلي' : '٥ مجلدات • روائي',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDownloaded
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDownloaded ? Icons.offline_pin_rounded : Icons.cloud_download_rounded,
                            size: 13,
                            color: isDownloaded ? Colors.green : Colors.amber.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDownloaded
                                ? 'متاح بدون إنترنت'
                                : 'تنزيل اختياري (${type.downloadSizeText})',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDownloaded ? Colors.green : Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  type.briefSummary,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          // Action Button Area
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: isDownloading
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: downloadProgress > 0 ? downloadProgress : null,
                        backgroundColor: themeColor.withValues(alpha: 0.2),
                        color: themeColor,
                        borderRadius: BorderRadius.circular(6),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'جاري التحميل وفك الضغط: ${(downloadProgress * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (isDownloaded) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TafseerSurahListScreen(initialType: type),
                                ),
                              ).then((_) => _loadInitialData());
                            } else {
                              _startDownload(type);
                            }
                          },
                          icon: Icon(
                            isDownloaded ? Icons.format_list_bulleted_rounded : Icons.download_rounded,
                            size: 17,
                          ),
                          label: Text(
                            isDownloaded
                                ? 'تصفح السور (١١٤)'
                                : 'تحميل التفسير (${type.downloadSizeText})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
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

  Widget _buildActionTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(height: 8),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
