import 'package:flutter/material.dart';
import '../models/sharia_answer.dart';

class ShariaResultCard extends StatelessWidget {
  final ShariaAnswer item;
  final VoidCallback onReadFull;
  final VoidCallback? onOpenSource;

  const ShariaResultCard({
    super.key,
    required this.item,
    required this.onReadFull,
    this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF10B981) : const Color(0xFF1B3A57);
    const gold = Color(0xFFD97706);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFD0E6F7),
          width: 1.1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onReadFull,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Metadata chips: category & religious reference
              if (item.category != null || item.reference != null) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (item.category != null)
                      _MetaChip(
                        icon: Icons.folder_outlined,
                        label: item.category!,
                        color: accent,
                        isDark: isDark,
                      ),
                    if (item.reference != null)
                      _MetaChip(
                        icon: Icons.verified_outlined,
                        label: item.reference!,
                        color: gold,
                        isDark: isDark,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Question title
              Text(
                item.title,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              if (item.question.isNotEmpty && item.question != item.title) ...[
                const SizedBox(height: 6),
                Text(
                  item.question,
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.0,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Answer preview box
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  item.answer,
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  softWrap: true,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1E293B),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Source row + Action buttons
              Row(
                children: [
                  if (item.source != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 15,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.source!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReadFull,
                      icon: const Icon(Icons.menu_book_rounded, size: 17),
                      label: const Text(
                        'قراءة الإجابة كاملة',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                  if (item.url != null && onOpenSource != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onOpenSource,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text(
                        'المصدر الأصلي',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
