import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/app_back_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class _RideUserProfile {
  final String name;
  final double rating;
  final String vehicle;
  final String licensePlate;
  final List<String> badges;
  final List<String> mutualConnections;
  final int totalRides;
  final List<_Review> reviews;

  const _RideUserProfile({
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.licensePlate,
    required this.badges,
    required this.mutualConnections,
    required this.totalRides,
    required this.reviews,
  });
}

class _Review {
  final String author;
  final String comment;
  final double rating;

  const _Review({
    required this.author,
    required this.comment,
    required this.rating,
  });
}

class TrackingScreen extends ConsumerStatefulWidget {
  final String rideId;

  const TrackingScreen({super.key, required this.rideId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  late AnimationController _pulseController;
  bool _sosVisible = false;
  bool _showTopPickupGuidance = true;
  late final _RideUserProfile _driverProfile;

  @override
  void initState() {
    super.initState();
    _driverProfile = const _RideUserProfile(
      name: 'Rahul M.',
      rating: 4.8,
      vehicle: 'Honda Activa - Black',
      licensePlate: 'TS 09 EF 6723',
      badges: ['Govt ID Verified', 'Company Email Verified'],
      mutualConnections: ['Ananya K.', 'Siddharth P.', 'Nikita R.'],
      totalRides: 124,
      reviews: [
        _Review(
          author: 'Ananya K.',
          comment: 'Smooth ride and great conversation!',
          rating: 5.0,
        ),
        _Review(
          author: 'Siddharth P.',
          comment: 'On time, safe driving, would ride again.',
          rating: 4.7,
        ),
        _Review(
          author: 'Nikita R.',
          comment: 'Very friendly and helpful with my luggage.',
          rating: 4.9,
        ),
      ],
    );
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _panelAnimation =
        CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic);
    _panelController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _panelController.dispose();
    _pulseController.dispose();
    _chatTextController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = mediaQuery.highContrast;
    // Watch the ride and driver location in real-time
    final driverLocationAsync =
        ref.watch(driverLocationProvider(widget.rideId));

    // Default route points (fallback)
    const defaultRoutePoints = [
      LatLng(17.4435, 78.3772),
      LatLng(17.4460, 78.3820),
      LatLng(17.4500, 78.3900),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Semantics(
            container: true,
            label: 'Ride tracking map',
            hint:
                'Shows the driver on the way to your destination. Ride details are in the bottom drawer.',
            child: ExcludeSemantics(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: driverLocationAsync.value != null
                      ? LatLng(driverLocationAsync.value!.lat,
                          driverLocationAsync.value!.lng)
                      : defaultRoutePoints[0],
                  initialZoom: 14.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: isDark ? ['a', 'b', 'c'] : [],
                    userAgentPackageName: 'com.bikepool.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: defaultRoutePoints,
                        color: AppColors.primary,
                        strokeWidth: highContrast ? 7 : 6,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: driverLocationAsync.value != null
                            ? LatLng(driverLocationAsync.value!.lat,
                                driverLocationAsync.value!.lng)
                            : defaultRoutePoints[0],
                        width: 80,
                        height: 80,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing Rings
                                ...List.generate(2, (index) {
                                  final progress =
                                      (_pulseController.value + (index * 0.5)) %
                                          1.0;
                                  return Container(
                                    width: 80 * progress,
                                    height: 80 * progress,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 1.0 - progress),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                }),
                                // Main Marker
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                            alpha: highContrast ? 0.65 : 0.50),
                                        blurRadius: highContrast ? 8 : 12,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: highContrast ? 2 : 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.directions_bike_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Marker(
                        point: defaultRoutePoints.last,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.accent,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              color: AppColors.mapScrim(
                isDark: isDark,
                highContrast: highContrast,
              ),
            ),
          ),
          Positioned(
            top: mediaQuery.padding.top + 16,
            left: 8,
            child: const AppBackButton(),
          ),
          _buildTopStatusCards(mediaQuery, isDark, highContrast),
          Positioned(
            top: mediaQuery.padding.top + 16,
            right: 16,
            child: Semantics(
              button: true,
              toggled: _sosVisible,
              label: 'Emergency options',
              hint: _sosVisible
                  ? 'Hide emergency actions'
                  : 'Show emergency actions',
              child: GestureDetector(
                onTap: () {
                  setState(() => _sosVisible = !_sosVisible);
                  HapticFeedback.heavyImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _sosVisible ? AppColors.error : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: _sosVisible ? 4 : 0,
                      ),
                    ],
                    border: Border.all(
                      color: _sosVisible ? Colors.white : AppColors.error,
                      width: highContrast ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'SOS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _sosVisible ? Colors.white : AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_sosVisible)
            Positioned(
              top: mediaQuery.padding.top + 80,
              right: 16,
              child: _buildEmergencyCard(isDark, highContrast, driverLocationAsync),
            ),
          AnimatedBuilder(
            animation: _panelAnimation,
            builder: (context, child) => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, (1 - _panelAnimation.value) * 300),
                child: child,
              ),
            ),
            child: _buildDriverPanel(
              context: context,
              isDark: isDark,
              highContrast: highContrast,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusCards(
    MediaQueryData mediaQuery,
    bool isDark,
    bool highContrast,
  ) {
    return Positioned(
      top: mediaQuery.padding.top + AppSpacing.md,
      left: 72,
      right: 84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground(
                isDark: isDark,
                highContrast: highContrast,
              ),
              borderRadius: BorderRadius.circular(AppRadii.pill),
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Driver arriving in 3 min',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (_showTopPickupGuidance) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.panelBackground(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: AppColors.outline(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: AppElevation.cardBlur,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Pickup guidance',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryText(
                              isDark: isDark,
                              highContrast: highContrast,
                            ),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Hide pickup guidance',
                        hint: 'Dismiss this card to see more of the map',
                        child: InkWell(
                          onTap: () {
                            setState(() => _showTopPickupGuidance = false);
                            HapticFeedback.selectionClick();
                          },
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.secondaryText(
                                isDark: isDark,
                                highContrast: highContrast,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Meet near Metro Station Gate A',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Walk 120 m to the pickup point. The driver will stop on the main road.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
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
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(bool isDark, bool highContrast, AsyncValue<dynamic> driverLocationAsync) {
    return Semantics(
      container: true,
      label: 'Emergency actions card',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panelBackground(
            isDark: isDark,
            highContrast: highContrast,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softElevation(
            isDark: isDark,
            highContrast: highContrast,
            strength: 0.9,
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
            Text('Emergency?',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(160, 40),
              ),
              onPressed: () async {
                const url = 'tel:112';
                if (await canLaunchUrlString(url)) {
                  await launchUrlString(url);
                }
              },
              child: const Text('Call Emergency'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(160, 40),
              ),
              onPressed: () {
                String locationText = 'Emergency! I need help.';
                if (driverLocationAsync.value != null) {
                  final lat = driverLocationAsync.value!.lat;
                  final lng = driverLocationAsync.value!.lng;
                  locationText = 'Emergency! My ride is currently at: https://maps.google.com/?q=$lat,$lng';
                }
                SharePlus.instance.share(ShareParams(text: locationText));
              },
              child: const Text('Share Location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverPanel({
    required BuildContext context,
    required bool isDark,
    required bool highContrast,
  }) {
    final mediaQuery = MediaQuery.of(context);

    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Ride status drawer',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground(
            isDark: isDark,
            highContrast: highContrast,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: highContrast ? 0.24 : 0.20),
              blurRadius: highContrast ? 16 : 32,
              offset: const Offset(0, -8),
            ),
          ],
          border: Border.all(
            color: AppColors.outline(
              isDark: isDark,
              highContrast: highContrast,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: mediaQuery.size.height * 0.60),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTripSnapshot(isDark, highContrast),
                  const SizedBox(height: 16),
                  _buildJourneyProgress(isDark, highContrast),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: 'Driver profile',
                    hint: 'Opens full driver details',
                    child: InkWell(
                      onTap: () => _openDriverProfile(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverProfile.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: _driverProfile.badges
                                        .map((badge) => _buildBadge(badge))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFC107),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_driverProfile.rating}',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _driverProfile.licensePlate,
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
                                  Text(
                                    _driverProfile.vehicle,
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
                            ),
                            Column(
                              children: [
                                _ActionCircleButton(
                                  label: 'Chat with driver',
                                  icon: Icons.chat_bubble_rounded,
                                  onTap: () => _openChatSheet(context),
                                ),
                                const SizedBox(height: 10),
                                _ActionCircleButton(
                                  label: 'Call driver',
                                  icon: Icons.call_rounded,
                                  onTap: () => _showCallDialog(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPickupGuidanceCard(isDark, highContrast),
                  const SizedBox(height: 16),
                  Semantics(
                    container: true,
                    label: 'Ride start code',
                    value: '4 8 7 2',
                    hint: 'Share this OTP with the driver to start the ride',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBackground(
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.outline(
                            isDark: isDark,
                            highContrast: highContrast,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share OTP with driver to start ride',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.secondaryText(
                                      isDark: isDark,
                                      highContrast: highContrast,
                                    ),
                                  ),
                                ),
                                Text(
                                  '4 8 7 2',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 6,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showShareDialog(context),
                          icon: const Icon(Icons.share_location_rounded),
                          label: const Text('Share Status'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: BorderSide(
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                            foregroundColor: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.goNamed('home'),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5),
                            ),
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripSnapshot(bool isDark, bool highContrast) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground(
          isDark: isDark,
          highContrast: highContrast,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: highContrast,
          strength: 0.8,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current trip',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  'ETA 8 min',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 32,
                    color: AppColors.outline(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText(
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                      ),
                    ),
                    Text(
                      'Metro Station Gate A',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Drop-off',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText(
                          isDark: isDark,
                          highContrast: highContrast,
                        ),
                      ),
                    ),
                    Text(
                      'Ameerpet Office Hub',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyProgress(bool isDark, bool highContrast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip progress',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryText(
              isDark: isDark,
              highContrast: highContrast,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ProgressStep(
                title: 'Driver on the way',
                isComplete: true,
                isActive: true,
                isDark: isDark,
                highContrast: highContrast,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ProgressStep(
                title: 'Meet at pickup',
                isComplete: false,
                isActive: false,
                isDark: isDark,
                highContrast: highContrast,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ProgressStep(
                title: 'Ride starts',
                isComplete: false,
                isActive: false,
                isDark: isDark,
                highContrast: highContrast,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickupGuidanceCard(bool isDark, bool highContrast) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground(
          isDark: isDark,
          highContrast: highContrast,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: highContrast,
          strength: 0.8,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: highContrast,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Walk 120 m to Metro Station Gate A',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Wait by the main-road pickup bay. The driver is approaching from the south side.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
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
    );
  }

  Widget _buildBadge(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            badge,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Share Live Status'),
        content: const Text(
          'Share your live ride tracking link with a contact via WhatsApp or SMS.',
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share via WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _openDriverProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final highContrast = MediaQuery.of(ctx).highContrast;

        return Semantics(
          container: true,
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: 'Driver profile bottom sheet',
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.panelBackground(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: AppColors.outline(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ExcludeSemantics(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driverProfile.name,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFC107),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_driverProfile.rating}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_driverProfile.totalRides} rides',
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
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openChatSheet(context);
                          },
                          icon: const Icon(Icons.chat_bubble_rounded),
                          color: AppColors.primary,
                          tooltip: 'Chat',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCallDialog(context);
                          },
                          icon: const Icon(Icons.call_rounded),
                          color: AppColors.primary,
                          tooltip: 'Call',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _driverProfile.badges.map(_buildBadge).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Mutual connections',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _driverProfile.mutualConnections.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final name = _driverProfile.mutualConnections[index];
                          return Semantics(
                            label: 'Mutual connection $name',
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.18),
                                  child: Text(
                                    name
                                        .split(' ')
                                        .map((part) => part[0])
                                        .join(),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.secondaryText(
                                      isDark: isDark,
                                      highContrast: highContrast,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Passenger reviews',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._driverProfile.reviews.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.18),
                              child: Text(
                                review.author
                                    .split(' ')
                                    .map((part) => part[0])
                                    .join(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        review.author,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFC107),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${review.rating}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    review.comment,
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  final _chatTextController = TextEditingController();
  final _chatScrollController = ScrollController();

  void _sendMessage(String text, WidgetRef ref) async {
    if (text.trim().isEmpty) return;
    final content = text.trim();
    _chatTextController.clear();
    final userProfile = ref.read(userProfileProvider).value;
    await ref.read(chatServiceProvider).sendMessage(
          rideId: widget.rideId,
          senderId: FirebaseAuth.instance.currentUser?.uid ?? '',
          senderName: userProfile?.fullName ?? 'User',
          text: content,
        );
  }

  void _openChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final highContrast = MediaQuery.of(context).highContrast;
            final messagesAsync =
                ref.watch(rideMessagesProvider(widget.rideId));

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.panelBackground(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Chat',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Flexible(
                      child: messagesAsync.when(
                        data: (messages) => ListView.builder(
                          controller: _chatScrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shrinkWrap: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId ==
                                FirebaseAuth.instance.currentUser?.uid;
                            return _ChatBubble(
                              message: message.text,
                              isMe: isMe,
                              timestamp: message.timestamp,
                            );
                          },
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatTextController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (val) => _sendMessage(val, ref),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () =>
                                  _sendMessage(_chatTextController.text, ref),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _chatTextController.clear();
    });
  }

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Call driver anonymously'),
        content: const Text(
          'This will place an anonymous call to your driver without sharing your phone number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final result = await FirebaseFunctions.instance
                    .httpsCallable('initiateMaskedCall')
                    .call({
                  'rideId': widget.rideId,
                });

                if (result.data['success'] == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connecting call...')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to call: ${result.data['error']}')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.call_rounded),
            label: const Text('Call now'),
          ),
        ],
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCircleButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final bool isComplete;
  final bool isActive;
  final bool isDark;
  final bool highContrast;

  const _ProgressStep({
    required this.title,
    required this.isComplete,
    required this.isActive,
    required this.isDark,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isComplete || isActive
        ? AppColors.primary
        : AppColors.secondaryText(
            isDark: isDark,
            highContrast: highContrast,
          );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: (isComplete || isActive)
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceBackground(
                isDark: isDark,
                highContrast: highContrast,
              ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: (isComplete || isActive)
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.outline(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isComplete
                ? Icons.check_circle_rounded
                : Icons.radio_button_checked,
            size: 16,
            color: color,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('h:mm a').format(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.primary
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
