import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/quran_chapter.dart';
import '../../models/tafseer_model.dart';
import '../../repositories/tafseer_repository.dart';
import '../../services/hijri_date_service.dart';
import '../../services/quran_api_service.dart';
import 'tafseer_comparison_screen.dart';

class TafseerReaderScreen extends StatefulWidget {
  final TafseerType type;
  final int surahNumber;
  final int? initialAyahNumber;

  const TafseerReaderScreen({
    super.key,
    required this.type,
    required this.surahNumber,
    this.initialAyahNumber,
  });

  @override
  State<TafseerReaderScreen> createState() => _TafseerReaderScreenState();
}

class _TafseerReaderScreenState extends State<TafseerReaderScreen> {
  late TafseerType _currentType;
  late int _surahNumber;
  int _currentAyah = 1;

  List<TafseerEntry> _entries = [];
  Map<int, String> _versesMap = {};
  bool _isLoading = true;
  bool _isDownloaded = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  double _fontSize = 18.0;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _currentType = widget.type;
    _surahNumber = widget.surahNumber;
    _currentAyah = widget.initialAyahNumber ?? 1;
    _fontSize = TafseerRepository().getFontSize();
    _loadSurahData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahData() async {
    setState(() => _isLoading = true);

    try {
      final ch = QuranChapter.getChapterById(_surahNumber);
      final surahName = ch?.nameArabic ?? '$_surahNumber';

      // 1. Load Quran verses for this Surah
      final verses = await QuranApiService.getVerses(_surahNumber);
      final Map<int, String> vMap = {};
      for (int i = 0; i < verses.length; i++) {
        vMap[i + 1] = verses[i].textUthmani;
      }

      // 1. Check if downloaded
      final downloaded = await TafseerRepository().isDownloaded(_currentType);
      if (!downloaded) {
        if (mounted) {
          setState(() {
            _isDownloaded = false;
            _entries = [];
            _versesMap = vMap;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Load Tafseer entries from SQLite
      final entries = await TafseerRepository().getTafseerEntriesForSurah(_currentType, _surahNumber);

      _itemKeys.clear();
      for (int i = 0; i < entries.length; i++) {
        _itemKeys[i] = GlobalKey();
      }

      if (mounted) {
        setState(() {
          _entries = entries;
          _versesMap = vMap;
          _isLoading = false;
        });

        // Save last reading position
        TafseerRepository().saveLastReadingPosition(
          type: _currentType,
          surahNumber: _surahNumber,
          ayahNumber: _currentAyah,
          surahName: surahName,
        );

        // Scroll to initial Ayah if specified
        if (widget.initialAyahNumber != null && widget.initialAyahNumber! > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAyah(_currentAyah);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading surah tafseer: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchTafseerType(TafseerType newType) {
    if (_currentType == newType) return;
    setState(() {
      _currentType = newType;
    });
    _loadSurahData();
  }

  void _goToSurah(int surahNum, {int initialAyah = 1}) {
    if (surahNum < 1 || surahNum > 114) return;
    setState(() {
      _surahNumber = surahNum;
      _currentAyah = initialAyah;
    });
    _loadSurahData();
  }

  void _scrollToAyah(int ayah) {
    final entryIdx = _entries.indexWhere((e) => e.containsAyah(ayah));
    if (entryIdx != -1) {
      final key = _itemKeys[entryIdx];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: 0.1,
        );
      }
    }
  }

  void _showAyahPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ch = QuranChapter.getChapterById(_surahNumber);
    if (ch == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'انتقال إلى آية من سورة ${ch.nameArabic} (${HijriDateService.toArabicDigits(ch.versesCount)} آية)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: ch.versesCount,
                  itemBuilder: (context, idx) {
                    final a = idx + 1;
                    final isCurrent = a == _currentAyah;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _currentAyah = a);
                        _scrollToAyah(a);
                        final ch = QuranChapter.getChapterById(_surahNumber);
                        if (ch != null) {
                          TafseerRepository().saveLastReadingPosition(
                            type: _currentType,
                            surahNumber: _surahNumber,
                            ayahNumber: a,
                            surahName: ch.nameArabic,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF059669)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          HijriDateService.toArabicDigits(a),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                          ),
                        ),
                      ),
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

  void _showFontSizeDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('حجم خط التفسير', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nالحمد لله رب العالمين',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: _fontSize, fontFamily: 'Amiri'),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 30.0,
                    divisions: 8,
                    activeColor: const Color(0xFF059669),
                    label: _fontSize.toInt().toString(),
                    onChanged: (val) {
                      setDialogState(() => _fontSize = val);
                      setState(() => _fontSize = val);
                      TafseerRepository().setFontSize(val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('تم', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ch = QuranChapter.getChapterById(_surahNumber);
    final surahName = ch?.nameArabic ?? '$_surahNumber';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'سورة $surahName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${ch?.isMakki == true ? "مكية" : "مدنية"} • ${HijriDateService.toArabicDigits(ch?.versesCount ?? 0)} آية',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'حجم الخط',
            onPressed: () => _showFontSizeDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'مقارنة التفسيرين',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TafseerComparisonScreen(
                    initialSurahNumber: _surahNumber,
                    initialAyahNumber: _currentAyah,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Switcher Tab Pill: [الميزان] | [الصافي] + Quick Ayah jump
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Toggle Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab(TafseerType.almizan, 'الميزان (الطباطبائي)', isDark),
                          _buildTypeTab(TafseerType.safi, 'الصافي (الكاشاني)', isDark),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Ayah Selector button
                  InkWell(
                    onTap: () => _showAyahPicker(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            'الآية ${HijriDateService.toArabicDigits(_currentAyah)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reading Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
                  : !_isDownloaded
                      ? _buildDownloadPrompt(isDark)
                      : _entries.isEmpty
                          ? const Center(child: Text('لا تتوفر نصوص تفسيرية لهذه السورة'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                final isFavorite = TafseerRepository().isFavorite(
                                  _currentType,
                                  entry.surahNumber,
                                  entry.startAyah,
                                );

                                return _buildEntryCard(
                                  index: index,
                                  entry: entry,
                                  isDark: isDark,
                                  isFavorite: isFavorite,
                                );
                              },
                            ),
            ),

            // Bottom Navigation Strip: Prev Surah / Next Surah (With SafeArea to avoid bottom gesture bar overlap)
            SafeArea(
              top: false,
              child: _buildSurahBottomNav(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(TafseerType type, String title, bool isDark) {
    final isSelected = _currentType == type;
    return Expanded(
      child: InkWell(
        onTap: () => _switchTafseerType(type),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (type == TafseerType.almizan ? const Color(0xFF0284C7) : const Color(0xFF059669))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard({
    required int index,
    required TafseerEntry entry,
    required bool isDark,
    required bool isFavorite,
  }) {
    final isMizan = entry.type == TafseerType.almizan;

    // Collect verses text for this entry range
    final versesBuffer = StringBuffer();
    for (int a = entry.startAyah; a <= entry.endAyah; a++) {
      final vText = _versesMap[a];
      if (vText != null && vText.isNotEmpty) {
        versesBuffer.write('$vText ﴿${HijriDateService.toArabicDigits(a)}﴾  ');
      }
    }
    final quranicText = versesBuffer.toString().trim();

    return Container(
      key: _itemKeys[index],
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.type.shortName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سورة ${entry.surahName} • ${entry.ayahRangeText}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                // Favorite Button
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isFavorite ? const Color(0xFFD4AF37) : (isDark ? Colors.white54 : Colors.grey),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isFavorite ? 'إزالة من المفضلة' : 'حفظ في المفضلة',
                  onPressed: () async {
                    final added = await TafseerRepository().toggleFavorite(
                      type: entry.type,
                      surahNumber: entry.surahNumber,
                      ayahNumber: entry.startAyah,
                      startAyah: entry.startAyah,
                      endAyah: entry.endAyah,
                      surahName: entry.surahName,
                      fullContent: entry.content,
                    );
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            added
                                ? 'تمت إضافة التفسير إلى المفضلة ⭐️'
                                : 'تمت إزالة التفسير من المفضلة',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Quranic Verses Container
          if (quranicText.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A2634), const Color(0xFF16202C)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  width: 1.1,
                ),
              ),
              child: Text(
                quranicText,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 17.5,
                  height: 1.95,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                  fontFamily: 'UthmanicHafs',
                ),
              ),
            ),

          // Tafseer Content (منضدة ككشيدة من الجوانب)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SelectableText(
              _cleanTafseerText(entry.content),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.9,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                fontFamily: 'Amiri',
              ),
            ),
          ),

          // Actions Footer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Compare with other Tafseer
                OutlinedButton.icon(
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: const Text('مقارنة التفسيرين', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669), width: 1.1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TafseerComparisonScreen(
                          initialSurahNumber: entry.surahNumber,
                          initialAyahNumber: entry.startAyah,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),

                // Copy Button
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 19),
                  tooltip: 'نسخ نص التفسير',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '${entry.content}\n\n[المصدر: ${entry.type.displayName} - سورة ${entry.surahName}: ${entry.ayahRangeText}]',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم نسخ تفسير ${entry.type.shortName} إلى الحافظة 📋')),
                    );
                  },
                ),

                // Share Button
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 19),
                  tooltip: 'مشاركة التفسير',
                  onPressed: () {
                    Share.share(
                      '${entry.content}\n\n[المصدر: ${entry.type.displayName} - سورة ${entry.surahName}: ${entry.ayahRangeText}]',
                      subject: 'تفسير سورة ${entry.surahName} (${entry.ayahRangeText})',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahBottomNav(bool isDark) {
    final prevCh = _surahNumber > 1 ? QuranChapter.getChapterById(_surahNumber - 1) : null;
    final nextCh = _surahNumber < 114 ? QuranChapter.getChapterById(_surahNumber + 1) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Surah (In RTL, prev is on right / forward icon)
          if (prevCh != null)
            TextButton.icon(
              onPressed: () => _goToSurah(prevCh.id),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              label: Text(
                'سورة ${prevCh.nameArabic}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            )
          else
            const SizedBox(width: 80),

          // Surah badge indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${HijriDateService.toArabicDigits(_surahNumber)} / ١١٤',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
          ),

          // Next Surah
          if (nextCh != null)
            TextButton.icon(
              onPressed: () => _goToSurah(nextCh.id),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: Text(
                'سورة ${nextCh.nameArabic}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildDownloadPrompt(bool isDark) {
    final themeColor = _currentType == TafseerType.almizan ? const Color(0xFF0284C7) : const Color(0xFF059669);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_download_rounded, size: 48, color: themeColor),
            ),
            const SizedBox(height: 16),
            Text(
              '${_currentType.displayName} غير محمل حالياً',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'حجم الملف: ${_currentType.downloadSizeText} فقط • تحميل لمرة واحدة للاستخدام دائماً بدون إنترنت',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            if (_isDownloading)
              SizedBox(
                width: 240,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: themeColor.withValues(alpha: 0.2),
                      color: themeColor,
                      borderRadius: BorderRadius.circular(6),
                      minHeight: 7,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'جاري التحميل وفك الضغط: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _downloadCurrentType,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('تحميل التفسير الآن (${_currentType.downloadSizeText})', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCurrentType() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await TafseerRepository().downloadTafseer(
        _currentType,
        onProgress: (p, received, total) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        await _loadSurahData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('تعذر تحميل التفسير: $e'),
          ),
        );
      }
    }
  }

  String _cleanTafseerText(String raw) {
    return raw
        .replaceAll(RegExp(r'^#+ ', multiLine: true), '')
        .replaceAll('****', '\n───── ✦ ─────\n')
        .replaceAll('```arabic', '')
        .replaceAll('```', '');
  }
}
