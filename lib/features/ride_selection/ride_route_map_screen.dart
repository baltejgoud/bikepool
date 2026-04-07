import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/lat_lng_point.dart';
import '../../core/providers/maps_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/vehicle_card.dart';
import 'ride_booking_provider.dart';

class RideRouteMapScreen extends ConsumerStatefulWidget {
  final String destination;
  final double destinationLat;
  final double destinationLng;
  final RideOption ride;

  const RideRouteMapScreen({
    super.key,
    required this.destination,
    required this.destinationLat,
    required this.destinationLng,
    required this.ride,
  });

  @override
  ConsumerState<RideRouteMapScreen> createState() => _RideRouteMapScreenState();
}

class _RideRouteMapScreenState extends ConsumerState<RideRouteMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sheetController;
  late Animation<double> _sheetAnimation;
  bool _isBooking = false;

  // Real route data
  List<LatLng> _routePoints = [];
  LatLng? _pickupLoc;
  LatLng? _dropOffLoc;
  String _distanceText = '...';
  String _durationText = '...';
  double _distanceKm = 0;
  bool _routeLoaded = false;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
    );
    _sheetController.forward();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    // Get user's current location as pickup
    LatLng pickupLoc;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      pickupLoc = LatLng(position.latitude, position.longitude);
    } catch (_) {
      // Fallback to destination area
      pickupLoc = LatLng(widget.destinationLat - 0.01, widget.destinationLng - 0.01);
    }

    final dropOff = LatLng(widget.destinationLat, widget.destinationLng);

    // Fetch real directions
    final mapsService = ref.read(googleMapsServiceProvider);
    final route = await mapsService.getDirections(
      origin: LatLngPoint(lat: pickupLoc.latitude, lng: pickupLoc.longitude),
      destination: LatLngPoint(lat: dropOff.latitude, lng: dropOff.longitude),
    );

    if (mounted) {
      setState(() {
        _pickupLoc = pickupLoc;
        _dropOffLoc = dropOff;
        if (route != null) {
          _routePoints = route.polylinePoints
              .map((p) => LatLng(p.lat, p.lng))
              .toList();
          _distanceText = route.distanceText;
          _durationText = route.durationText;
          _distanceKm = route.distanceMeters / 1000.0;
        } else {
          // Fallback straight line
          _routePoints = [pickupLoc, dropOff];
          _distanceText = '~${(const Distance().as(LengthUnit.Kilometer, pickupLoc, dropOff)).toStringAsFixed(1)} km';
          _durationText = 'Est.';
        }
        _routeLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupLoc = _pickupLoc ?? LatLng(widget.destinationLat - 0.01, widget.destinationLng);
    final dropOffLoc = _dropOffLoc ?? LatLng(widget.destinationLat, widget.destinationLng);
    final distanceKm = _distanceKm;
    const isOffRoute = false;

    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highContrast = mediaQuery.highContrast;
    final outline = AppColors.outline(
      isDark: isDark,
      highContrast: highContrast,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const AppBackButton(),
      ),
      body: Stack(
        children: [
          Semantics(
            container: true,
            label: 'Route preview map',
            hint: 'Shows the driver location, pickup point, and destination.',
            child: ExcludeSemantics(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: pickupLoc,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: isDark ? const ['a', 'b', 'c'] : const [],
                    userAgentPackageName: 'com.bikepool.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routeLoaded && _routePoints.isNotEmpty
                            ? _routePoints
                            : [pickupLoc, dropOffLoc],
                        color: AppColors.primary,
                        strokeWidth: highContrast ? 6 : 5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Driver/Pickup Marker
                      Marker(
                        point: pickupLoc,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      // Drop-off Marker
                      Marker(
                        point: dropOffLoc,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: mediaQuery.padding.top + 56,
            left: 16,
            right: 16,
            child: Semantics(
              container: true,
              label: 'Trip summary',
              value: 'Pickup in 3 min, 12 min ride, 4.2 kilometres',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _routeLoaded
                          ? '$_durationText ride → $_distanceText'
                          : 'Loading route...',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _sheetAnimation,
            builder: (context, child) => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(
                    0,
                    (1 - _sheetAnimation.value) *
                        600), // Adjusted for taller sheet
                child: child,
              ),
            ),
            child: _buildBottomSheet(
                context, isDark, highContrast, distanceKm, isOffRoute),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, bool isDark, bool highContrast,
      double distanceKm, bool isOffRoute) {
    final theme = Theme.of(context);
    final secondaryText = AppColors.secondaryText(
      isDark: isDark,
      highContrast: highContrast,
    );
    final outline = AppColors.outline(
      isDark: isDark,
      highContrast: highContrast,
    );

    return Semantics(
      container: true,
      label: 'Ride review drawer',
      hint: 'Review driver details, pickup instructions, and confirm booking.',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground(
            isDark: isDark,
            highContrast: highContrast,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 12,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.ride.type == VehicleType.bike
                                ? Icons.directions_bike
                                : Icons.directions_car,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.ride.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (widget.ride.recommendationTag != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            widget.ride.recommendationTag!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        widget.ride.eta,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.ride.priceFormatted,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceBackground(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
                  backgroundImage: widget.ride.driverPhoto != null
                      ? NetworkImage(widget.ride.driverPhoto!)
                      : null,
                  child: widget.ride.driverPhoto == null
                      ? Icon(Icons.person_rounded, color: secondaryText)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ride.driverName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.ride.vehicleModel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Message driver',
                  icon: const Icon(
                    Icons.message_rounded,
                    color: AppColors.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCarbonBadge(distanceKm),
            if (isOffRoute) ...[
              const SizedBox(height: 16),
              _buildGetOffEarlyCard(context, isDark, highContrast),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking
                    ? null
                    : () async {
                        setState(() => _isBooking = true);
                        ref
                            .read(rideBookingProvider.notifier)
                            .startRequesting(widget.ride);

                        await Future.delayed(const Duration(seconds: 2));
                        
                        if (!mounted) return;
                        
                        ref.read(rideBookingProvider.notifier).setPending();
                        if (context.mounted) {
                          context.pushNamed('booking-status');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isBooking
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Requesting ride...',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Confirm & Book',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonBadge(double distanceKm) {
    // simple carbon footprint calculation based on distance and vehicle
    final savingFactor = widget.ride.type == VehicleType.bike ? 0.12 : 0.25;
    final savedCo2 = (distanceKm * savingFactor).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: Colors.green.shade600, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "You're saving ${savedCo2}kg CO₂ on this trip! 🌱",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetOffEarlyCard(
      BuildContext context, bool isDark, bool highContrast) {
    return GestureDetector(
      onTap: () {
        // Show confirmation dialog with map preview
        _showGetOffEarlyDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.softElevation(
            isDark: isDark,
            highContrast: highContrast,
            tint: AppColors.primary,
            strength: 0.85,
          ),
          border: Border.all(
            color: AppColors.softStroke(
              isDark: isDark,
              highContrast: highContrast,
              tint: AppColors.primary,
              strength: 1.1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get off here & walk',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get down here & walk 450m (6 min) to your destination',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showGetOffEarlyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_walk_rounded,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Walk 450m to destination?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The driver\'s route stays on the main road. Getting off early saves you a detour fee.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                // Simple placeholder for map preview
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      'Preview Walking Route Map',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // apply get off early selection
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Walking route selected!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
