import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/quran_chapter.dart';
import '../../models/tafseer_model.dart';
import '../../repositories/tafseer_repository.dart';
import '../../services/hijri_date_service.dart';
import '../../services/voice_search_service.dart';
import 'tafseer_reader_screen.dart';

class TafseerSearchScreen extends StatefulWidget {
  final TafseerType? initialType;
  const TafseerSearchScreen({super.key, this.initialType});

  @override
  State<TafseerSearchScreen> createState() => _TafseerSearchScreenState();
}

class _TafseerSearchScreenState extends State<TafseerSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedFilterIndex = 0; // 0: الكل, 1: الميزان, 2: الصافي
  List<TafseerSearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialType == TafseerType.almizan) {
      _selectedFilterIndex = 1;
    } else if (widget.initialType == TafseerType.safi) {
      _selectedFilterIndex = 2;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    // Check if query is Surah name or Surah:Ayah (e.g. "البقرة 255" or "1:1")
    final directMatch = _checkDirectSurahAyahMatch(trimmed);
    if (directMatch != null) {
      // Direct navigation suggestion handled immediately
      _executeSearch(trimmed, directSurahMatch: directMatch);
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(trimmed);
    });
  }

  Map<String, int>? _checkDirectSurahAyahMatch(String query) {
    final clean = query.replaceAll('سورة', '').trim();
    final parts = clean.split(RegExp(r'[\s:,\-_]+'));
    if (parts.isEmpty) return null;

    final firstPart = parts[0].trim();
    QuranChapter? matchedChapter;

    // By ID
    final id = int.tryParse(firstPart);
    if (id != null && id >= 1 && id <= 114) {
      matchedChapter = QuranChapter.getChapterById(id);
    } else {
      // By Name
      matchedChapter = QuranChapter.allChapters.firstWhere(
        (c) => c.nameArabic == firstPart || c.nameArabic.contains(firstPart),
        orElse: () => QuranChapter.allChapters.first,
      );
      if (!matchedChapter.nameArabic.contains(firstPart)) {
        matchedChapter = null;
      }
    }

    if (matchedChapter != null) {
      int ayah = 1;
      if (parts.length > 1) {
        final parsedAyah = int.tryParse(parts[1]);
        if (parsedAyah != null && parsedAyah >= 1 && parsedAyah <= matchedChapter.versesCount) {
          ayah = parsedAyah;
        }
      }
      return {'surah': matchedChapter.id, 'ayah': ayah};
    }
    return null;
  }

  Future<void> _executeSearch(String query, {Map<String, int>? directSurahMatch}) async {
    setState(() => _isSearching = true);

    try {
      final List<TafseerSearchResult> all = [];

      // If direct Surah/Ayah matched, fetch direct tafseer entry
      if (directSurahMatch != null) {
        final surahId = directSurahMatch['surah']!;
        final ayahId = directSurahMatch['ayah']!;

        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
          final mizanEntry = await TafseerRepository().getTafseerForAyah(TafseerType.almizan, surahId, ayahId);
          if (mizanEntry != null) {
            all.add(TafseerSearchResult(
              type: TafseerType.almizan,
              contentId: mizanEntry.contentId,
              surahNumber: surahId,
              startAyah: mizanEntry.startAyah,
              endAyah: mizanEntry.endAyah,
              surahName: mizanEntry.surahName,
              snippet: mizanEntry.content.length > 140 ? '${mizanEntry.content.substring(0, 140)}...' : mizanEntry.content,
              matchedText: query,
            ));
          }
        }
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) {
          final safiEntry = await TafseerRepository().getTafseerForAyah(TafseerType.safi, surahId, ayahId);
          if (safiEntry != null) {
            all.add(TafseerSearchResult(
              type: TafseerType.safi,
              contentId: safiEntry.contentId,
              surahNumber: surahId,
              startAyah: safiEntry.startAyah,
              endAyah: safiEntry.endAyah,
              surahName: safiEntry.surahName,
              snippet: safiEntry.content.length > 140 ? '${safiEntry.content.substring(0, 140)}...' : safiEntry.content,
              matchedText: query,
            ));
          }
        }
      }

      // Text search in SQLite
      if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
        final mizanResults = await TafseerRepository().searchTafseer(TafseerType.almizan, query, limit: 40);
        all.addAll(mizanResults);
      }
      if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) {
        final safiResults = await TafseerRepository().searchTafseer(TafseerType.safi, query, limit: 40);
        all.addAll(safiResults);
      }

      if (mounted) {
        setState(() {
          _results = all;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Tafseer search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'البحث في تفاسير القرآن',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
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
                    const Padding(
                      padding: EdgeInsets.only(right: 14, left: 6),
                      child: Icon(Icons.search, color: Color(0xFF059669), size: 22),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث في نصوص التفسير أو باسم السورة والآية...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        color: Colors.grey,
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.mic_none_rounded, size: 22, color: Color(0xFF059669)),
                        tooltip: 'البحث الصوتي',
                        onPressed: () async {
                          final spoken = await VoiceSearchService.startVoiceSearch(context);
                          if (spoken != null && spoken.isNotEmpty) {
                            _searchCtrl.text = spoken;
                            _onSearchChanged(spoken);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Tafseer Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip('الكل', 0, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('الميزان', 1, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('الصافي', 2, isDark),
                  const Spacer(),
                  if (_results.isNotEmpty)
                    Text(
                      '${HijriDateService.toArabicDigits(_results.length)} نتيجة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),

            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  backgroundColor: Colors.transparent,
                ),
              ),

            // Results List
            Expanded(
              child: _results.isEmpty && !_isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 56,
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchCtrl.text.isEmpty
                                ? 'اكتب كلمة أو جملة أو اسم سورة للبحث'
                                : 'لا توجد نتائج تطابق بحثك',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          if (_searchCtrl.text.isEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'أمثلة: "الصراط المستقيم" أو "البقرة 255" أو "الكوثر"',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final res = _results[index];
                        final isMizan = res.type == TafseerType.almizan;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TafseerReaderScreen(
                                    type: res.type,
                                    surahNumber: res.surahNumber,
                                    initialAyahNumber: res.startAyah,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669))
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          res.type.shortName,
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
                                          'سورة ${res.surahName} • ${res.ayahRangeText}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.grey),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    res.snippet,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      fontFamily: 'Amiri',
                                    ),
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
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilterIndex = index);
        if (_searchCtrl.text.trim().isNotEmpty) {
          _onSearchChanged(_searchCtrl.text);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF059669)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
