import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum VehicleType { bike, car }

class RideOption {
  final VehicleType type;
  final String name;
  final int seats;
  final String priceFormatted;
  final int? priceValue;
  final String eta;
  final int? etaMinutes;
  final String description;
  final String driverName;
  final String? driverPhoto;
  final String vehicleModel;
  final bool willPickup;
  final int? pickupDistanceMeters;
  final double? rating;
  final String? recommendationTag;
  final String? pickupSummary;
  final String? detourLabel;
  final String? trustLabel;

  const RideOption({
    required this.type,
    required this.name,
    required this.seats,
    required this.priceFormatted,
    this.priceValue,
    required this.eta,
    this.etaMinutes,
    required this.description,
    required this.driverName,
    this.driverPhoto,
    required this.vehicleModel,
    this.willPickup = true,
    this.pickupDistanceMeters,
    this.rating,
    this.recommendationTag,
    this.pickupSummary,
    this.detourLabel,
    this.trustLabel,
  });
}

class VehicleCard extends StatelessWidget {
  final RideOption option;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.of(context).highContrast;
    final secondaryText = AppColors.secondaryText(
      isDark: isDark,
      highContrast: highContrast,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.name,
      value:
          '${option.priceFormatted}, ${option.eta}, ${option.seats} seat${option.seats > 1 ? 's' : ''}',
      hint: option.pickupSummary ?? option.description,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(
                      alpha: highContrast ? 0.16 : 0.08,
                    )
                  : AppColors.panelBackground(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppColors.softElevation(
                isDark: isDark,
                highContrast: highContrast,
                tint: isSelected ? AppColors.primary : null,
                strength: isSelected ? 1.0 : 0.9,
              ),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(
                        alpha: highContrast ? 1 : 0.28,
                      )
                    : AppColors.softStroke(
                        isDark: isDark,
                        highContrast: highContrast,
                      ),
                width: highContrast ? 2 : (isSelected ? 1.4 : 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (option.recommendationTag != null) ...[
                  _PillTag(
                    label: option.recommendationTag!,
                    isDark: isDark,
                    highContrast: highContrast,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    foregroundColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                option.type == VehicleType.bike
                                    ? Icons.directions_bike_rounded
                                    : Icons.directions_car_filled_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                option.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            option.eta,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          option.priceFormatted,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'total',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: option.driverPhoto != null
                            ? Colors.transparent
                            : AppColors.surfaceBackground(
                                isDark: isDark,
                                highContrast: highContrast,
                              ),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        image: option.driverPhoto != null
                            ? DecorationImage(
                                image: NetworkImage(option.driverPhoto!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: option.driverPhoto == null
                          ? Icon(
                              Icons.person_rounded,
                              color: secondaryText,
                              size: 32,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  option.driverName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (option.rating != null) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  option.rating!.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            option.vehicleModel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            option.pickupSummary ?? option.description,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.4,
                              color: secondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _InfoBadge(
                      icon: Icons.people_outline_rounded,
                      label:
                          '${option.seats} seat${option.seats > 1 ? 's' : ''}',
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                    if (option.detourLabel != null)
                      _InfoBadge(
                        icon: Icons.alt_route_rounded,
                        label: option.detourLabel!,
                        isDark: isDark,
                        highContrast: highContrast,
                      ),
                    if (option.trustLabel != null)
                      _InfoBadge(
                        icon: Icons.verified_user_rounded,
                        label: option.trustLabel!,
                        isDark: isDark,
                        highContrast: highContrast,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool highContrast;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground(
          isDark: isDark,
          highContrast: highContrast,
        ),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: AppColors.outline(
            isDark: isDark,
            highContrast: highContrast,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: AppColors.secondaryText(
              isDark: isDark,
              highContrast: highContrast,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText(
                isDark: isDark,
                highContrast: highContrast,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool highContrast;
  final Color backgroundColor;
  final Color foregroundColor;

  const _PillTag({
    required this.label,
    required this.isDark,
    required this.highContrast,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}
