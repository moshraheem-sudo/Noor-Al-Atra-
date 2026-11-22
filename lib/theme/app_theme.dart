import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/settings_controller.dart';

class AppTheme {
  // Brand colors
  static const Color primaryNavy = Color(0xFF1B3A57);
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color emeraldDarkBg = Color(0xFF04140D);
  static const Color emeraldCardBg = Color(0xFF082216);
  static const Color emeraldBorder = Color(0xFF14452F);
  static const Color goldAccent = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFD97706);

  static ThemeData getTheme(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.emeraldGreen:
        return _buildEmeraldGreenTheme();
      case AppThemePalette.royalDark:
        return _buildRoyalDarkTheme();
      case AppThemePalette.icyBlue:
        return _buildIcyBlueTheme();
    }
  }

  // --- 1. Icy Blue Theme (Default Light) ---
  static ThemeData _buildIcyBlueTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1B3A57),
      scaffoldBackgroundColor: const Color(0xFFEAF4FB),
      cardColor: Colors.white,
      fontFamily: 'Cairo',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1B3A57),
        onPrimary: Colors.white,
        secondary: Color(0xFF0284C7),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1B3A57),
        surfaceContainerHighest: Color(0xFFF0F7FD),
        outline: Color(0xFFD0E6F7),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF1B3A57);
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF90CAF9);
          return const Color(0xFFCBD5E1);
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // --- 2. Emerald Green Theme (Middle Option - Matching User's Screenshot Exactly) ---
  static ThemeData _buildEmeraldGreenTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF10B981),
      scaffoldBackgroundColor: emeraldDarkBg,
      cardColor: emeraldCardBg,
      fontFamily: 'Cairo',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF10B981),
        onPrimary: Colors.black,
        secondary: Color(0xFFFBBF24), // Vibrant gold accent
        onSecondary: Colors.black,
        surface: emeraldCardBg,
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF0D2F20),
        outline: emeraldBorder,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF04140D);
          return Colors.white70;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFFFBBF24); // Gold track
          return const Color(0xFF1E3D2F);
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // --- 3. Royal Dark Theme (Obsidian Dark) ---
  static ThemeData _buildRoyalDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF38BDF8),
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      cardColor: const Color(0xFF1E293B),
      fontFamily: 'Cairo',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8),
        onPrimary: Colors.black,
        secondary: Color(0xFF60A5FA),
        onSecondary: Colors.black,
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF162235),
        outline: Color(0xFF334155),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white70;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF38BDF8);
          return const Color(0xFF334155);
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Legacy accessors
  static ThemeData get lightTheme => _buildIcyBlueTheme();
  static ThemeData get darkTheme => _buildRoyalDarkTheme();
}
