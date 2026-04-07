import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/providers/data_providers.dart';
import '../../../shared/widgets/vehicle_card.dart';
import '../../../shared/widgets/app_pill.dart';

class DriverDashboardView extends ConsumerWidget {
  const DriverDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(myRidesAsDriverProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F4);

    return ridesAsync.when(
      data: (rides) {
        final activeRide = rides.cast<RideModel?>().firstWhere(
              (r) =>
                  r?.status != RideStatus.completed &&
                  r?.status != RideStatus.cancelled,
              orElse: () => null,
            );
        final hasActiveRideInfo = activeRide != null;

        return Container(
          color: bgColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 100.0,
                top: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniMapPlaceholder(context, isDark, hasActiveRideInfo),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, isDark),
                  const SizedBox(height: 32),
                  _buildActiveRideSectionFromModel(context, isDark, activeRide),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error loading dashboard')),
    );
  }

  Widget _buildActiveRideSectionFromModel(
    BuildContext context,
    bool isDark,
    RideModel? activeRide,
  ) {
    if (activeRide == null) {
      return _buildNoActiveRideSection(context, isDark);
    }

    // Map RideModel to what the UI expects or update UI to use RideModel
    // For now, I'll update the helper to take RideModel
    return _buildActiveRideDetails(context, isDark, activeRide);
  }

  Widget _buildNoActiveRideSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.95,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: false,
            tint: AppColors.primary,
            strength: 1.1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No active rides',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Post a ride to start sharing seats and earning.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.pushNamed('offer-ride'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Post a Ride',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideDetails(
    BuildContext context,
    bool isDark,
    RideModel ride,
  ) {
    // Current stage based on RideStatus
    final currentStage = ride.status == RideStatus.active ? 0 : 1;
    final isFindingRiders = ride.status == RideStatus.active;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final panelColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F4EE);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 1.0,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: false,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      AppPill(
                        label: isFindingRiders
                            ? 'FINDING RIDERS'
                            : 'RIDE IN PROGRESS',
                        icon: isFindingRiders
                            ? Icons.radar_rounded
                            : Icons.check_circle_outline_rounded,
                        pillContext: isFindingRiders
                            ? AppPillContext.warning
                            : AppPillContext.success,
                        style: AppPillStyle.soft,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isFindingRiders ? 'Posted ride' : 'Active trip summary',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your route is live and visible to nearby riders.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\u20B9${ride.price.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStageTimeline(isDark: isDark, currentStage: currentStage),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _buildRouteNode(outlined: true, color: AppColors.primary),
                      Container(
                        width: 2,
                        height: 28,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      _buildRouteNode(
                        outlined: false,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRouteStop(
                          label: 'Pickup',
                          value: ride.originAddress,
                          textColor: primaryText,
                          secondaryTextColor: secondaryText,
                        ),
                        const SizedBox(height: 18),
                        _buildRouteStop(
                          label: 'Drop-off',
                          value: ride.destinationAddress,
                          textColor: primaryText,
                          secondaryTextColor: secondaryText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const AppPill(
                  label: 'Today',
                  icon: Icons.schedule_rounded,
                  pillContext: AppPillContext.neutral,
                  style: AppPillStyle.soft,
                ),
                AppPill(
                  label: '${ride.totalSeats} seats total',
                  icon: Icons.event_seat_rounded,
                  pillContext: AppPillContext.neutral,
                  style: AppPillStyle.soft,
                ),
                AppPill(
                  label: ride.vehicleType == VehicleType.bike
                      ? 'Bike ride'
                      : 'Car ride',
                  icon: ride.vehicleType == VehicleType.bike
                      ? Icons.two_wheeler_rounded
                      : Icons.directions_car_filled_rounded,
                  pillContext: AppPillContext.neutral,
                  style: AppPillStyle.soft,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Requests and rider matches will show up in Management.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: secondaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => context.pushNamed('request-management'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Manage Ride',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMapPlaceholder(
    BuildContext context,
    bool isDark,
    bool hasActiveRide,
  ) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: false,
            tint: AppColors.primary,
            strength: 1.05,
          ),
        ),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.95,
        ),
        image: const DecorationImage(
          image: NetworkImage(
            'https://maps.googleapis.com/maps/api/staticmap?center=Hyderabad&zoom=12&size=600x300&maptype=roadmap&style=feature:all|element:labels.text.fill|color:0x9e9e9e&style=feature:all|element:labels.text.stroke|visibility:off&style=feature:administrative.locality|element:labels.text.fill|color:0x707070&style=feature:administrative.neighborhood|element:labels.text.fill|color:0x707070&style=feature:landscape|element:geometry.fill|color:0xf5f5f2&style=feature:poi|element:geometry.fill|color:0xdce0d9&style=feature:poi.park|element:geometry.fill|color:0xc8d7d4&style=feature:road|element:geometry.fill|color:0xffffff&style=feature:road|element:labels.icon|visibility:off&style=feature:transit|element:geometry.fill|color:0xe5e5e5&style=feature:water|element:geometry.fill|color:0xa3ccff',
          ),
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hasActiveRide ? 'Active ride tracking...' : 'You are online',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildActionItem(
            context: context,
            title: 'Post Ride',
            icon: Icons.add_road_rounded,
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => context.pushNamed('offer-ride'),
            isPrimary: true,
          ),
          const SizedBox(width: 16),
          _buildActionItem(
            context: context,
            title: 'Ride Requests',
            icon: Icons.notifications_active_rounded,
            color: Colors.orange,
            isDark: isDark,
            onTap: () => context.pushNamed('request-management'),
          ),
          const SizedBox(width: 16),
          _buildActionItem(
            context: context,
            title: 'Go Offline',
            icon: Icons.power_settings_new_rounded,
            color: Colors.redAccent,
            isDark: isDark,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.9), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : AppColors.softStroke(
                    isDark: isDark,
                    highContrast: false,
                  ),
          ),
          boxShadow: AppColors.softElevation(
            isDark: isDark,
            highContrast: false,
            tint: isPrimary ? color : null,
            strength: isPrimary ? 0.95 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? Colors.white : color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageTimeline({
    required bool isDark,
    required int currentStage,
  }) {
    const stages = ['Posted', 'Matched', 'On trip'];

    return Row(
      children: List.generate(stages.length, (index) {
        final isComplete = index <= currentStage;
        final isLast = index == stages.length - 1;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF0ECE4)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete ? Icons.check_rounded : Icons.circle_outlined,
                  size: isComplete ? 16 : 14,
                  color: isComplete
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black38),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stages[index],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        height: 3,
                        decoration: BoxDecoration(
                          color: index < currentStage
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.08)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRouteNode({
    required bool outlined,
    required Color color,
  }) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        border: outlined ? Border.all(color: color, width: 2) : null,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRouteStop({
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
