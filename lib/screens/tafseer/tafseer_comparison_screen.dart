import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/quran_chapter.dart';
import '../../models/tafseer_model.dart';
import '../../repositories/tafseer_repository.dart';
import '../../services/hijri_date_service.dart';
import '../../services/quran_api_service.dart';

class TafseerComparisonScreen extends StatefulWidget {
  final int initialSurahNumber;
  final int initialAyahNumber;

  const TafseerComparisonScreen({
    super.key,
    this.initialSurahNumber = 1,
    this.initialAyahNumber = 1,
  });

  @override
  State<TafseerComparisonScreen> createState() => _TafseerComparisonScreenState();
}

class _TafseerComparisonScreenState extends State<TafseerComparisonScreen> with SingleTickerProviderStateMixin {
  late int _surahNumber;
  late int _ayahNumber;
  late TabController _tabController;

  TafseerEntry? _mizanEntry;
  TafseerEntry? _safiEntry;
  String? _verseText;
  bool _isLoading = true;
  double _fontSize = 17.5;

  @override
  void initState() {
    super.initState();
    _surahNumber = widget.initialSurahNumber;
    _ayahNumber = widget.initialAyahNumber;
    _tabController = TabController(length: 2, vsync: this);
    _fontSize = TafseerRepository().getFontSize();
    _loadComparisonData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComparisonData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        TafseerRepository().getTafseerForAyah(TafseerType.almizan, _surahNumber, _ayahNumber),
        TafseerRepository().getTafseerForAyah(TafseerType.safi, _surahNumber, _ayahNumber),
        _fetchVerseText(_surahNumber, _ayahNumber),
      ]);

      if (mounted) {
        setState(() {
          _mizanEntry = results[0] as TafseerEntry?;
          _safiEntry = results[1] as TafseerEntry?;
          _verseText = results[2] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tafseer comparison: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _fetchVerseText(int surah, int ayah) async {
    try {
      final verses = await QuranApiService.getVerses(surah);
      final idx = ayah - 1;
      if (idx >= 0 && idx < verses.length) {
        return verses[idx].textUthmani;
      }
    } catch (_) {}
    return null;
  }

  void _nextAyah() {
    final ch = QuranChapter.getChapterById(_surahNumber);
    if (ch == null) return;

    if (_ayahNumber < ch.versesCount) {
      setState(() => _ayahNumber++);
      _loadComparisonData();
    } else if (_surahNumber < 114) {
      setState(() {
        _surahNumber++;
        _ayahNumber = 1;
      });
      _loadComparisonData();
    }
  }

  void _prevAyah() {
    if (_ayahNumber > 1) {
      setState(() => _ayahNumber--);
      _loadComparisonData();
    } else if (_surahNumber > 1) {
      final prevCh = QuranChapter.getChapterById(_surahNumber - 1);
      if (prevCh != null) {
        setState(() {
          _surahNumber--;
          _ayahNumber = prevCh.versesCount;
        });
        _loadComparisonData();
      }
    }
  }

  void _showAyahPickerSheet(BuildContext context) {
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
                      'اختر الآية من سورة ${ch.nameArabic}',
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
                    final isCurrent = a == _ayahNumber;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _ayahNumber = a);
                        _loadComparisonData();
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

  void _showSurahPickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    const Text(
                      'اختر السورة الكريمة للمقارنة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                child: ListView.builder(
                  itemCount: QuranChapter.allChapters.length,
                  itemBuilder: (context, idx) {
                    final ch = QuranChapter.allChapters[idx];
                    final isCurrent = ch.id == _surahNumber;

                    return ListTile(
                      selected: isCurrent,
                      selectedTileColor: const Color(0xFF059669).withValues(alpha: 0.1),
                      leading: CircleAvatar(
                        backgroundColor: isCurrent ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        child: Text(
                          HijriDateService.toArabicDigits(ch.id),
                          style: TextStyle(
                            color: isCurrent ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        'سورة ${ch.nameArabic}',
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent ? const Color(0xFF059669) : null,
                        ),
                      ),
                      subtitle: Text('${ch.isMakki ? "مكية" : "مدنية"} • ${HijriDateService.toArabicDigits(ch.versesCount)} آية'),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _surahNumber = ch.id;
                          _ayahNumber = 1;
                        });
                        _loadComparisonData();
                      },
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ch = QuranChapter.getChapterById(_surahNumber);
    final surahName = ch?.nameArabic ?? '$_surahNumber';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showSurahPickerSheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'سورة $surahName : الآية ${HijriDateService.toArabicDigits(_ayahNumber)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down_rounded, size: 22),
              ],
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'حجم الخط',
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 24 ? 15 : _fontSize + 2;
              });
              TafseerRepository().setFontSize(_fontSize);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF059669),
          indicatorWeight: 3,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'تفسير الميزان (الطباطبائي)'),
            Tab(text: 'تفسير الصافي (الكاشاني)'),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Quranic Ayah Box
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سورة $surahName • الآية ${HijriDateService.toArabicDigits(_ayahNumber)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showAyahPickerSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 14, color: Color(0xFFD4AF37)),
                              SizedBox(width: 4),
                              Text(
                                'تغيير الآية',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _verseText ?? '﴿ قيد التحميل... ﴾',
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 18.5,
                      height: 1.95,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                      fontFamily: 'UthmanicHafs',
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content: Mizan vs Safi
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTafseerContent(TafseerType.almizan, _mizanEntry, isDark),
                        _buildTafseerContent(TafseerType.safi, _safiEntry, isDark),
                      ],
                    ),
            ),

            // Bottom Navigation Strip: Prev Ayah / Next Ayah (Safe from mobile bottom buttons)
            SafeArea(
              top: false,
              child: _buildBottomNavStrip(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTafseerContent(TafseerType type, TafseerEntry? entry, bool isDark) {
    if (entry == null) {
      return Center(
        child: Text(
          'لا يتوفر نص تفسيري لهذه الآية في ${type.shortName}',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
      );
    }

    final isMizan = type == TafseerType.almizan;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type.shortName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.ayahRangeText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'نسخ التفسير',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '${entry.content}\n\n[المصدر: ${type.displayName} - سورة ${entry.surahName}: ${entry.ayahRangeText}]',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم نسخ تفسير ${type.shortName} إلى الحافظة 📋')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  tooltip: 'مشاركة التفسير',
                  onPressed: () {
                    Share.share(
                      '${entry.content}\n\n[المصدر: ${type.displayName} - سورة ${entry.surahName}: ${entry.ayahRangeText}]',
                      subject: 'تفسير سورة ${entry.surahName} (${entry.ayahRangeText})',
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // Full Tafseer text (منضدة ككشيدة من الجوانب)
            SelectableText(
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
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavStrip(bool isDark) {
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
          // Previous Ayah button
          TextButton.icon(
            onPressed: (_surahNumber > 1 || _ayahNumber > 1) ? _prevAyah : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: const Text('الآية السابقة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'الآية ${HijriDateService.toArabicDigits(_ayahNumber)}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
          ),

          // Next Ayah button
          TextButton.icon(
            onPressed: (_surahNumber < 114 || _ayahNumber < (QuranChapter.getChapterById(_surahNumber)?.versesCount ?? 0))
                ? _nextAyah
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
            label: const Text('الآية التالية', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _cleanTafseerText(String raw) {
    return raw
        .replaceAll(RegExp(r'^#+ ', multiLine: true), '')
        .replaceAll('****', '\n───── ✦ ─────\n')
        .replaceAll('```arabic', '')
        .replaceAll('```', '');
  }
}
