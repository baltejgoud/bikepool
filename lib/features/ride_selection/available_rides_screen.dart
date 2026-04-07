import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/vehicle_card.dart';
import '../../shared/widgets/app_pill.dart';
import '../shared_widgets/empty_state/empty_state.dart';
import '../shared_widgets/skeleton_loaders/skeleton_loaders.dart';
import '../../core/models/ride_model.dart';
import '../../core/providers/data_providers.dart';
import 'models/ride_alert.dart';
import 'providers/ride_alert_provider.dart';

enum RideSortOption { bestMatch, cheapest, fastest, closestPickup }

class AvailableRidesScreen extends ConsumerStatefulWidget {
  final String destination;
  final double destinationLat;
  final double destinationLng;
  final String? initialVehicleType;

  const AvailableRidesScreen({
    super.key,
    required this.destination,
    required this.destinationLat,
    required this.destinationLng,
    this.initialVehicleType,
  });

  @override
  ConsumerState<AvailableRidesScreen> createState() =>
      _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends ConsumerState<AvailableRidesScreen> {
  String? _selectedFilter;
  RideSortOption _selectedSort = RideSortOption.bestMatch;

  final List<String> _filters = [
    'All',
    'Bike',
    'Scooty',
    '4 seat car',
    '7 seat car'
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialVehicleType ?? 'All';
  }

  RideOption _mapRideToOption(RideModel ride) {
    return RideOption(
      type: ride.vehicleType,
      name: ride.vehicleType == VehicleType.bike ? 'Bike' : 'Car',
      seats: ride.availableSeats,
      priceFormatted: '₹${ride.price.toStringAsFixed(0)}',
      priceValue: ride.price.toInt(),
      eta: 'Pickup in 5 min',
      etaMinutes: 5,
      description: 'Shared ride heading to destination.',
      driverName: ride.driverName,
      vehicleModel: ride.vehicleType == VehicleType.bike
          ? 'Hero Splendor'
          : 'Maruti Swift',
      willPickup: true,
      pickupDistanceMeters: 150,
      rating: 4.8,
      recommendationTag: ride.price < 60 ? 'Cheapest' : 'Best Match',
      pickupSummary: 'Pickup from ${ride.originAddress}',
      detourLabel: 'Low detour',
      trustLabel: 'ID verified',
    );
  }

  void _setAlert() {
    final alert = RideAlert.create(
      source: 'Current Location',
      destination: widget.destination,
      type: AlertType.immediate,
    );
    ref.read(rideAlertsProvider.notifier).addAlert(alert);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert set for ${alert.destination}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(rideAlertsProvider.notifier).removeAlert(alert.id),
        ),
      ),
    );
  }

  void _scheduleRide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Ride'),
        content: const Text('Select a time for your ride:'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ride scheduled!')),
              );
              context.pop();
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  List<RideOption> _sortRides(List<RideOption> rides) {
    final sorted = [...rides];

    int pickupRank(RideOption ride) => ride.pickupDistanceMeters ?? 9999;
    int etaRank(RideOption ride) => ride.etaMinutes ?? 999;
    int fareRank(RideOption ride) => ride.priceValue ?? 9999;
    int recommendationRank(RideOption ride) {
      final tag = ride.recommendationTag?.toLowerCase() ?? '';
      if (tag.contains('best')) return 0;
      if (tag.contains('fast')) return 1;
      if (tag.contains('comfortable')) return 2;
      if (tag.contains('cheap')) return 3;
      return 4;
    }

    switch (_selectedSort) {
      case RideSortOption.bestMatch:
        sorted.sort((a, b) {
          final compare =
              recommendationRank(a).compareTo(recommendationRank(b));
          if (compare != 0) return compare;
          return pickupRank(a).compareTo(pickupRank(b));
        });
        break;
      case RideSortOption.cheapest:
        sorted.sort((a, b) => fareRank(a).compareTo(fareRank(b)));
        break;
      case RideSortOption.fastest:
        sorted.sort((a, b) => etaRank(a).compareTo(etaRank(b)));
        break;
      case RideSortOption.closestPickup:
        sorted.sort((a, b) => pickupRank(a).compareTo(pickupRank(b)));
        break;
    }

    return sorted;
  }

  String _sortLabel(RideSortOption option) {
    switch (option) {
      case RideSortOption.bestMatch:
        return 'Best Match';
      case RideSortOption.cheapest:
        return 'Cheapest';
      case RideSortOption.fastest:
        return 'Fastest';
      case RideSortOption.closestPickup:
        return 'Closest Pickup';
    }
  }

  String _sortDescription(RideSortOption option) {
    switch (option) {
      case RideSortOption.bestMatch:
        return 'Balances pickup ease, route fit, and comfort.';
      case RideSortOption.cheapest:
        return 'Lowest fare first for budget-friendly choices.';
      case RideSortOption.fastest:
        return 'Shortest pickup ETA first.';
      case RideSortOption.closestPickup:
        return 'Best if you want the least walking.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    final ridesAsync = ref.watch(matchedRidesProvider({
      'originLat': 17.3850,
      'originLng': 78.4867,
      'destinationLat': widget.destinationLat,
      'destinationLng': widget.destinationLng,
    }));

    return ridesAsync.when(
      data: (allRides) {
        final options = allRides.map(_mapRideToOption).toList();
        final filteredRides = _selectedFilter == 'All'
            ? options
            : options
                .where(
                  (r) => r.name.toLowerCase() == _selectedFilter?.toLowerCase(),
                )
                .toList();
        final visibleRides = _sortRides(filteredRides);
        final bestRide = visibleRides.isNotEmpty ? visibleRides.first : null;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            leading: const AppBackButton(),
            title: Text(
              'Choose your ride',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTripSummaryCard(
                      isDark: isDark,
                      highContrast: highContrast,
                      bestRide: bestRide,
                      visibleCount: visibleRides.length,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSortSection(isDark, highContrast),
                    const SizedBox(height: AppSpacing.md),
                    _buildFilterSection(isDark, highContrast),
                  ],
                ),
              ),
              Expanded(
                child: visibleRides.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: '🚗',
                          title: 'No rides available right now',
                          subtitle:
                              'Try a different time or location, or set an alert.',
                          actionLabel: 'Set Alert',
                          onAction: _setAlert,
                          secondaryActionLabel: 'Schedule for Later',
                          onSecondaryAction: _scheduleRide,
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        itemCount: visibleRides.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final ride = visibleRides[index];
                          return VehicleCard(
                            option: ride,
                            isSelected: index == 0 &&
                                _selectedSort == RideSortOption.bestMatch,
                            isDark: isDark,
                            onTap: () {
                              context.pushNamed(
                                'ride-route-map',
                                extra: {
                                  'destination': widget.destination,
                                  'lat': widget.destinationLat,
                                  'lng': widget.destinationLng,
                                  'ride': ride,
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          children: [
            RideOptionSkeleton(isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            RideOptionSkeleton(isDark: isDark),
          ],
        ),
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: const Center(child: Text('Error searching rides')),
      ),
    );
  }

  Widget _buildTripSummaryCard({
    required bool isDark,
    required bool highContrast,
    required RideOption? bestRide,
    required int visibleCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.panelBackground(
          isDark: isDark,
          highContrast: highContrast,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: highContrast,
          strength: 0.95,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: highContrast,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heading to ${widget.destination.split(',').first}',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            bestRide == null
                ? 'Checking nearby shared rides now.'
                : '$visibleCount options found. Best current fit: ${bestRide.name} with ${bestRide.pickupSummary?.toLowerCase() ?? 'quick pickup'}.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AppColors.secondaryText(
                isDark: isDark,
                highContrast: highContrast,
              ),
            ),
          ),
          if (bestRide != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (bestRide.recommendationTag != null)
                  AppPill(
                    label: bestRide.recommendationTag!,
                    pillContext: AppPillContext.success,
                    icon: Icons.star_rounded,
                  ),
                AppPill(
                  label: bestRide.priceFormatted,
                  pillContext: AppPillContext.primary,
                  icon: Icons.payments_rounded,
                ),
                AppPill(
                  label: bestRide.eta,
                  pillContext: AppPillContext.info,
                  icon: Icons.timer_rounded,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortSection(bool isDark, bool highContrast) {
    return Semantics(
      container: true,
      label: 'Ride sorting options',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RideSortOption.values.map((option) {
                final isSelected = _selectedSort == option;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(_sortLabel(option)),
                    selected: isSelected,
                    tooltip: _sortDescription(option),
                    onSelected: (_) => setState(() => _selectedSort = option),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _sortDescription(_selectedSort),
            style: GoogleFonts.inter(
              fontSize: 12,
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

  Widget _buildFilterSection(bool isDark, bool highContrast) {
    return Semantics(
      container: true,
      label: 'Vehicle type filters',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                tooltip: 'Filter rides by $filter',
                onSelected: (_) => setState(() => _selectedFilter = filter),
                backgroundColor: AppColors.surfaceBackground(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
                side: BorderSide(
                  color: AppColors.outline(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                ),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.secondaryText(
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
