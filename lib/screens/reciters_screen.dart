import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reciter.dart';
import '../providers/quran_provider.dart';
import '../services/quran_audio_download_service.dart';
import 'reciter_detail_screen.dart';

class RecitersScreen extends StatefulWidget {
  final VoidCallback? onBackToMushaf;

  const RecitersScreen({super.key, this.onBackToMushaf});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  int _selectedFilterIndex = 0; // 0: الكل, 1: المفضلة, 2: المحملة
  final Set<int> _favoriteReciterIds = {51, 112, 118, 108}; // Default popular favorites

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quran = context.watch<QuranProvider>();
    final downloadService = context.watch<QuranAudioDownloadService>();
    const allReciters = ReciterItem.popularReciters;

    // Filter reciters based on selected tab
    final filteredReciters = allReciters.where((r) {
      if (_selectedFilterIndex == 1) {
        // المفضلة
        return _favoriteReciterIds.contains(r.id);
      } else if (_selectedFilterIndex == 2) {
        // المحملة
        return downloadService.getCachedDownloadedCount(r.id) > 0;
      }
      return true; // الكل
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (AppBar)
            _buildAppBar(context, isDark),

            // 2. Filter Segmented Tabs (الكل • المفضلة • المحملة)
            _buildFilterTabs(isDark),

            const SizedBox(height: 12),

            // 3. Reciters List matching design exactly
            Expanded(
              child: filteredReciters.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: filteredReciters.length,
                      itemBuilder: (context, index) {
                        final reciter = filteredReciters[index];
                        final isSelected = quran.selectedReciter.id == reciter.id;
                        final isFavorite = _favoriteReciterIds.contains(reciter.id);

                        return _buildReciterCard(
                          context: context,
                          reciter: reciter,
                          isSelected: isSelected,
                          isFavorite: isFavorite,
                          isDark: isDark,
                          quran: quran,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Header (AppBar) ---
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title on Right (in RTL layout)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                color: isDark ? Colors.white : const Color(0xFF1B3A57),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'رجوع',
                onPressed: () {
                  if (widget.onBackToMushaf != null) {
                    widget.onBackToMushaf!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 12),
              Text(
                'القُرّاء',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  // --- 2. Filter Segmented Tabs ---
  Widget _buildFilterTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFD6E9F3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 1. الكل
          _buildTabItem(
            index: 0,
            title: 'الكل',
            icon: Icons.list_alt_rounded,
            isDark: isDark,
          ),

          // 2. المفضلة
          _buildTabItem(
            index: 1,
            title: 'المفضلة',
            icon: Icons.bookmark_border_rounded,
            isDark: isDark,
          ),

          // 3. المحملة
          _buildTabItem(
            index: 2,
            title: 'المحملة',
            icon: Icons.file_download_outlined,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = (_selectedFilterIndex == index);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilterIndex = index),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57))
                          .withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                      : (isDark ? Colors.white70 : const Color(0xFF1B3A57)),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                    : (isDark ? Colors.white70 : const Color(0xFF1B3A57)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Reciter Card matching Image exactly ---
  Widget _buildReciterCard({
    required BuildContext context,
    required ReciterItem reciter,
    required bool isSelected,
    required bool isFavorite,
    required bool isDark,
    required QuranProvider quran,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1B3A57)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE1EFF7)),
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            quran.selectReciter(reciter);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReciterDetailScreen(reciter: reciter),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 1. Microphone Circle Avatar on the Right (Child 0 in RTL)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD9EEF9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mic_rounded,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57),
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // 2. Name & Country / Narration Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reciter.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1B3A57),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reciter.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Favorite heart / bookmark toggle button
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isFavorite
                        ? const Color(0xFF1B3A57)
                        : (isDark ? Colors.white38 : const Color(0xFFB0C4D6)),
                    size: 22,
                  ),
                  tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                  onPressed: () {
                    setState(() {
                      if (isFavorite) {
                        _favoriteReciterIds.remove(reciter.id);
                      } else {
                        _favoriteReciterIds.add(reciter.id);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilterIndex == 1
                ? Icons.bookmark_border_rounded
                : Icons.file_download_off_rounded,
            size: 54,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilterIndex == 1
                ? 'لا يوجد قراء في المفضلة حالياً'
                : 'لا توجد سور محملة لهذا القارئ بعد',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

