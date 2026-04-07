import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/lat_lng_point.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/vehicle_card.dart';
import '../../core/providers/data_providers.dart';
import '../../core/providers/maps_providers.dart';
import '../../core/services/models/place_prediction.dart';
import 'providers/driver_ride_provider.dart';

class OfferRideScreen extends ConsumerStatefulWidget {
  const OfferRideScreen({super.key});

  @override
  ConsumerState<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends ConsumerState<OfferRideScreen> {
  // Step 1: Route
  final TextEditingController _destinationController = TextEditingController();
  String _distance = '-';
  String _duration = '-';
  String _earningsRange = '₹-- – ₹--';
  bool _isLoading = false;

  // Places Autocomplete
  List<PlacePrediction> _predictions = [];
  Timer? _searchDebounce;
  String _sessionToken = const Uuid().v4();
  bool _showPredictions = false;

  // Real coordinates from GPS + Places API
  double? _originLat;
  double? _originLng;
  double? _destLat;
  double? _destLng;

  List<LatLngPoint> _routePolyline = [];
  int? _distanceMeters;
  int? _durationSeconds;

  // Step 2: Ride Details
  bool _isBike = true;
  bool _isNow = true;
  TimeOfDay? _departureTime;
  int _availableSeats = 1;
  double _price = 0;
  bool _isLoadingPrice = false;

  // Step 3: Preferences
  bool _prefMusic = true;
  bool _prefAC = true; // Only valid if car
  bool _prefWomenOnly = false;
  bool _prefChat = true;

  @override
  void initState() {
    super.initState();
    _applySmartDefaults();
    _fetchCurrentLocation();
  }

  void _applySmartDefaults() {
    setState(() {
      _isBike = true;
      _isNow = true;
      _availableSeats = 1;
      _price = 45.0;
    });
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _originLat = position.latitude;
          _originLng = position.longitude;
        });
      }
    } catch (_) {}
  }

  void _onDestinationTextChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _predictions = [];
        _showPredictions = false;
      });
      return;
    }

    setState(() => _showPredictions = true);

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final mapsService = ref.read(googleMapsServiceProvider);
      try {
        final results = await mapsService.searchPlaces(
          query,
          sessionToken: _sessionToken,
        );
        if (mounted) {
          setState(() => _predictions = results);
        }
      } catch (_) {}
    });
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    _destinationController.text = prediction.mainText;
    setState(() {
      _showPredictions = false;
      _predictions = [];
      _isLoadingPrice = true;
    });

    final mapsService = ref.read(googleMapsServiceProvider);
    final details = await mapsService.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
    );
    _sessionToken = const Uuid().v4();

    if (details == null || !mounted) {
      setState(() => _isLoadingPrice = false);
      return;
    }

    _destLat = details.lat;
    _destLng = details.lng;


    // Get real route + distance using Directions API
    if (_originLat != null && _originLng != null) {
      final route = await mapsService.getDirections(
        origin: LatLngPoint(lat: _originLat!, lng: _originLng!),
        destination: LatLngPoint(lat: _destLat!, lng: _destLng!),
      );

      if (route != null && mounted) {
        _routePolyline = route.polylinePoints;
        _distanceMeters = route.distanceMeters;
        _durationSeconds = route.durationSeconds;

        // Compute real fare
        double serverFare;
        try {
          serverFare = await ref.read(rideRepositoryProvider).getServerFare(
                origin: LatLngPoint(lat: _originLat!, lng: _originLng!),
                destination: LatLngPoint(lat: _destLat!, lng: _destLng!),
                vehicleType: _isBike ? 'bike' : 'car',
                demandFactor: 1.0,
              );
        } catch (_) {
          serverFare = _isBike ? 50.0 : 180.0;
        }

        if (mounted) {
          setState(() {
            _distance = route.distanceText;
            _duration = route.durationText;
            _earningsRange = _isBike
                ? '₹${(serverFare * 0.8).round()}–₹${(serverFare * 1.2).round()}'
                : '₹${(serverFare * 0.8).round()}–₹${(serverFare * 1.2).round()}';
            _price = serverFare;
            _isLoadingPrice = false;
          });
        }
        return;
      }
    }

    setState(() => _isLoadingPrice = false);
  }

  /// Recalculate fare when vehicle type or seats change after destination already selected
  Future<void> _recalculateFare() async {
    if (_destLat == null || _destLng == null || _originLat == null || _originLng == null) return;
    setState(() => _isLoadingPrice = true);
    try {
      final serverFare = await ref.read(rideRepositoryProvider).getServerFare(
            origin: LatLngPoint(lat: _originLat!, lng: _originLng!),
            destination: LatLngPoint(lat: _destLat!, lng: _destLng!),
            vehicleType: _isBike ? 'bike' : 'car',
            demandFactor: 1.0,
          );
      if (mounted) {
        setState(() {
          _earningsRange = '₹${(serverFare * 0.8).round()}–₹${(serverFare * 1.2).round()}';
          _price = serverFare;
          _isLoadingPrice = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingPrice = false);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _departureTime = picked;
        _isNow = false;
      });
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post a Ride',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: ROUTE SELECTION
            _SectionHeader(title: 'Step 1: Route Selection', isDark: isDark),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  // From Display
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Auto-detected nearby point',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 24,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                  ),
                  // To Input
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _destinationController,
                          onChanged: _onDestinationTextChanged,
                          decoration: InputDecoration(
                            hintText: 'Search destination...',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondaryLight,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Predictions dropdown
            if (_showPredictions && _predictions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _predictions.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppColors.accent,
                      ),
                      title: Text(
                        prediction.mainText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        prediction.secondaryText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _onPredictionSelected(prediction),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            // Distance & Earnings Strip
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_rounded,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        _distance,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Est. Earnings: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      _isLoadingPrice
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : Text(
                              _earningsRange,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.accent,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // STEP 2: RIDE DETAILS
            _SectionHeader(title: 'Step 2: Ride Details', isDark: isDark),
            const SizedBox(height: 16),

            // Time & Vehicle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isNow = true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isNow
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Now',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: _isNow
                                          ? (isDark
                                              ? Colors.black
                                              : Colors.white)
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !_isNow
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    !_isNow && _departureTime != null
                                        ? _departureTime!.format(context)
                                        : 'Later',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize:
                                          !_isNow && _departureTime != null
                                              ? 12
                                              : 14,
                                      color: !_isNow
                                          ? (isDark
                                              ? Colors.black
                                              : Colors.white)
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isBike = true;
                                    _availableSeats = 1;
                                  });
                                  _recalculateFare();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isBike
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.directions_bike_rounded,
                                    color: _isBike
                                        ? (isDark ? Colors.black : Colors.white)
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isBike = false;
                                  });
                                  _recalculateFare();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !_isBike
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.directions_car_filled_rounded,
                                    color: !_isBike
                                        ? (isDark ? Colors.black : Colors.white)
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Seats Available',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondaryLight)),
                if (_isBike)
                  Text('Max 1 for bike',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (index) {
                final seatNum = index + 1;
                final isDisabled = _isBike && seatNum > 1;
                final isSelected = _availableSeats == seatNum;
                return Expanded(
                  child: GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() => _availableSeats = seatNum);
                            _recalculateFare();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? (isDark ? Colors.white10 : Colors.black12)
                            : isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white10 : Colors.black12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$seatNum',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDisabled
                              ? AppColors.textSecondaryLight
                                  .withValues(alpha: 0.5)
                              : isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // AI Price Editor
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Suggested Price',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'Per seat • Editable',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Editor
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            if (_price > 10) setState(() => _price -= 5);
                          },
                        ),
                        SizedBox(
                          width: 48,
                          child: Center(
                            child: Text(
                              '₹${_price.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() => _price += 5);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // STEP 3: PREFERENCES
            _SectionHeader(
                title: 'Step 3: Preferences (Optional)', isDark: isDark),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PreferenceChip(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  isSelected: _prefMusic,
                  isDark: isDark,
                  onTap: () => setState(() => _prefMusic = !_prefMusic),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: !_isBike
                      ? _PreferenceChip(
                          icon: Icons.ac_unit_rounded,
                          label: 'AC',
                          isSelected: _prefAC,
                          isDark: isDark,
                          onTap: () => setState(() => _prefAC = !_prefAC),
                        )
                      : const SizedBox.shrink(),
                ),
                _PreferenceChip(
                  icon: Icons.face_3_rounded,
                  label: 'Women only',
                  isSelected: _prefWomenOnly,
                  isDark: isDark,
                  onTap: () => setState(() => _prefWomenOnly = !_prefWomenOnly),
                ),
                _PreferenceChip(
                  icon: _prefChat
                      ? Icons.chat_bubble_rounded
                      : Icons.volume_off_rounded,
                  label: _prefChat ? 'Chat allowed' : 'Silent ride',
                  isSelected: true, // Always colored, but changes state
                  isDark: isDark,
                  onTap: () => setState(() => _prefChat = !_prefChat),
                  activeColor: _prefChat ? AppColors.primary : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        try {
                          // Update Driver Ride Provider
                          await ref.read(driverRideProvider.notifier).postRide(
                                from: 'Current Location',
                                to: _destinationController.text.isEmpty
                                    ? 'Selected Destination'
                                    : _destinationController.text,
                                time: _isNow ? 'Now' : 'Scheduled',
                                seats: _availableSeats,
                                price: _price,
                                vehicleType: _isBike
                                    ? VehicleType.bike
                                    : VehicleType.car,
                                originLat: _originLat ?? 0.0,
                                originLng: _originLng ?? 0.0,
                                destinationLat: _destLat ?? 0.0,
                                destinationLng: _destLng ?? 0.0,
                                routePolyline: _routePolyline.isNotEmpty ? _routePolyline : null,
                                distanceMeters: _distanceMeters,
                                durationSeconds: _durationSeconds,
                                distanceText: _distance != '-' ? _distance : null,
                                durationText: _duration != '-' ? _duration : null,
                              );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ Ride posted successfully!',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: AppColors.accent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          if (context.mounted) context.pop(); // Returns to Home screen
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error posting ride: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm & Post Ride',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Color? activeColor;

  const _PreferenceChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? color : (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
