import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum AppPillContext {
  primary,
  success,
  warning,
  error,
  info,
  neutral,
}

enum AppPillStyle {
  filled,
  soft,
  outline,
}

class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppPillContext pillContext;
  final AppPillStyle style;
  final VoidCallback? onTap;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.pillContext = AppPillContext.primary,
    this.style = AppPillStyle.soft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = _getColorScheme(pillContext, isDark);

    final backgroundColor = _getBackgroundColor(colorScheme, style);
    final foregroundColor = _getForegroundColor(colorScheme, style);
    final borderColor = _getBorderColor(colorScheme, style);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 8 : 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: foregroundColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PillColors _getColorScheme(AppPillContext context, bool isDark) {
    switch (context) {
      case AppPillContext.primary:
        return _PillColors(
          base: isDark ? AppColors.primaryDark : AppColors.primary,
          onBase: isDark ? const Color(0xFF173126) : Colors.white,
        );
      case AppPillContext.success:
        return _PillColors(
          base: AppColors.success,
          onBase: Colors.white,
        );
      case AppPillContext.warning:
        return _PillColors(
          base: AppColors.warning,
          onBase: Colors.white,
        );
      case AppPillContext.error:
        return _PillColors(
          base: AppColors.error,
          onBase: Colors.white,
        );
      case AppPillContext.info:
        return _PillColors(
          base: AppColors.accent,
          onBase: Colors.white,
        );
      case AppPillContext.neutral:
        return _PillColors(
          base: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          onBase: Colors.white,
        );
    }
  }

  Color _getBackgroundColor(_PillColors colors, AppPillStyle style) {
    switch (style) {
      case AppPillStyle.filled:
        return colors.base;
      case AppPillStyle.soft:
        return colors.base.withValues(alpha: 0.12);
      case AppPillStyle.outline:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(_PillColors colors, AppPillStyle style) {
    switch (style) {
      case AppPillStyle.filled:
        return colors.onBase;
      case AppPillStyle.soft:
      case AppPillStyle.outline:
        return colors.base;
    }
  }

  Color? _getBorderColor(_PillColors colors, AppPillStyle style) {
    if (style == AppPillStyle.outline) {
      return colors.base.withValues(alpha: 0.4);
    }
    if (style == AppPillStyle.soft) {
       return colors.base.withValues(alpha: 0.1);
    }
    return null;
  }
}

class _PillColors {
  final Color base;
  final Color onBase;

  _PillColors({required this.base, required this.onBase});
}
