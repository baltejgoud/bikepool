import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'plan_ride_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/vehicle_card.dart';
import '../../shared/widgets/count_up_number.dart';
import '../../shared/widgets/staggered_entrance.dart';
import '../ride_selection/ride_booking_provider.dart';
import '../driver/providers/driver_ride_provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 96,
      title: _buildHomeModeToggle(
        mode: mode,
        isDark: isDark,
        highContrast: highContrast,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF12312A), const Color(0xFF0F1F1A)]
                      : [const Color(0xFF000000), const Color(0xFF2D2D2D)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white70, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CountUpNumber(
                    value: 1240.0,
                    prefix: '₹',
                    decimalPlaces: 2,
                    curve: Curves.easeOutQuart,
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Transfer', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pushNamed('withdraw'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Withdraw', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Transactions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 0,
              child: _buildTransactionItem(
                title: 'Ride to Inorbit Mall',
                subtitle: 'Oct 10, 11:15 AM',
                amount: '-₹120.00',
                isDebit: true,
              ),
            ),
            StaggeredEntrance(
              index: 1,
              child: _buildTransactionItem(
                title: 'Wallet Top-up',
                subtitle: 'Oct 09, 08:30 PM',
                amount: '+₹500.00',
                isDebit: false,
              ),
            ),
            StaggeredEntrance(
              index: 2,
              child: _buildTransactionItem(
                title: 'Ride to Jubilee Hills',
                subtitle: 'Oct 08, 05:30 PM',
                amount: '-₹45.00',
                isDebit: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required bool isDebit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDebit
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
              color: isDebit ? Colors.red : Colors.green,
              size: 20,
            ),
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
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDebit ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
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
              onTap: () => context.goNamed('destination-search'),
              child: Text(
                'Where to?',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
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
    return Column(
      children: [
        _buildRecentSearchItem(
          icon: Icons.history_rounded,
          title: '17, Golnaka',
          subtitle: 'Alwal, Secunderabad, Hyderabad, Telangana...',
        ),
        const SizedBox(height: 20),
        _buildRecentSearchItem(
          icon: Icons.history_rounded,
          title: 'Suchitra',
          subtitle: 'Alwal, Secunderabad, Telangana',
        ),
      ],
    );
  }

  Widget _buildRecentSearchItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {},
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
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
    final bookingState = ref.watch(rideBookingProvider);
    final isConfirmed = bookingState.status == RideBookingStatus.confirmed;
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
        if (isConfirmed && bookingState.selectedRide != null)
          _buildScheduledRideCard(bookingState.selectedRide!)
        else
          _buildEmptyScheduledRideCard(),
      ],
    );
  }

  Widget _buildEmptyScheduledRideCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
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

  Widget _buildScheduledRideCard(RideOption ride) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Ready to Pickup',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Icon(
                ride.type == VehicleType.bike
                    ? Icons.motorcycle_rounded
                    : Icons.directions_car_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.person_pin_circle_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.driverName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                    ),
                  ),
                  Text(
                    ride.vehicleModel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 18, color: isDark ? AppColors.textSecondaryDark : Colors.black54),
              const SizedBox(width: 14),
              Text(
                'Meeting at: ${ride.willPickup ? "Your Location" : "Driver Location"}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.pushNamed('tracking', extra: {'rideId': 'BK_123'}),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Track Ride',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          )
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
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDriverMetrics(),
              const SizedBox(height: 32),
              _buildCurrentRideSection(),
              const SizedBox(height: 32),
              _buildPostRideSection(),
              const SizedBox(height: 32),
              _buildRecentActivitySection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverMetrics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Daily Earned',
            value: '₹250',
            icon: Icons.account_balance_wallet_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Current Rating',
            value: '4.91',
            icon: Icons.star_rounded,
            isDark: isDark,
            iconColor: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostRideSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.pushNamed('offer-ride'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [AppColors.primary.withValues(alpha: 0.8), AppColors.primary.withValues(alpha: 0.4)]
                : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Abstract background icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.directions_car_rounded,
                size: 100,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_road_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Offer a ride',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your empty seats,\nreduce traffic & split costs.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get started',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRideSection() {
    final rideState = ref.watch(driverRideProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (rideState.status == DriverRideStatus.none) {
      return const SizedBox.shrink();
    }

    final isFindingRiders = rideState.status == DriverRideStatus.findingRiders || rideState.status == DriverRideStatus.posted;
    final isAccepted = rideState.status == DriverRideStatus.accepted;
    final isBoarding = rideState.status == DriverRideStatus.boarding;
    final isEnRoute = rideState.status == DriverRideStatus.enRoute;

    String getStatusText() {
      if (isFindingRiders) return 'FINDING RIDERS';
      if (isAccepted) return 'RIDER ACCEPTED';
      if (isBoarding) return 'AWAITING BOARDING';
      if (isEnRoute) return 'EN ROUTE';
      return 'ONGOING RIDE';
    }

    Color getStatusColor() {
      if (isFindingRiders) return Colors.amber[700]!;
      if (isAccepted) return AppColors.primary;
      if (isBoarding) return Colors.orange;
      if (isEnRoute) return Colors.indigoAccent;
      return AppColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current ride',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map preview mock
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primary),
                      ),
                      Container(
                        width: 100,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: getStatusColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFindingRiders ? Icons.radar_rounded 
                                : isEnRoute ? Icons.navigation_rounded 
                                : Icons.check_circle_outline_rounded,
                                size: 16,
                                color: getStatusColor(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getStatusText(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          rideState.time,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Route
                    Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.primary, width: 2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 24,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rideState.from,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                rideState.to,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    // Rider Info or Details
                    if (!isFindingRiders)
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.person_rounded,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rideState.riderName?.isNotEmpty == true ? rideState.riderName! : 'Rider',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      rideState.riderRating?.toString() ?? '5.0',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Dynamic Action Button
                          if (isAccepted)
                            ElevatedButton(
                              onPressed: () {
                                ref.read(driverRideProvider.notifier).updateStatus(DriverRideStatus.enRoute);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text('Start Trip', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            )
                          else if (isEnRoute)
                            ElevatedButton(
                              onPressed: () {
                                ref.read(driverRideProvider.notifier).updateStatus(DriverRideStatus.none);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text('End Trip', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      )
                    else 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  rideState.vehicleType == VehicleType.bike
                                      ? Icons.motorcycle_rounded
                                      : Icons.directions_car_rounded,
                                  size: 20,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${rideState.seats} seats available • ₹${rideState.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => context.pushNamed('request-management'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Row(
                              children: [
                                Text('Manage', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    final mode = ref.watch(userModeProvider);
    final isDriver = mode == UserMode.driver;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent activity',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecentRideCard(
          route: 'Alwal → Hitech City',
          date: 'Yesterday, 08:30 AM',
          vehicleIcon: Icons.motorcycle_rounded,
          status: 'Completed',
          statusColor: Colors.green[700]!,
          onPostAgain: isDriver
              ? () {
                  ref.read(driverRideProvider.notifier).postRide(
                        from: 'Alwal',
                        to: 'Hitech City',
                        time: 'Now',
                        seats: 1,
                        price: 150,
                        vehicleType: VehicleType.bike,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ride Posted Again!')),
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        _buildRecentRideCard(
          route: 'Suchitra → Secunderabad Station',
          date: 'Yesterday, 06:15 PM',
          vehicleIcon: Icons.directions_car_rounded,
          status: 'Canceled',
          statusColor: Colors.red[600]!,
          onPostAgain: isDriver
              ? () {
                  ref.read(driverRideProvider.notifier).postRide(
                        from: 'Suchitra',
                        to: 'Secunderabad Station',
                        time: 'Now',
                        seats: 3,
                        price: 300,
                        vehicleType: VehicleType.car,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ride Posted Again!')),
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        _buildRecentRideCard(
          route: 'Alwal → Gachibowli',
          date: 'Oct 20, 09:00 AM',
          vehicleIcon: Icons.motorcycle_rounded,
          status: 'Completed',
          statusColor: Colors.green[700]!,
          onPostAgain: isDriver
              ? () {
                  ref.read(driverRideProvider.notifier).postRide(
                        from: 'Alwal',
                        to: 'Gachibowli',
                        time: 'Now',
                        seats: 1,
                        price: 200,
                        vehicleType: VehicleType.bike,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ride Posted Again!')),
                  );
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildRecentRideCard({
    required String route,
    required String date,
    required IconData vehicleIcon,
    required String status,
    required Color statusColor,
    VoidCallback? onPostAgain,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(vehicleIcon, size: 24, color: isDark ? AppColors.textSecondaryDark : Colors.blueGrey[800]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (onPostAgain != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onPostAgain,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Post Again',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  // ----- STUB SCREENS FOR NEW TABS -----

  Widget _buildRidesBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rides',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            _buildRecentActivitySection(),
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
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTimeChip('Now'),
                    _buildTimeChip('In 15 min'),
                    _buildTimeChip('In 30 min'),
                    _buildTimeChip('Custom time'),
                  ],
                ),
                const SizedBox(height: 24),

                // Locations Section
                Text(
                  'Pickup & Drop',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildVehicleChip('Bike', Icons.motorcycle_rounded),
                      const SizedBox(width: 8),
                      _buildVehicleChip(
                          'Scooty', Icons.electric_scooter_rounded),
                      const SizedBox(width: 8),
                      _buildVehicleChip(
                          '4 seat car', Icons.directions_car_rounded),
                      const SizedBox(width: 8),
                      _buildVehicleChip(
                          '7 seat car', Icons.airport_shuttle_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPreferenceChip(
                          'Non-smoking', Icons.smoke_free_rounded),
                      const SizedBox(width: 8),
                      _buildPreferenceChip(
                          'Quiet ride', Icons.volume_off_rounded),
                      const SizedBox(width: 8),
                      _buildPreferenceChip(
                          'Female driver only', Icons.female_rounded),
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
                              style: GoogleFonts.inter()),
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

  Widget _buildTimeChip(String label) {
    final isSelected = selectedTime == label;
    return GestureDetector(
      onTap: () => setState(() => selectedTime = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[200]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleChip(String label, IconData icon) {
    final isSelected = selectedVehicle == label;
    return GestureDetector(
      onTap: () => setState(() => selectedVehicle = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue[700] : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blue[800] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
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
