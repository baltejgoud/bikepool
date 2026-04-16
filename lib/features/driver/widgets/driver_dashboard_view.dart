import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/providers/data_providers.dart';
import '../../../shared/widgets/vehicle_card.dart';
import '../../../shared/widgets/app_pill.dart';
import '../providers/driver_ride_provider.dart';

class DriverDashboardView extends ConsumerWidget {
  const DriverDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(myRidesAsDriverProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141414) : const Color(0xFFF7F7F9);

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
                bottom: 120.0,
                top: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniMapPlaceholder(context, isDark, hasActiveRideInfo),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, isDark),
                  const SizedBox(height: 32),
                  _buildActiveRideSectionFromModel(context, ref, isDark, activeRide),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(
          'Error loading dashboard:\n$e',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.red[300] : Colors.red),
        ),
      ),
    );
  }

  Widget _buildActiveRideSectionFromModel(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    RideModel? activeRide,
  ) {
    if (activeRide == null) {
      return _buildNoActiveRideSection(context, isDark);
    }
    return _buildActiveRideDetails(context, ref, isDark, activeRide);
  }

  Widget _buildNoActiveRideSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.8,
        ),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to earn?',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Offer an empty seat on your next trip to share costs and meet great people.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pushNamed('offer-ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                'Post a Ride Now',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideDetails(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    RideModel ride,
  ) {
    final currentStage = ride.status == RideStatus.active ? 0 : 1;
    final isFindingRiders = ride.status == RideStatus.active;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 1.2,
        ),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppPill(
                      label: isFindingRiders ? 'FINDING RIDERS' : 'RIDE IN PROGRESS',
                      icon: isFindingRiders ? Icons.radar_rounded : Icons.check_circle_outline_rounded,
                      pillContext: isFindingRiders ? AppPillContext.warning : AppPillContext.success,
                      style: AppPillStyle.filled,
                    ),
                    Text(
                      '\u20B9${ride.price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  isFindingRiders ? 'Your ride is live!' : 'Currently on route',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Matching with nearby riders traveling this route.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          
          // Timeline & Stage
          Container(
            color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFA),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStageTimeline(isDark: isDark, currentStage: currentStage),
                const SizedBox(height: 32),
                
                // Elegant Route Display
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 4),
                          _buildRouteNode(outlined: true, color: AppColors.primary),
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildRouteNode(outlined: false, color: AppColors.secondary),
                          const SizedBox(height: 20), // Offset for the bottom text
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRouteStop(
                              label: 'Pickup',
                              value: ride.originAddress,
                              textColor: primaryText,
                              secondaryText: secondaryText,
                            ),
                            const SizedBox(height: 24),
                            _buildRouteStop(
                              label: 'Drop-off',
                              value: ride.destinationAddress,
                              textColor: primaryText,
                              secondaryText: secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),

          // Actions & Details Bottom
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailTile(
                        icon: Icons.event_seat_rounded,
                        label: '${ride.availableSeats} of ${ride.totalSeats} seats',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailTile(
                        icon: ride.vehicleType == VehicleType.bike
                            ? Icons.two_wheeler_rounded
                            : Icons.directions_car_filled_rounded,
                        label: ride.vehicleType == VehicleType.bike ? 'Bike trip' : 'Car trip',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.pushNamed('request-management'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Manage Ride & Requests',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(driverRideProvider.notifier).cancelRide(ride.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Ride cancelled successfully'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Cancel Ride',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMapPlaceholder(
    BuildContext context,
    bool isDark,
    bool hasActiveRide,
  ) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.8,
        ),
        image: const DecorationImage(
          image: NetworkImage(
            'https://maps.googleapis.com/maps/api/staticmap?center=Hyderabad&zoom=12&size=600x300&maptype=roadmap&style=feature:all|element:labels.text.fill|color:0x9e9e9e&style=feature:all|element:labels.text.stroke|visibility:off&style=feature:administrative.locality|element:labels.text.fill|color:0x707070&style=feature:administrative.neighborhood|element:labels.text.fill|color:0x707070&style=feature:road|element:geometry.fill|color:0xffffff&style=feature:road|element:labels.icon|visibility:off',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.8 : 0.4),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  hasActiveRide ? 'Tracking via GPS...' : 'Online \u2022 Waiting for rides',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
          const SizedBox(width: 12),
          _buildActionItem(
            context: context,
            title: 'Ride Requests',
            icon: Icons.notifications_active_rounded,
            color: Colors.orange,
            isDark: isDark,
            onTap: () => context.pushNamed('request-management'),
          ),
          const SizedBox(width: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                : isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: isPrimary
              ? AppColors.softElevation(
                  isDark: isDark,
                  highContrast: false,
                  tint: color,
                  strength: 1.0,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? Colors.white : color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length, (index) {
        final isComplete = index <= currentStage;
        final isLast = index == stages.length - 1;

        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFEDEEF2)),
                  shape: BoxShape.circle,
                  border: isComplete ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4) : null,
                ),
                child: Center(
                  child: Icon(
                    isComplete ? Icons.check_rounded : Icons.fiber_manual_record,
                    size: isComplete ? 16 : 8,
                    color: isComplete
                        ? Colors.white
                        : (isDark ? Colors.white30 : Colors.black26),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stages[index],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isComplete ? FontWeight.w700 : FontWeight.w600,
                        color: isComplete ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                                  : Colors.black.withValues(alpha: 0.06)),
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
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        border: outlined ? Border.all(color: color, width: 4) : null,
        shape: BoxShape.circle,
        boxShadow: outlined ? null : [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ],
      ),
    );
  }

  Widget _buildRouteStop({
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: secondaryText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

