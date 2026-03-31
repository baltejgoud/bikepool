import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2F6B57); // Sage Green
  static const Color primaryDark = Color(0xFFA8D2BF); // Soft Mint Sage
  static const Color secondary = Color(0xFF6F857A); // Moss Grey
  static const Color accent = Color(0xFF7FB494); // Muted Mint

  // Neutral Backgrounds
  static const Color backgroundLight = Color(0xFFF7F6F1);
  static const Color backgroundDark = Color(0xFF101714);
  static const Color surfaceLight = Color(0xFFFCFBF7); // Warm Ivory
  static const Color surfaceDark = Color(0xFF16211D);

  // Cards & Drawers
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1C2924);

  // Text
  static const Color textPrimaryLight = Color(0xFF28483D);
  static const Color textSecondaryLight = Color(0xFF72867D);
  static const Color textPrimaryDark = Color(0xFFEAF3EE);
  static const Color textSecondaryDark = Color(0xFFA9BBB2);

  // Status
  static const Color success = Color(0xFF5D9878);
  static const Color warning = Color(0xFFD1A25A);
  static const Color error = Color(0xFFB65F52);

  // Map Overlay
  static const Color mapOverlay = Color(0xB2182620);
  static const Color glassMorphism =
      Color(0xDDFDFCF9); // Frosted ivory glass
  static const Color glassMorphismDark = Color(0xCC17211D);

  static Color panelBackground({
    required bool isDark,
    required bool highContrast,
  }) {
    if (highContrast) {
      return isDark ? const Color(0xFF0B110E) : const Color(0xFFFFFFFF);
    }
    return isDark ? cardDark : cardLight;
  }

  static Color surfaceBackground({
    required bool isDark,
    required bool highContrast,
  }) {
    if (highContrast) {
      return isDark ? const Color(0xFF050A08) : const Color(0xFFF2F1EA);
    }
    return isDark ? surfaceDark : surfaceLight;
  }

  static Color outline({
    required bool isDark,
    required bool highContrast,
  }) {
    if (highContrast) {
      return isDark ? const Color(0xFFBFD0C8) : const Color(0xFF6C8178);
    }
    return isDark ? const Color(0x335E7C70) : const Color(0xFFDCE6E0);
  }

  static Color secondaryText({
    required bool isDark,
    required bool highContrast,
  }) {
    if (highContrast) {
      return isDark ? const Color(0xFFF2F7F4) : const Color(0xFF1F372E);
    }
    return isDark ? textSecondaryDark : textSecondaryLight;
  }

  static Color mapScrim({
    required bool isDark,
    required bool highContrast,
  }) {
    if (highContrast) {
      return const Color(0x99111A16);
    }
    return isDark
        ? const Color(0x66101814)
        : const Color(0x291E2C25);
  }
}
