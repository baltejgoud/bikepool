import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/providers/data_providers.dart';
import '../../core/models/ride_request_model.dart';
import '../../shared/widgets/app_back_button.dart';
import 'ride_booking_provider.dart';

class BookingStatusScreen extends ConsumerStatefulWidget {
  const BookingStatusScreen({super.key});

  @override
  ConsumerState<BookingStatusScreen> createState() =>
      _BookingStatusScreenState();
}

class _BookingStatusScreenState extends ConsumerState<BookingStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  // Tracks whether we've already reacted to a terminal status to avoid
  // double-navigation (the stream can emit more than once).
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _cancelRequest() async {
    final bookingState = ref.read(rideBookingProvider);
    final requestId = bookingState.requestId;

    if (requestId != null && requestId.isNotEmpty) {
      try {
        await ref
            .read(rideRepositoryProvider)
            .updateRideRequestStatus(requestId, RideRequestStatus.cancelled);
      } catch (_) {
        // Best-effort cancel — we still navigate away
      }
    }

    ref.read(rideBookingProvider.notifier).reset();
    if (mounted) context.goNamed('home');
  }

  void _openTracking() {
    final rideId = ref.read(rideBookingProvider).rideId;
    if (rideId == null || rideId.isEmpty) {
      context.goNamed('home');
      return;
    }
    context.goNamed('tracking', extra: {'rideId': rideId});
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(rideBookingProvider);
    final ride = bookingState.selectedRide;
    final requestId = bookingState.requestId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    // ── Empty-state guard ─────────────────────────────────────────────────
    if (ride == null) {
      return _buildEmptyState(context, isDark, highContrast);
    }

    // ── Real-time Firestore listener ──────────────────────────────────────
    final requestAsync = ref.watch(singleRideRequestProvider(requestId));

    return requestAsync.when(
      loading: () => _buildScaffold(
        context: context,
        isDark: isDark,
        highContrast: highContrast,
        ride: ride,
        child: _buildWaitingState(context, ride, isDark, highContrast),
      ),
      error: (e, _) => _buildScaffold(
        context: context,
        isDark: isDark,
        highContrast: highContrast,
        ride: ride,
        child: _buildErrorState(context, e.toString(), isDark, highContrast),
      ),
      data: (request) {
        // React to terminal states exactly once
        if (!_handled && request != null) {
          if (request.status == RideRequestStatus.accepted) {
            _handled = true;
            ref
                .read(rideBookingProvider.notifier)
                .confirmRide(request.rideId);
          } else if (request.status == RideRequestStatus.declined ||
              request.status == RideRequestStatus.cancelled) {
            _handled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    request.status == RideRequestStatus.declined
                        ? 'Driver declined your request. Try another ride.'
                        : 'Your request was cancelled.',
                  ),
                ),
              );
              ref.read(rideBookingProvider.notifier).reset();
              context.goNamed('home');
            });
          }
        }

        final isAccepted = request?.status == RideRequestStatus.accepted ||
            bookingState.status == RideBookingStatus.confirmed;

        return _buildScaffold(
          context: context,
          isDark: isDark,
          highContrast: highContrast,
          ride: ride,
          isMatched: isAccepted,
          child: AnimatedSwitcher(
            duration: AppMotion.slow,
            switchInCurve: AppMotion.emphasized,
            switchOutCurve: AppMotion.standard,
            child: isAccepted
                ? _buildMatchedState(
                    context, ride, request, isDark, highContrast)
                : _buildWaitingState(context, ride, isDark, highContrast),
          ),
        );
      },
    );
  }

  // ─── Scaffold wrapper ───────────────────────────────────────────────────

  Widget _buildScaffold({
    required BuildContext context,
    required bool isDark,
    required bool highContrast,
    required dynamic ride,
    Widget? child,
    bool isMatched = false,
  }) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(isMatched ? 'Driver Found' : 'Finding Your Ride'),
      ),
      body: SafeArea(child: child ?? const SizedBox.shrink()),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmptyState(
      BuildContext context, bool isDark, bool highContrast) {
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

  // ─── Error state ────────────────────────────────────────────────────────

  Widget _buildErrorState(
    BuildContext context,
    String error,
    bool isDark,
    bool highContrast,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: AppColors.secondaryText(isDark: isDark, highContrast: highContrast),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Connection issue',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unable to track your request right now. Please check your connection.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText(
                        isDark: isDark, highContrast: highContrast),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: _cancelRequest,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Waiting state ───────────────────────────────────────────────────────

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
      value: 'Waiting for driver to accept',
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
              'Waiting for driver to accept',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your ${ride.name.toLowerCase()} request has been sent. The driver will accept or decline shortly.',
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
              subtitle: '${ride.priceFormatted} total · ${ride.eta}',
              icon: Icons.check_circle_rounded,
              isDark: isDark,
              highContrast: highContrast,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusCard(
              title: 'Awaiting driver response',
              subtitle: 'The driver is reviewing your request',
              icon: Icons.hourglass_top_rounded,
              isDark: isDark,
              highContrast: highContrast,
              highlighted: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusCard(
              title: 'Next up',
              subtitle:
                  'You will move straight to live tracking once the driver accepts',
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

  // ─── Matched / accepted state ────────────────────────────────────────────

  Widget _buildMatchedState(
    BuildContext context,
    dynamic ride,
    RideRequestModel? request,
    bool isDark,
    bool highContrast,
  ) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Driver accepted',
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
              'Your driver is on the way!',
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${ride.driverName} accepted your request. Track the driver live below.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Driver card
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
                      // Live badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Live',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
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
                          value: request != null
                              ? '₹${request.price.toStringAsFixed(0)}'
                              : ride.priceFormatted,
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                      ),
                    ],
                  ),
                  if (request != null && request.estimatedTime.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            label: 'ETA',
                            value: request.estimatedTime,
                            isDark: isDark,
                            highContrast: highContrast,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _InfoTile(
                            label: 'Pickup Point',
                            value: request.pickupLocation.isNotEmpty
                                ? request.pickupLocation
                                : ride.origin,
                            isDark: isDark,
                            highContrast: highContrast,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openTracking,
                child: const Text('Track Driver Live'),
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

// ─── Reusable widgets ──────────────────────────────────────────────────────────

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
