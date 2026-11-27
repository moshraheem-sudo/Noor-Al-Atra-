import 'package:flutter/material.dart';
import '../../models/quran_chapter.dart';
import '../../models/tafseer_model.dart';
import '../../services/hijri_date_service.dart';
import 'tafseer_reader_screen.dart';

class TafseerSurahListScreen extends StatefulWidget {
  final TafseerType initialType;

  const TafseerSurahListScreen({
    super.key,
    required this.initialType,
  });

  @override
  State<TafseerSurahListScreen> createState() => _TafseerSurahListScreenState();
}

class _TafseerSurahListScreenState extends State<TafseerSurahListScreen> {
  late TafseerType _currentType;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMizan = _currentType == TafseerType.almizan;

    final filtered = QuranChapter.allChapters.where((ch) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim();
      return ch.nameArabic.contains(q) ||
          ch.id.toString() == q ||
          HijriDateService.toArabicDigits(ch.id).contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _currentType.shortName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              _currentType.shortAuthor,
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
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Tafseer Switcher Capsule + Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Type Switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildTypeTab(TafseerType.almizan, 'الميزان في تفسير القرآن', isDark),
                        _buildTypeTab(TafseerType.safi, 'تفسير الصافي', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search Field
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 12, left: 6),
                          child: Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'ابحث باسم السورة أو رقمها (١-١١٤)...',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
                            ),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Surahs List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد سورة تطابق البحث',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ch = filtered[index];
                        final arabicNum = HijriDateService.toArabicDigits(ch.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 9),
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TafseerReaderScreen(
                                      type: _currentType,
                                      surahNumber: ch.id,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    // Number Badge
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669))
                                            .withValues(alpha: 0.12),
                                        border: Border.all(
                                          color: (isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669))
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        arabicNum,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isMizan ? const Color(0xFF0284C7) : const Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Surah Name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'سورة ${ch.nameArabic}',
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${ch.isMakki ? "مكية" : "مدنية"} • ${HijriDateService.toArabicDigits(ch.versesCount)} آية',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Indicator
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'عرض التفسير',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.grey),
                                      ],
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
    );
  }

  Widget _buildTypeTab(TafseerType type, String title, bool isDark) {
    final isSelected = _currentType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentType = type),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
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
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }
}
