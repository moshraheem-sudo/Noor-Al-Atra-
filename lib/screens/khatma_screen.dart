import 'package:flutter/material.dart';
import '../models/khatma_model.dart';
import '../models/quran_chapter.dart';
import '../repositories/khatma_repository.dart';
import 'quran_reader_screen.dart';

class KhatmaScreen extends StatefulWidget {
  final VoidCallback? onBackToMushaf;

  const KhatmaScreen({super.key, this.onBackToMushaf});

  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  final KhatmaRepository _khatmaRepo = KhatmaRepository();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar: Title on Right, Back Button on Left
            _buildHeader(context, isDark),

            // 2. Full-width Reset Button below Header and above First Juz
            _buildResetAllButton(context, isDark),

            // 3. 30 Juz List Cards
            Expanded(
              child: ListenableBuilder(
                listenable: _khatmaRepo,
                builder: (context, _) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: JuzInfo.allAjza.length,
                    itemBuilder: (context, index) {
                      final juzInfo = JuzInfo.allAjza[index];
                      final progress = _khatmaRepo.getJuzProgress(juzInfo.juzNumber);

                      return _buildJuzCard(
                        context: context,
                        juzInfo: juzInfo,
                        progress: progress,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Header Bar: Title on Right (Start in RTL), Back Arrow on Left (End in RTL) ---
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right in RTL: "الختمة القرآنية" Title
          Text(
            'الختمة القرآنية',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1B3A57),
            ),
          ),

          // Left in RTL: Back Arrow Button
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
        ],
      ),
    );
  }

  // --- 2. Full-width "بدء من جديد" Button under Title & above Juz 1 ---
  Widget _buildResetAllButton(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: isDark ? const Color(0xFF241A20) : const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showResetAllDialog(context, isDark),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF4C2D35) : const Color(0xFFFFD4D0),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.replay_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC2410C),
                ),
                const SizedBox(width: 8),
                Text(
                  'بدء من جديد (تصفير تقدم الختمة بالكامل)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 3. Juz Card: Name on Right (Start in RTL), Status on Left (End in RTL) ---
  Widget _buildJuzCard({
    required BuildContext context,
    required JuzInfo juzInfo,
    required JuzProgress progress,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF5FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFDCEAF2),
          width: 1.0,
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _openJuzInReader(context, juzInfo, progress),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Juz Name on Right, Status badge & Reset icon on Left
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Right in RTL: Juz Arabic Name ("الجزء الأول", "الجزء الثاني"...)
                    Text(
                      juzInfo.arabicName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1B3A57),
                      ),
                    ),

                    // Left in RTL: Status badge + Reset icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Capsule Badge
                        _buildStatusBadge(progress, isDark),
                        const SizedBox(width: 6),

                        // Reset icon button
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 19),
                          color: isDark ? Colors.white60 : const Color(0xFFB45309),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: 'إعادة ضبط هذا الجزء',
                          onPressed: () => _showResetJuzDialog(
                            context,
                            juzInfo.juzNumber,
                            juzInfo.arabicName,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Horizontal Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.progressRatio,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFD3E7F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57),
                    ),
                    minHeight: 6,
                  ),
                ),

                // Bottom percentage and verse location when in progress
                if (progress.status == JuzStatus.inProgress) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Right in RTL: Verse location ("البقرة: آية 10")
                      if (progress.lastReadSurahName != null && progress.lastReadAyah != null)
                        Text(
                          '${progress.lastReadSurahName}: آية ${progress.lastReadAyah}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                        ),

                      // Left in RTL: Percentage ("10%")
                      Text(
                        '${progress.progressPercentInt}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 3. Status Badge Pill ---
  Widget _buildStatusBadge(JuzProgress progress, bool isDark) {
    switch (progress.status) {
      case JuzStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1B3A57),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مكتمل',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ),
        );

      case JuzStatus.inProgress:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2327) : const Color(0xFFFFEEF0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'قيد القراءة ${progress.progressPercentInt}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF1B3A57),
            ),
          ),
        );

      case JuzStatus.notStarted:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2327) : const Color(0xFFFFEEF0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'لم يبدأ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF1B3A57),
            ),
          ),
        );
    }
  }

  // --- 4. Navigation to Quran Reader Screen ---
  void _openJuzInReader(BuildContext context, JuzInfo juzInfo, JuzProgress progress) {
    final targetSurahId = progress.lastReadSurahId ?? juzInfo.startSurahId;
    final targetAyah = progress.lastReadAyah ?? juzInfo.startAyah;
    final targetPage = progress.lastReadPage ?? JuzInfo.getPageForSurahAndAyah(targetSurahId, targetAyah);

    final chapter = QuranChapter.allChapters.firstWhere(
      (c) => c.id == targetSurahId,
      orElse: () => QuranChapter.allChapters.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          chapter: chapter,
          surahId: chapter.id,
          initialPage: targetPage,
          initialAyah: targetAyah,
          highlightKhatmaAyah: true,
          isKhatmaMode: true,
        ),
      ),
    );
  }

  // --- 5. Reset Single Juz Dialog ---
  void _showResetJuzDialog(
    BuildContext context,
    int juzNumber,
    String arabicName,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'إعادة ضبط $arabicName',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1B3A57),
            ),
          ),
          content: Text(
            'هل ترغب في إعادة تعيين تقدم هذا الجزء والبدء فيه من جديد؟',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3A57),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _khatmaRepo.resetJuz(juzNumber);
              },
              child: const Text('إعادة ضبط'),
            ),
          ],
        );
      },
    );
  }

  // --- 6. Reset All Khatma Dialog ---
  void _showResetAllDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'بدء ختمة جديدة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1B3A57),
            ),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في تصفير تقدم جميع الأجزاء والبدء في ختمة قرآنية جديدة من البداية؟',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _khatmaRepo.resetAll();
              },
              child: const Text('تأكيد البدء من جديد'),
            ),
          ],
        );
      },
    );
  }
}
