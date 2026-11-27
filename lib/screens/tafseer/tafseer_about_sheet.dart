import 'package:flutter/material.dart';

class TafseerAboutSheet extends StatelessWidget {
  const TafseerAboutSheet({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const TafseerAboutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'عن تفاسير القرآن ومصدر البيانات',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tafseer Al-Mizan info
              _buildInfoCard(
                isDark: isDark,
                title: 'الميزان في تفسير القرآن',
                author: 'العلامة السيد محمد حسين الطباطبائي (قدس سره)',
                description:
                    'تفسير قرآني فريد موسوعي جليل، قائم على منهج "تفسير القرآن بالقرآن"، مع استقصاء الآيات الشريفة وبيان دلالاتها اللغوية والعقلية، وإفراد أبحاث روائية وفلسفية واجتماعية وأخلاقية مستقلة تخدم فهم الآيات.',
                badge: 'تفسير تحليلي • ٢٠ مجلداً',
                badgeColor: const Color(0xFF0284C7),
              ),
              const SizedBox(height: 12),

              // Tafseer Al-Safi info
              _buildInfoCard(
                isDark: isDark,
                title: 'تفسير الصافي',
                author: 'الشيخ محمد محسن الفيض الكاشاني (قدس سره)',
                description:
                    'تفسير روائي شريف جامع ومختصر معتمد، يستند مباشرة إلى أحاديث وروايات النبي الأعظم (ص) وأهل بيته الأطهار (عليهم السلام) المروية في جوامع الحديث المعتبرة، مبيناً أسرار التنزيل وبواطن التأويل.',
                badge: 'تفسير روائي • ٥ مجلدات',
                badgeColor: const Color(0xFF059669),
              ),
              const SizedBox(height: 16),

              // Data source and License
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 18, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 8),
                        Text(
                          'مصدر البيانات والترخيص',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم اعتماد قواعد بيانات SQLite الأصلية بدون أي تعديل من مستودع:\n'
                      'Furqan Apps — Quran App Data\n'
                      'https://github.com/app-furqan/quran-app-data',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'مرخص وفق رخصة المشاع الإبداعي: CC BY-ND 4.0\n'
                        'Creative Commons Attribution-NoDerivatives 4.0 International',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• الخدمة مجانية بالكامل ومدمجة بنسبة 100% دون الحاجة إلى إنترنت.\n'
                      '• النصوص القرآنية والتفسيرية أصلية وغير محرفة.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required String author,
    required String description,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            author,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
