import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_controller.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings.themePalette == AppThemePalette.royalDark;
    final isDark = isEmerald || isRoyalDark;

    Color navBarBg;
    Color navBarBorder;
    if (isEmerald) {
      navBarBg = const Color(0xFF04140D);
      navBarBorder = const Color(0xFF14452F);
    } else if (isRoyalDark) {
      navBarBg = const Color(0xFF0B1120);
      navBarBorder = const Color(0xFF1E293B);
    } else {
      navBarBg = Colors.white;
      navBarBorder = const Color(0xFFE2E8F0);
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: navBarBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: navBarBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: (bottomInset > 0 ? bottomInset : 14.0) + 12.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_rounded, 'الرئيسية', settings),
          _navItem(1, Icons.calendar_month_rounded, 'التقويم', settings),
          _navItem(2, Icons.menu_book_rounded, 'العبادات', settings),
          _navItem(3, Icons.auto_stories_rounded, 'القرآن', settings),
          _navItem(4, Icons.settings_rounded, 'الإعدادات', settings),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, SettingsController settings) {
    final isSelected = currentIndex == index;
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings.themePalette == AppThemePalette.royalDark;

    Color badgeBg;
    Color activeIconColor;
    Color activeTextColor;
    Color inactiveColor;

    if (isEmerald) {
      badgeBg = const Color(0xFF0F3B26);
      activeIconColor = const Color(0xFFFBBF24); // Radiant Gold
      activeTextColor = const Color(0xFF34D399); // Mint Emerald
      inactiveColor = const Color(0xFF6EE7B7).withValues(alpha: 0.6);
    } else if (isRoyalDark) {
      badgeBg = const Color(0xFF1E3A5F);
      activeIconColor = const Color(0xFF38BDF8);
      activeTextColor = Colors.white;
      inactiveColor = Colors.white60;
    } else {
      badgeBg = const Color(0xFFD6EEFA);
      activeIconColor = const Color(0xFF1B3A57);
      activeTextColor = const Color(0xFF1B3A57);
      inactiveColor = const Color(0xFF64748B);
    }

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(16),
                  border: isEmerald
                      ? Border.all(color: const Color(0xFF1B5E3B), width: 1.0)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: activeIconColor,
                  size: 22,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(
                  icon,
                  color: inactiveColor,
                  size: 22,
                ),
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeTextColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
