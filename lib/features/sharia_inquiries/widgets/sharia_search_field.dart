import 'package:flutter/material.dart';

class ShariaSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;

  const ShariaSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.isLoading,
    required this.onSearch,
    required this.onClear,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = isDark ? const Color(0xFF10B981) : primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              maxLines: 2,
              minLines: 1,
              enabled: !isLoading,
              onChanged: onChanged,
              onSubmitted: (_) => onSearch(),
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'اكتب سؤالك الشرعي للبحث عن إجابات منشورة...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: accent,
                  size: 22,
                ),
                suffixIcon: controller.text.isNotEmpty && !isLoading
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        tooltip: 'مسح النص',
                        onPressed: onClear,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accent.withValues(alpha: 0.5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'بحث',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
