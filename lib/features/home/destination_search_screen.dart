import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/models/place_prediction.dart';
import '../../core/services/google_maps_service.dart';
import '../../core/providers/maps_providers.dart';
import '../../core/theme/app_colors.dart';
import 'search_history_provider.dart';

class DestinationSearchScreen extends ConsumerStatefulWidget {
  final String currentLocationLabel;
  final String currentAddress;

  const DestinationSearchScreen({
    super.key,
    required this.currentLocationLabel,
    required this.currentAddress,
  });

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _sessionToken = const Uuid().v4();

  // User's current location for origin coordinates
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
      }
    } catch (_) {
      // Fall back — user can still search manually
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _predictions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final mapsService = ref.read(googleMapsServiceProvider);
      try {
        final results = await mapsService.searchPlaces(
          query,
          sessionToken: _sessionToken,
        );
        if (mounted) {
          setState(() {
            _predictions = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          if (e is MapsApiException) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An unexpected error occurred'), behavior: SnackBarBehavior.floating),
            );
          }
        }
      }
    });
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    setState(() => _isLoading = true);

    final mapsService = ref.read(googleMapsServiceProvider);
    try {
      final details = await mapsService.getPlaceDetails(
        prediction.placeId,
        sessionToken: _sessionToken,
      );

      // Reset session token for next search session
      _sessionToken = const Uuid().v4();

      if (details != null && mounted) {
        // Save to search history
        ref.read(searchHistoryProvider.notifier).addSearch(
              SearchHistoryItem(
                title: prediction.mainText,
                subtitle: prediction.secondaryText,
                lat: details.lat,
                lng: details.lng,
                placeId: prediction.placeId,
              ),
            );

        context.pushNamed(
          'available-rides',
          extra: {
            'destination': prediction.mainText,
            'lat': details.lat,
            'lng': details.lng,
            'originLat': _currentLat,
            'originLng': _currentLng,
          },
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e is MapsApiException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred fetching details'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  void _onHistoryItemSelected(SearchHistoryItem item) {
    if (item.lat != null && item.lng != null) {
      context.pushNamed(
        'available-rides',
        extra: {
          'destination': item.title,
          'lat': item.lat,
          'lng': item.lng,
          'originLat': _currentLat,
          'originLng': _currentLng,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchHistory = ref.watch(searchHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showHistory = _searchController.text.isEmpty && _predictions.isEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Where to?',
          style: GoogleFonts.inter(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Search Bar ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassMorphismDark : AppColors.glassMorphism,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : AppColors.primary.withValues(alpha: 0.1),
              ),
              boxShadow: AppColors.softElevation(isDark: isDark, highContrast: false),
            ),
            child: Column(
              children: [
                // Current location row
                _buildLocationRow(
                  icon: Icons.my_location,
                  iconColor: const Color(0xFF4ADE80),
                  label: widget.currentAddress.isNotEmpty
                      ? widget.currentAddress
                      : widget.currentLocationLabel,
                  isOrigin: true,
                ),
                Divider(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.08) 
                      : AppColors.primary.withValues(alpha: 0.08),
                  height: 1,
                  indent: 52,
                ),
                // Destination search input
                _buildSearchInput(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Loading indicator ─────────────────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

          // ─── Results / History ─────────────────────────────────────
          Expanded(
            child: showHistory
                ? _buildHistoryAndQuickActions(searchHistory)
                : _buildPredictionsList(),
          ),

          // ─── Powered by Google ─────────────────────────────────────
          if (_predictions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Powered by ',
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Google',
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isOrigin,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          Icon(Icons.search, 
               color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5), 
               size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search destination...',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close,
                  color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5), 
                  size: 18),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_predictions.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.2) : AppColors.textSecondaryLight.withValues(alpha: 0.2), 
                size: 48),
            const SizedBox(height: 12),
            Text(
              'No places found',
              style: GoogleFonts.inter(
                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.4) : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // Pop with a special value indicating manual pick
                context.pop('drop_pin');
              },
              icon: Icon(
                Icons.pin_drop,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
              ),
              label: Text(
                'Drop a Pin on Map',
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.5)
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return _buildPredictionTile(prediction);
      },
    );
  }

  Widget _buildPredictionTile(PlacePrediction prediction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _onPredictionSelected(prediction),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
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
                    prediction.mainText,
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prediction.secondaryText,
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.north_east,
              color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.3) : AppColors.textSecondaryLight.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryAndQuickActions(List<SearchHistoryItem> history) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // ─── Quick Actions ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickAction(Icons.home_outlined, 'Home'),
              _buildQuickAction(Icons.work_outline, 'Office'),
              _buildQuickAction(Icons.bookmark_border, 'Saved'),
            ],
          ),
        ),

        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    ref.read(searchHistoryProvider.notifier).clearHistory(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      color: AppColors.error.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map((item) => _buildHistoryTile(item)),
        ] else ...[
          // ─── Empty State ───────────────────────────────────────────
          const SizedBox(height: 60),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.softElevation(isDark: isDark, highContrast: false),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.3) : AppColors.textSecondaryLight.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No recent searches',
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent destinations will appear here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryTile(SearchHistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _onHistoryItemSelected(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
              child: Icon(
                Icons.history,
                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.inter(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        _searchController.text = label;
        _onSearchChanged(label);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.1),
          ),
          boxShadow: AppColors.softElevation(isDark: isDark, highContrast: false),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, 
                 color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, 
                 size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
