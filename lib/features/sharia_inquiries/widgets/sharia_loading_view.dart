import 'package:flutter/material.dart';

class ShariaLoadingView extends StatelessWidget {
  final String query;

  const ShariaLoadingView({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF10B981) : Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'جاري البحث في مستودع المجيب...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1B3A57),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'استرجاع المسائل والأجوبة المنشورة المتعلقة بـ «$query»',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
