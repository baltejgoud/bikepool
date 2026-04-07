import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.7,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13, // Slightly smaller
        fontWeight: FontWeight.w500, // Medium weight for secondary
        color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700, // Bolder labels
        color: primary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10, // Smaller for metadata
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.6,
      ),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required bool highContrast,
  }) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final onPrimary = isDark ? const Color(0xFF173126) : Colors.white;
    final onSecondary = isDark ? const Color(0xFF173126) : Colors.white;
    final surface = AppColors.surfaceBackground(
      isDark: isDark,
      highContrast: highContrast,
    );
    final card = AppColors.panelBackground(
      isDark: isDark,
      highContrast: highContrast,
    );
    final outline = AppColors.outline(
      isDark: isDark,
      highContrast: highContrast,
    );
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = AppColors.secondaryText(
      isDark: isDark,
      highContrast: highContrast,
    );
    final cs = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: surface,
      error: AppColors.error,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      colorScheme: cs,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      textTheme: _buildTextTheme(primaryText, secondaryText),
      dividerColor: outline,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          textStyle:
              GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: outline),
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: highContrast ? 0 : 2,
        shadowColor: AppColors.shadowColor(
          isDark: isDark,
          highContrast: highContrast,
          strength: 0.9,
        ),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(
            color: AppColors.softStroke(
              isDark: isDark,
              highContrast: highContrast,
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark 
            ? primary.withValues(alpha: 0.15) 
            : primary.withValues(alpha: 0.08),
        selectedColor: primary,
        disabledColor: surface,
        secondarySelectedColor: primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: BorderSide(
            color: isDark 
                ? primary.withValues(alpha: 0.2) 
                : primary.withValues(alpha: 0.1),
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: onPrimary,
        ),
        checkmarkColor: onPrimary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        selectedItemColor: primary,
        unselectedItemColor: secondaryText,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primary,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onPrimary,
        ),
        waitDuration: const Duration(milliseconds: 300),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: primary,
            width: highContrast ? 2 : 1.5,
          ),
        ),
        hintStyle: GoogleFonts.inter(color: secondaryText, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 18),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        highContrast: false,
      );

  static ThemeData get highContrastLightTheme => _buildTheme(
        brightness: Brightness.light,
        highContrast: true,
      );

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      highContrast: false,
    );
  }

  static ThemeData get highContrastDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        highContrast: true,
      );
}
