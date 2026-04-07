import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'plan_ride_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/app_pill.dart';
import '../driver/widgets/driver_dashboard_view.dart';
import '../driver/widgets/driver_rides_view.dart';
import '../wallet/wallet_view.dart';
import 'search_history_provider.dart';
import '../../core/providers/data_providers.dart';
import '../../core/models/ride_model.dart';

final userModeProvider = StateProvider<UserMode>((ref) => UserMode.rider);
final scheduledRideProvider = StateProvider<bool>((ref) => false);

enum UserMode { rider, driver }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _currentIndex == 0 ? _buildHomeAppBar() : null,
      body: _buildSelectedTabBody(),
      bottomNavigationBar: _buildBottomNav(isDark, highContrast),
    );
  }

  PreferredSizeWidget _buildHomeAppBar() {
    final mode = ref.watch(userModeProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 120, // Increased height for profile info
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userProfile.value != null) ...[
            Text(
              'Hello, ${userProfile.value!.fullName}!',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
          ],
          _buildHomeModeToggle(
            mode: mode,
            isDark: isDark,
            highContrast: highContrast,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeModeToggle({
    required UserMode mode,
    required bool isDark,
    required bool highContrast,
  }) {
    final outline = AppColors.outline(
      isDark: isDark,
      highContrast: highContrast,
    );
    final selectedBackground = Theme.of(context).colorScheme.primary;
    final outerShadow = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x1A153529);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32;
        final segmentWidth = (availableWidth - AppSpacing.xs) / 2;

        return Center(
          child: Container(
            height: 72,
            width: availableWidth,
            padding: const EdgeInsets.all(AppSpacing.xxs),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF16201D), const Color(0xFF0E1412)]
                    : [const Color(0xFFF9FCFA), const Color(0xFFF0F5F2)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: outline),
              boxShadow: [
                BoxShadow(
                  color: outerShadow,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasized,
                  left: mode == UserMode.rider ? 0 : segmentWidth,
                  width: segmentWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          selectedBackground,
                          AppColors.primary.withValues(alpha: 0.88),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.12 : 0.38,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.28 : 0.22,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildTopSegment(
                      title: 'Rider',
                      subtitle: 'Find a ride',
                      icon: Icons.person_pin_circle_rounded,
                      isSelected: mode == UserMode.rider,
                      onTap: () => ref.read(userModeProvider.notifier).state =
                          UserMode.rider,
                    ),
                    _buildTopSegment(
                      title: 'Driver',
                      subtitle: 'Start earning',
                      icon: Icons.directions_car_rounded,
                      isSelected: mode == UserMode.driver,
                      onTap: () => ref.read(userModeProvider.notifier).state =
                          UserMode.driver,
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

  Widget _buildTopSegment({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;
    final unselectedColor = AppColors.secondaryText(
      isDark: isDark,
      highContrast: highContrast,
    );
    final selectedForeground = Theme.of(context).colorScheme.onPrimary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$title mode, $subtitle',
        hint: isSelected ? 'Currently selected' : 'Double tap to switch modes',
        child: Tooltip(
          message: '$title - $subtitle',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: AnimatedContainer(
              duration: AppMotion.medium,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              color: Colors.transparent,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppColors.primary.withValues(
                              alpha: isDark ? 0.16 : 0.10,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.24)
                            : AppColors.primary.withValues(
                                alpha: isDark ? 0.14 : 0.08,
                              ),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? selectedForeground : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color:
                                isSelected ? selectedForeground : unselectedColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            color: isSelected
                                ? selectedForeground.withValues(alpha: 0.80)
                                : unselectedColor.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeBody();
      case 1:
        return _buildRidesBody();
      case 2:
        return _buildWalletBody();
      default:
        return _buildHomeBody();
    }
  }

  Widget _buildBottomNav(bool isDark, bool highContrast) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.outline(
              isDark: isDark,
              highContrast: highContrast,
            ),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            context.pushNamed('profile');
          } else {
            setState(() => _currentIndex = index);
          }
        },
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_rounded),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    final mode = ref.watch(userModeProvider);
    if (mode == UserMode.driver) {
      return _buildDriverHomeBody();
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchSection(),
              const SizedBox(height: 48),
              _buildRecentSearches(),
              const SizedBox(height: 48),
              _buildForYouSection(),
              const SizedBox(height: 48),
              _buildUpcomingRideSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBody() {
    return const WalletView();
  }


  Widget _buildSearchSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 28, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await context.pushNamed<String>('destination-search');
                if (result == 'drop_pin' && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Map selection mode is coming soon.',
                        style: GoogleFonts.inter(),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                'Where to?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: isDark ? Colors.white24 : Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          GestureDetector(
            onTap: _showScheduleRideDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_filled_rounded,
                      size: 16, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    'Later',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final history = ref.watch(searchHistoryProvider);
    
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: history.take(2).map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _buildRecentSearchItem(
          icon: Icons.history_rounded,
          title: item.title,
          subtitle: item.subtitle,
          onTap: () {
            context.goNamed('available-rides', extra: {
              'destination': '${item.title} – ${item.subtitle}',
              'lat': item.lat ?? 17.4500,
              'lng': item.lng ?? 78.3800,
              'initialVehicleType': null,
            });
          },
        ),
      )).toList(),
    );
  }

  Widget _buildRecentSearchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: isDark ? AppColors.textPrimaryDark : Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For you',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            letterSpacing: -0.6,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildRideTypeCard(
              title: 'Bike',
              icon: Icons.motorcycle_rounded,
              iconColor: Colors.orange,
              bgColor: Colors.orange.withValues(alpha: 0.1),
              onTap: () => _showPlanRideSheet(
                context,
                title: 'Bike',
                icon: Icons.motorcycle_rounded,
                color: Colors.orange,
              ),
            ),
            _buildRideTypeCard(
              title: 'Scooty',
              icon: Icons.electric_scooter_rounded,
              iconColor: Colors.blue,
              bgColor: Colors.blue.withValues(alpha: 0.1),
              onTap: () => _showPlanRideSheet(
                context,
                title: 'Scooty',
                icon: Icons.electric_scooter_rounded,
                color: Colors.blue,
              ),
            ),
            _buildRideTypeCard(
              title: '4 seat car',
              icon: Icons.directions_car_rounded,
              iconColor: Colors.green,
              bgColor: Colors.green.withValues(alpha: 0.1),
              onTap: () => _showPlanRideSheet(
                context,
                title: '4 seat car',
                icon: Icons.directions_car_rounded,
                color: Colors.green,
              ),
            ),
            _buildRideTypeCard(
              title: '7 seat car',
              icon: Icons.airport_shuttle_rounded,
              iconColor: Colors.purple,
              bgColor: Colors.purple.withValues(alpha: 0.1),
              onTap: () => _showPlanRideSheet(
                context,
                title: '7 seat car',
                icon: Icons.airport_shuttle_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRideTypeCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Icon(icon, size: 48, color: iconColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanRideSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PlanRideSheet(
          vehicleTitle: title,
          vehicleIcon: icon,
          vehicleColor: color,
        );
      },
    );
  }

  Widget _buildUpcomingRideSection() {
    final myRidesAsync = ref.watch(myRidesAsRiderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming ride',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        myRidesAsync.when(
          data: (rides) {
            final activeRide = rides.cast<RideModel?>().firstWhere(
                  (r) => r?.status != RideStatus.completed && r?.status != RideStatus.cancelled,
                  orElse: () => null,
                );
            if (activeRide != null) {
              return _buildScheduledRideCardFromModel(activeRide);
            }
            return _buildEmptyScheduledRideCard();
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => _buildEmptyScheduledRideCard(),
        ),
      ],
    );
  }

  Widget _buildScheduledRideCardFromModel(RideModel ride) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: highContrast,
          tint: AppColors.primary,
          strength: 0.95,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ride.status.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.motorcycle_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.person_pin_circle_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.destinationAddress,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Pickup: ${ride.originAddress}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyScheduledRideCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Icon(Icons.event_available_rounded,
              size: 40, color: isDark ? AppColors.textSecondaryDark : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No upcoming rides yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showScheduleRideDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primary : Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Schedule a ride',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showScheduleRideDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const _ScheduleRideSheet();
      },
    );
  }

  Widget _buildDriverHomeBody() {
    return const DriverDashboardView();
  }



  // ----- STUB SCREENS FOR NEW TABS -----

  Widget _buildRidesBody() {
    final mode = ref.watch(userModeProvider);
    if (mode == UserMode.driver) {
      return const DriverRidesView();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rides',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Your recent activities will appear here'),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // _buildAccountBody removed as it navigates directly to profile screen
}

class _ScheduleRideSheet extends ConsumerStatefulWidget {
  const _ScheduleRideSheet();

  @override
  ConsumerState<_ScheduleRideSheet> createState() => _ScheduleRideSheetState();
}

class _ScheduleRideSheetState extends ConsumerState<_ScheduleRideSheet> {
  DateTime selectedDate = DateTime.now();
  String selectedTime = 'Now';
  String selectedVehicle = '4 seat car';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Schedule a ride',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.black87,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Date Section
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = date.day == selectedDate.day &&
                          date.month == selectedDate.month &&
                          date.year == selectedDate.year;
                      final isToday = index == 0;
                      return GestureDetector(
                        onTap: () => setState(() => selectedDate = date),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected ? Colors.black : Colors.grey[200]!,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isToday
                                    ? 'Today'
                                    : _getWeekdayLabel(date.weekday),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Time Section
                Text(
                  'Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTimePill('Now'),
                    _buildTimePill('In 15 min'),
                    _buildTimePill('In 30 min'),
                    _buildTimePill('Custom time'),
                  ],
                ),
                const SizedBox(height: 24),

                // Locations Section
                Text(
                  'Pickup & Drop',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location_rounded,
                                size: 20, color: Colors.black54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Pickup location',
                                  hintStyle:
                                      GoogleFonts.inter(color: Colors.black45),
                                  border: InputBorder.none,
                                ),
                                style: GoogleFonts.inter(fontSize: 16),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon:
                                  const Icon(Icons.gps_fixed_rounded, size: 16),
                              label: const Text('Current'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue[700],
                                textStyle: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            )
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey[300], indent: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 20, color: Colors.red[500]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Drop location',
                                  hintStyle:
                                      GoogleFonts.inter(color: Colors.black45),
                                  border: InputBorder.none,
                                ),
                                style: GoogleFonts.inter(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Preferences Section
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildVehiclePill('Bike', Icons.motorcycle_rounded),
                      const SizedBox(width: 8),
                      _buildVehiclePill(
                          'Scooty', Icons.electric_scooter_rounded),
                      const SizedBox(width: 8),
                      _buildVehiclePill(
                          '4 seat car', Icons.directions_car_rounded),
                      const SizedBox(width: 8),
                      _buildVehiclePill(
                          '7 seat car', Icons.airport_shuttle_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppPill(
                        label: 'Non-smoking',
                        icon: Icons.smoke_free_rounded,
                        pillContext: AppPillContext.neutral,
                        style: AppPillStyle.soft,
                      ),
                      SizedBox(width: 8),
                      AppPill(
                        label: 'Quiet ride',
                        icon: Icons.volume_off_rounded,
                        pillContext: AppPillContext.neutral,
                        style: AppPillStyle.soft,
                      ),
                      SizedBox(width: 8),
                      AppPill(
                        label: 'Female driver only',
                        icon: Icons.female_rounded,
                        pillContext: AppPillContext.neutral,
                        style: AppPillStyle.soft,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(scheduledRideProvider.notifier).state = true;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ride scheduled successfully!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                          backgroundColor: Colors.green[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Confirm schedule',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePill(String label) {
    final isSelected = selectedTime == label;
    return AppPill(
      label: label,
      pillContext: isSelected ? AppPillContext.primary : AppPillContext.neutral,
      style: isSelected ? AppPillStyle.filled : AppPillStyle.soft,
      onTap: () => setState(() => selectedTime = label),
    );
  }

  Widget _buildVehiclePill(String label, IconData icon) {
    final isSelected = selectedVehicle == label;
    return AppPill(
      label: label,
      icon: icon,
      pillContext: isSelected ? AppPillContext.primary : AppPillContext.neutral,
      style: isSelected ? AppPillStyle.soft : AppPillStyle.outline,
      onTap: () => setState(() => selectedVehicle = label),
    );
  }

  String _getWeekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
