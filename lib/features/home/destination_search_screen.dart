import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/quick_suggestion_chip.dart';
import '../../shared/widgets/app_back_button.dart';
import '../shared_widgets/skeleton_loaders/skeleton_loaders.dart';

class DestinationSearchScreen extends StatefulWidget {
  final String currentLocationLabel;
  final String currentAddress;

  const DestinationSearchScreen({
    super.key,
    required this.currentLocationLabel,
    required this.currentAddress,
  });

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _destinationController = TextEditingController();
  bool _hasText = false;
  bool _isSearching = false;
  List<_PlaceSuggestion> _filteredSuggestions = [];

  final List<_PlaceSuggestion> _suggestions = const [
    _PlaceSuggestion(
      label: 'Office',
      address: 'Madhapur, Hyderabad',
      icon: Icons.work_outline_rounded,
    ),
    _PlaceSuggestion(
      label: 'Home',
      address: 'Kukatpally, Hyderabad',
      icon: Icons.home_rounded,
    ),
    _PlaceSuggestion(
      label: 'Airport',
      address: 'Rajiv Gandhi International Airport',
      icon: Icons.flight_takeoff_rounded,
    ),
    _PlaceSuggestion(
      label: 'Mall',
      address: 'Gachibowli, Hyderabad',
      icon: Icons.shopping_bag_rounded,
    ),
    _PlaceSuggestion(
      label: 'Station',
      address: 'Secunderabad Railway Station',
      icon: Icons.train_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = _suggestions;
    _destinationController.addListener(() {
      _onSearchChanged(_destinationController.text);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _hasText = query.isNotEmpty;
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        if (query.isEmpty) {
          _filteredSuggestions = _suggestions;
        } else {
          _filteredSuggestions = _suggestions
              .where((s) =>
                  s.label.toLowerCase().contains(query.toLowerCase()) ||
                  s.address.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      });
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _navigateToRideSelection(String destination) {
    if (destination.isEmpty) return;
    context.goNamed('available-rides', extra: {
      'destination': destination,
      'lat': 17.4500,
      'lng': 78.3800,
      'initialVehicleType': null, // Show mixed types
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Choose destination'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentLocationCard(isDark),
            const SizedBox(height: 18),
            _buildSearchField(isDark),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'Searching...' : 'Suggestions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isSearching
                  ? ListView(
                      children: [
                        SearchResultSkeleton(isDark: isDark),
                        SearchResultSkeleton(isDark: isDark),
                        SearchResultSkeleton(isDark: isDark),
                      ],
                    )
                  : _filteredSuggestions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '🔍',
                                style: TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No places found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching for a different location',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: _filteredSuggestions.map((suggestion) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: QuickSuggestionChip(
                                icon: suggestion.icon,
                                label: suggestion.label,
                                address: suggestion.address,
                                isDark: isDark,
                                onTap: () => _navigateToRideSelection(
                                  '${suggestion.label} – ${suggestion.address}',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionIcons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionIcons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionIcon(Icons.home_rounded, 'Home', isDark),
        _buildQuickActionIcon(Icons.work_rounded, 'Office', isDark),
        _buildQuickActionIcon(Icons.star_rounded, 'Saved', isDark),
      ],
    );
  }

  Widget _buildQuickActionIcon(IconData icon, String label, bool isDark) {
    return InkWell(
      onTap: () => _navigateToRideSelection(label),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentLocationLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.currentAddress,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _destinationController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Where are you going?',
                border: InputBorder.none,
                filled: false,
                isDense: true,
              ),
              onSubmitted: _navigateToRideSelection,
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () => setState(() {
                _destinationController.clear();
              }),
              child: const Icon(Icons.close_rounded, size: 20),
            ),
        ],
      ),
    );
  }
}

class _PlaceSuggestion {
  final String label;
  final String address;
  final IconData icon;

  const _PlaceSuggestion({
    required this.label,
    required this.address,
    required this.icon,
  });
}
