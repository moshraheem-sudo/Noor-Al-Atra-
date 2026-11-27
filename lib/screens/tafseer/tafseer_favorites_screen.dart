import 'package:flutter/material.dart';
import '../../models/tafseer_model.dart';
import '../../repositories/tafseer_repository.dart';
import '../../services/hijri_date_service.dart';
import 'tafseer_reader_screen.dart';

class TafseerFavoritesScreen extends StatefulWidget {
  const TafseerFavoritesScreen({super.key});

  @override
  State<TafseerFavoritesScreen> createState() => _TafseerFavoritesScreenState();
}

class _TafseerFavoritesScreenState extends State<TafseerFavoritesScreen> {
  List<TafseerFavorite> _favorites = [];
  int _selectedFilterIndex = 0; // 0: الكل, 1: الميزان, 2: الصافي

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favorites = TafseerRepository().getFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _favorites.where((f) {
      if (_selectedFilterIndex == 1) return f.type == TafseerType.almizan;
      if (_selectedFilterIndex == 2) return f.type == TafseerType.safi;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'التفاسير المفضلة',
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
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('الكل (${HijriDateService.toArabicDigits(_favorites.length)})', 0, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'الميزان (${HijriDateService.toArabicDigits(_favorites.where((f) => f.type == TafseerType.almizan).length)})',
                    1,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'الصافي (${HijriDateService.toArabicDigits(_favorites.where((f) => f.type == TafseerType.safi).length)})',
                    2,
                    isDark,
                  ),
                ],
              ),
            ),

            // List or Empty
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border_rounded,
                            size: 56,
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد تفاسير محفوظة في المفضلة',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'يمكنك حفظ أي تفسير عبر زر المفضلة أثناء القراءة',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final fav = filtered[index];
                        final isMizan = fav.type == TafseerType.almizan;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                                    type: fav.type,
                                    surahNumber: fav.surahNumber,
                                    initialAyahNumber: fav.ayahNumber,
                                  ),
                                ),
                              ).then((_) => _loadFavorites());
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
                                          fav.type.shortName,
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
                                          'سورة ${fav.surahName} • ${fav.ayahRangeText}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.bookmark_remove_rounded, color: Colors.redAccent, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'إزالة من المفضلة',
                                        onPressed: () async {
                                          await TafseerRepository().toggleFavorite(
                                            type: fav.type,
                                            surahNumber: fav.surahNumber,
                                            ayahNumber: fav.ayahNumber,
                                            startAyah: fav.startAyah,
                                            endAyah: fav.endAyah,
                                            surahName: fav.surahName,
                                            fullContent: fav.snippet,
                                          );
                                          _loadFavorites();
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    fav.snippet,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
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
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
