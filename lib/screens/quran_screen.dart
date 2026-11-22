import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quran_chapter.dart';
import '../models/reciter.dart';
import '../providers/quran_provider.dart';
import '../services/hijri_date_service.dart';
import '../services/quran_api_service.dart';
import '../services/quran_audio_download_service.dart';
import '../widgets/quran_bookmarks_sheet.dart';
import '../widgets/ayah_number_symbol.dart';
import 'quran_reader_screen.dart';
import 'reciters_screen.dart';
import 'khatma_screen.dart';
import '../widgets/mini_audio_player.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  int _currentTab = 0; // 0: المصحف, 1: القراء, 2: الختمة
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<QuranSearchResult> _verseResults = [];
  bool _isSearchingVerses = false;
  int _searchFilterIndex = 0; // 0: الكل, 1: السور, 2: الآيات
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    QuranApiService.preloadAllSurahsInBackground();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    setState(() {
      _searchQuery = v;
    });
    _searchDebounceTimer?.cancel();
    final trimmed = v.trim();
    if (trimmed.isNotEmpty) {
      setState(() => _isSearchingVerses = true);
      _searchDebounceTimer = Timer(const Duration(milliseconds: 150), () async {
        final results = await QuranApiService.searchVerses(trimmed);
        if (mounted && _searchQuery.trim() == trimmed) {
          setState(() {
            _verseResults = results;
            _isSearchingVerses = false;
          });
        }
      });
    } else {
      setState(() {
        _verseResults = [];
        _isSearchingVerses = false;
      });
    }
  }

  String _formatTwoDigitArabic(int number) {
    final str = number.toString().padLeft(2, '0');
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return str.split('').map((c) {
      final idx = int.tryParse(c);
      return idx != null ? arabicDigits[idx] : c;
    }).join('');
  }

  void _showOfflineDownloadDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const reciters = ReciterItem.popularReciters;

    // Refresh counts when dialog opens
    QuranAudioDownloadService().refreshDownloadedCounts();

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<QuranAudioDownloadService>(
          builder: (context, downloadService, _) {
            final isDownloading = downloadService.isDownloading;
            final currentReciter = downloadService.currentReciter;
            final progressPct = (downloadService.progress * 100).toInt();
            final arabicPct = HijriDateService.toArabicDigits(progressPct);

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Title matching screenshot: "تحميل المصحف كاملاً"
                        const Text(
                          'تحميل المصحف كاملاً',
                          style: TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        // 2. Subtitle matching screenshot
                        Text(
                          'اختر القارئ لتحميل جميع سور القرآن الكريم للعمل بدون إنترنت:',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // 3. Active Download Live Progress Banner (if downloading)
                        if (isDownloading && currentReciter != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'جاري تحميل: ${currentReciter.name}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0284C7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '٪$arabicPct',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: downloadService.progress > 0 ? downloadService.progress : null,
                                    minHeight: 6,
                                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        downloadService.statusMessage ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            downloadService.isPaused
                                                ? Icons.play_arrow_rounded
                                                : Icons.pause_rounded,
                                            size: 20,
                                            color: const Color(0xFF0284C7),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: downloadService.isPaused ? 'استئناف' : 'إيقاف مؤقت',
                                          onPressed: () {
                                            if (downloadService.isPaused) {
                                              downloadService.resumeDownload();
                                            } else {
                                              downloadService.pauseDownload();
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'إلغاء التحميل',
                                          onPressed: () => downloadService.cancelDownload(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 4. List of Reciter Buttons matching screenshot exactly
                        ...reciters.map((r) {
                          final isThisDownloading = isDownloading && currentReciter?.id == r.id;
                          final isCompleted = downloadService.isReciterComplete(r.id);
                          final downloadedCount = downloadService.getCachedDownloadedCount(r.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            decoration: BoxDecoration(
                              color: isThisDownloading
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                                  : (isCompleted
                                      ? Colors.green.withValues(alpha: isDark ? 0.12 : 0.08)
                                      : (isDark ? const Color(0xFF283548) : const Color(0xFFEBF5FF))),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isThisDownloading
                                    ? const Color(0xFF0284C7)
                                    : (isCompleted
                                        ? Colors.green.withValues(alpha: 0.5)
                                        : Colors.transparent),
                                width: 1.2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  if (isThisDownloading) return;
                                  if (isCompleted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('مصحف ${r.name} محمل بالكامل وجاهز للعمل بدون إنترنت.'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  downloadService.startDownload(r);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Right / Status icon
                                      if (isThisDownloading)
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            value: downloadService.progress > 0 ? downloadService.progress : null,
                                            strokeWidth: 2.2,
                                            color: const Color(0xFF0284C7),
                                          ),
                                        )
                                      else if (isCompleted)
                                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                                      else if (downloadedCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${HijriDateService.toArabicDigits(downloadedCount)}/١١٤',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: Color(0xFF0284C7),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.cloud_download_outlined,
                                          size: 19,
                                          color: isDark ? Colors.white54 : const Color(0xFF0284C7),
                                        ),

                                      const SizedBox(width: 10),

                                      // Reciter Name (Centered)
                                      Expanded(
                                        child: Text(
                                          r.name.replaceAll(' - مرتل', ''),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted
                                                ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                                : (isDark ? Colors.white : const Color(0xFF1E3A5F)),
                                          ),
                                        ),
                                      ),

                                      // Delete button for completed/downloaded reciters
                                      if (isCompleted || downloadedCount > 0)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'حذف التلاوة لتحرير الذاكرة',
                                          onPressed: () {
                                            downloadService.deleteReciterAudio(r.id);
                                          },
                                        )
                                      else
                                        const SizedBox(width: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 6),

                        // 5. Cancel Button matching screenshot: "إلغاء"
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quran = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Active Tab Content
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  // Tab 0: المصحف الشريف (مطابق للصورة 1 بالضبط)
                  _buildMushafTab(context, isDark, quran),

                  // Tab 1: القراء (مطابق لتصميم القراء الجديد)
                  RecitersScreen(
                    onBackToMushaf: () => setState(() => _currentTab = 0),
                  ),

                  // Tab 2: الختمة (مطابق لتصميم الختمة الجديد)
                  KhatmaScreen(
                    onBackToMushaf: () => setState(() => _currentTab = 0),
                  ),
                ],
              ),
            ),

            // Floating Mini Audio Player Banner
            const MiniAudioPlayer(),

            // Custom 3-Tab Bottom Bar matching Image 1
            _buildCustomBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  /// واجهة المصحف الشريف وقائمة السور الكريمة (مطابقة للصورة 1)
  Widget _buildMushafTab(BuildContext context, bool isDark, QuranProvider quran) {
    const all = QuranChapter.allChapters;
    final filtered = _searchQuery.trim().isEmpty
        ? all
        : all.where((c) =>
            c.nameArabic.contains(_searchQuery.trim()) ||
            c.id.toString() == _searchQuery.trim() ||
            c.nameSimple.toLowerCase().contains(_searchQuery.trim().toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Bar matching Image 1:
        // Right: Back arrow + "القرآن الكريم"
        // Left: Cloud icon + Bookmark icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Right: Title & Back Arrow (Child 0 in RTL is on the Right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 24),
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'القرآن الكريم',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              // Left: Cloud download + Bookmark icons (Child 1 in RTL is on the Left)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<QuranAudioDownloadService>(
                    builder: (context, downloadService, _) {
                      if (downloadService.isDownloading) {
                        final pct = (downloadService.progress * 100).toInt();
                        final arabicPct = HijriDateService.toArabicDigits(pct);
                        return InkWell(
                          onTap: () => _showOfflineDownloadDialog(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF0284C7),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    value: downloadService.progress > 0 ? downloadService.progress : null,
                                    strokeWidth: 2,
                                    color: const Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '٪$arabicPct',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return IconButton(
                        icon: const Icon(Icons.cloud_download_outlined, size: 24),
                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                        tooltip: 'التحميل بدون إنترنت',
                        onPressed: () => _showOfflineDownloadDialog(context),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_rounded, size: 24),
                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                    tooltip: 'العلامات المحفوظة',
                    onPressed: () => QuranBookmarksSheet.show(context),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Search Bar matching Arabic RTL:
        // Search icon on right, text in middle, clear / mic button on left
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
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
            child: Row(
              children: [
                // Search icon on right (Child 0 in RTL is on the Right)
                Padding(
                  padding: const EdgeInsets.only(right: 14, left: 6),
                  child: Icon(
                    Icons.search,
                    color: isDark ? Colors.white54 : const Color(0xFF0284C7),
                    size: 20,
                  ),
                ),

                // TextField in middle
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textAlign: TextAlign.right,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سورة أو آية قرآنية...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    ),
                  ),
                ),

                // Clear button or Mic button in circle on left (Child 2 in RTL is on the Left)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  child: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF283548) : const Color(0xFFE0F2FE),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.mic, size: 18),
                            color: const Color(0xFF0284C7),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('يرجى كتابة اسم السورة أو جزء من الآية للبحث الفوري'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // Search active loading indicator
        if (_isSearchingVerses)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),

        // Filter Pills when search query is active
        if (_searchQuery.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSearchFilterChip(
                  label: 'الكل (${HijriDateService.toArabicDigits(filtered.length + _verseResults.length)})',
                  index: 0,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildSearchFilterChip(
                  label: 'السور (${HijriDateService.toArabicDigits(filtered.length)})',
                  index: 1,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildSearchFilterChip(
                  label: 'الآيات (${HijriDateService.toArabicDigits(_verseResults.length)})',
                  index: 2,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          const SizedBox(height: 12),
          // Section Title: "السور الكريمة"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              'السور الكريمة',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Content Area: Surahs or Search Results
        Expanded(
          child: _buildMushafContent(filtered, isDark),
        ),
      ],
    );
  }

  Widget _buildSearchFilterChip({
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _searchFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _searchFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildMushafContent(List<QuranChapter> filteredSurahs, bool isDark) {
    if (_searchQuery.trim().isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: filteredSurahs.length,
        itemBuilder: (context, index) => _buildSurahCard(filteredSurahs[index], isDark),
      );
    }

    final showSurahs = (_searchFilterIndex == 0 || _searchFilterIndex == 1) && filteredSurahs.isNotEmpty;
    final showAyahs = (_searchFilterIndex == 0 || _searchFilterIndex == 2) && _verseResults.isNotEmpty;

    if (!showSurahs && !showAyahs && !_isSearchingVerses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج مطابقة للبحث',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (showSurahs) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السور الكريمة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                ),
                Text(
                  '${HijriDateService.toArabicDigits(filteredSurahs.length)} سورة',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ...filteredSurahs.map((c) => _buildSurahCard(c, isDark)),
          const SizedBox(height: 12),
        ],

        if (showAyahs) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الآيات الكريمة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                ),
                Text(
                  '${HijriDateService.toArabicDigits(_verseResults.length)} آية',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ..._verseResults.map((result) => _buildAyahCard(result, isDark)),
        ],
      ],
    );
  }

  Widget _buildSurahCard(QuranChapter chapter, bool isDark) {
    final arabicNumber = _formatTwoDigitArabic(chapter.id);
    final versesCountArabic = HijriDateService.toArabicDigits(chapter.versesCount);
    final typeText = chapter.isMakki ? 'مكية' : 'مدنية';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.025),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuranReaderScreen(chapter: chapter),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Number Badge in soft light-blue rounded box on right
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2E40) : const Color(0xFFE0EDFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      arabicNumber,
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Name & Details on the right next to badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.nameArabic,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$typeText • $versesCountArabic آية',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle indicator on left
                Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAyahCard(QuranSearchResult result, bool isDark) {
    final chapter = QuranChapter.allChapters.firstWhere(
      (c) => c.id == result.surahId,
      orElse: () => QuranChapter.allChapters.first,
    );
    final ayahArabic = HijriDateService.toArabicDigits(result.ayahNumber);
    final juzArabic = HijriDateService.toArabicDigits(result.juzNumber);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.025),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuranReaderScreen(
                  chapter: chapter,
                  initialAyah: result.ayahNumber,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Info Bar: Surah Name badge + Ayah / Juz badge + Navigate arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'سورة ${result.surahName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2E40) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'الآية $ayahArabic • الجزء $juzArabic',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_back_ios_new,
                      size: 14,
                      color: Color(0xFF0284C7),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Verse Text with exact Quranic Uthmani drawing & AyahNumberSymbol
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: VerseItem.sanitizeUthmaniText(result.textUthmani.trim()),
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontFamilyFallback: const [
                              'UthmanicHafs',
                              'Amiri',
                              'Traditional Arabic',
                              'Cairo',
                              'sans-serif',
                            ],
                            fontSize: 19.5,
                            height: 2.3,
                            wordSpacing: 1.5,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const TextSpan(text: ' '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: AyahNumberSymbol(
                            ayahNumber: result.ayahNumber,
                            size: 26.0,
                            backgroundColor: Colors.transparent,
                            symbolColor: const Color(0xFFD4AF37),
                            numberColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// الشريط السفلي المخصص داخل نافذة القرآن مطابق للصورة 1 بالضبط
  Widget _buildCustomBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. المصحف (Selected) - on right in RTL
          _bottomNavItem(
            index: 0,
            icon: Icons.menu_book_rounded,
            label: 'المصحف',
            isDark: isDark,
          ),

          // 2. القراء
          _bottomNavItem(
            index: 1,
            icon: Icons.headphones_rounded,
            label: 'القراء',
            isDark: isDark,
          ),

          // 3. الختمة - on left in RTL
          _bottomNavItem(
            index: 2,
            icon: Icons.auto_stories_rounded,
            label: 'الختمة',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = (_currentTab == index);

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill capsule for active state
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD9EEF9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                ),
              ),

            const SizedBox(height: 2),

            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57))
                    : (isDark ? Colors.white60 : const Color(0xFF7A8B99)),
              ),
            ),

            // Small indicator line underneath selected tab
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 18,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 5.5),
          ],
        ),
      ),
    );
  }
}
