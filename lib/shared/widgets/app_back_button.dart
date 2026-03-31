import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class AppBackButton extends StatelessWidget {
  final String fallbackRouteName;

  const AppBackButton({
    super.key,
    this.fallbackRouteName = 'home',
  });

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.goNamed(fallbackRouteName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    return Semantics(
      button: true,
      label: 'Back',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Material(
          color: AppColors.panelBackground(
            isDark: isDark,
            highContrast: highContrast,
          ),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _handleBack(context),
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outline(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
