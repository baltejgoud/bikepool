import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/app_back_button.dart';
import 'ride_booking_provider.dart';

enum _BookingPhase { waiting, matched }

class BookingStatusScreen extends ConsumerStatefulWidget {
  const BookingStatusScreen({super.key});

  @override
  ConsumerState<BookingStatusScreen> createState() =>
      _BookingStatusScreenState();
}

class _BookingStatusScreenState extends ConsumerState<BookingStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _simulationTimer;
  _BookingPhase _phase = _BookingPhase.waiting;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final bookingState = ref.read(rideBookingProvider);
    _phase = bookingState.status == RideBookingStatus.confirmed
        ? _BookingPhase.matched
        : _BookingPhase.waiting;

    if (bookingState.status != RideBookingStatus.confirmed) {
      _startSimulation();
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();

    _simulationTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      final ride = ref.read(rideBookingProvider).selectedRide;
      if (ride == null) return;

      ref.read(rideBookingProvider.notifier).confirmRide(
            'RIDE_${DateTime.now().millisecondsSinceEpoch}',
          );

      setState(() {
        _phase = _BookingPhase.matched;
      });
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _cancelRequest() {
    _simulationTimer?.cancel();
    ref.read(rideBookingProvider.notifier).reset();
    context.goNamed('home');
  }

  void _openTracking() {
    final bookingState = ref.read(rideBookingProvider);
    final rideId = bookingState.rideId;

    if (rideId == null || rideId.isEmpty) {
      context.goNamed('home');
      return;
    }

    context.goNamed(
      'tracking',
      extra: {'rideId': rideId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(rideBookingProvider);
    final ride = bookingState.selectedRide;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;
    final isMatched = bookingState.status == RideBookingStatus.confirmed ||
        _phase == _BookingPhase.matched;

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Ride Status'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_rounded,
                  size: 72,
                  color: AppColors.secondaryText(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No active ride request',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Start from the ride selection screen to request a driver.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryText(
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () => context.goNamed('home'),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          isMatched ? 'Driver Found' : 'Finding Your Ride',
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.slow,
          switchInCurve: AppMotion.emphasized,
          switchOutCurve: AppMotion.standard,
          child: !isMatched
              ? _buildWaitingState(context, ride, isDark, highContrast)
              : _buildMatchedState(context, ride, isDark, highContrast),
        ),
      ),
    );
  }

  Widget _buildWaitingState(
    BuildContext context,
    dynamic ride,
    bool isDark,
    bool highContrast,
  ) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Ride request in progress',
      value: 'Searching for a nearby driver',
      child: SingleChildScrollView(
        key: const ValueKey('waiting'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Looking for the best nearby driver',
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your ${ride.name.toLowerCase()} request is live. We are checking nearby drivers and confirming the quickest pickup option.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _StatusCard(
              title: 'Request sent',
              subtitle: '${ride.priceFormatted} total - ${ride.eta}',
              icon: Icons.check_circle_rounded,
              isDark: isDark,
              highContrast: highContrast,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusCard(
              title: 'Matching nearby drivers',
              subtitle: 'Usually takes a few seconds',
              icon: Icons.radar_rounded,
              isDark: isDark,
              highContrast: highContrast,
              highlighted: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusCard(
              title: 'Next up',
              subtitle:
                  'You will move straight to live tracking once a driver accepts',
              icon: Icons.route_rounded,
              isDark: isDark,
              highContrast: highContrast,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancelRequest,
                child: const Text('Cancel Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchedState(
    BuildContext context,
    dynamic ride,
    bool isDark,
    bool highContrast,
  ) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Driver matched',
      value: '${ride.driverName} is on the way',
      child: SingleChildScrollView(
        key: const ValueKey('matched'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Your driver is on the way',
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${ride.driverName} accepted your request. You can now track the driver live and follow the pickup guidance.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.panelBackground(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(
                  color: AppColors.outline(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage: ride.driverPhoto != null
                            ? NetworkImage(ride.driverPhoto!)
                            : null,
                        child: ride.driverPhoto == null
                            ? const Icon(Icons.person_rounded)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.driverName,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              ride.vehicleModel,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.secondaryText(
                                  isDark: isDark,
                                  highContrast: highContrast,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '3 min away',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          label: 'Pickup',
                          value: ride.willPickup
                              ? 'At your location'
                              : 'Meet at driver point',
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _InfoTile(
                          label: 'Fare',
                          value: ride.priceFormatted,
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openTracking,
                child: const Text('Track Driver'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _cancelRequest,
                child: const Text('Cancel Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final bool highContrast;
  final bool highlighted;

  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.highContrast,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      value: subtitle,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.panelBackground(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppColors.softElevation(
            isDark: isDark,
            highContrast: highContrast,
            tint: highlighted ? AppColors.primary : null,
            strength: 0.9,
          ),
          border: Border.all(
            color: highlighted
                ? AppColors.softStroke(
                    isDark: isDark,
                    highContrast: highContrast,
                    tint: AppColors.primary,
                    strength: 1.1,
                  )
                : AppColors.softStroke(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.secondaryText(
                        isDark: isDark,
                        highContrast: highContrast,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highContrast;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.isDark,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      value: value,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground(
            isDark: isDark,
            highContrast: highContrast,
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.secondaryText(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
