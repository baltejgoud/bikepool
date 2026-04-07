import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/destination_search_screen.dart';
import '../../features/ride_selection/available_rides_screen.dart';
import '../../features/ride_selection/ride_route_map_screen.dart';
import '../../shared/widgets/vehicle_card.dart';
import '../../features/ride_tracking/tracking_screen.dart';
import '../../features/driver/offer_ride_screen.dart';
import '../../features/driver/request_management_screen.dart';
import '../../features/driver/driver_dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/profile_setup_screen.dart';
import '../../features/profile/notification_settings_screen.dart';
import '../../features/profile/ride_preferences_screen.dart';
import '../../features/profile/help_safety_screen.dart';
import '../../features/eco_impact/carbon_dashboard_screen.dart';
import '../../features/eco_impact/achievements_screen.dart';
import '../../features/ride_selection/booking_status_screen.dart';
import '../../features/wallet/withdrawal_screen.dart';
import '../auth/auth_provider.dart';
import '../providers/data_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userProfile = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/onboarding';
      final isSettingUpProfile = state.matchedLocation == '/profile-setup';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/onboarding';
      }

      if (isLoggingIn) {
        return '/home';
      }

      // Profile completion check
      if (isLoggedIn && !isSettingUpProfile) {
        final profile = userProfile.value;
        // If we have profile data and it's not complete, redirect
        if (userProfile.hasValue && (profile == null || !profile.isProfileCompleted)) {
          return '/profile-setup';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProfileSetupScreen(
            initialStep: extra?['step'] ?? 0,
            returnToProfile: extra?['returnToProfile'] ?? false,
          );
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'destination-search',
            name: 'destination-search',
            builder: (context, state) => const DestinationSearchScreen(
              currentLocationLabel: 'Your location',
              currentAddress: 'Kukatpally, Hyderabad',
            ),
          ),
          GoRoute(
            path: 'available-rides',
            name: 'available-rides',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AvailableRidesScreen(
                destination: extra?['destination'] ?? '',
                destinationLat: extra?['lat'] ?? 17.3850,
                destinationLng: extra?['lng'] ?? 78.4867,
                initialVehicleType: extra?['initialVehicleType'],
              );
            },
          ),
          GoRoute(
            path: 'ride-route-map',
            name: 'ride-route-map',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return RideRouteMapScreen(
                destination: extra?['destination'] ?? '',
                destinationLat: extra?['lat'] ?? 17.3850,
                destinationLng: extra?['lng'] ?? 78.4867,
                ride: extra?['ride'] as RideOption,
              );
            },
          ),
          GoRoute(
            path: 'tracking',
            name: 'tracking',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return TrackingScreen(rideId: extra?['rideId'] ?? '');
            },
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'carbon-dashboard',
                name: 'carbon-dashboard',
                builder: (context, state) => const CarbonDashboardScreen(),
              ),
              GoRoute(
                path: 'achievements',
                name: 'achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
              GoRoute(
                path: 'notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'ride-preferences',
                name: 'ride-preferences',
                builder: (context, state) => const RidePreferencesScreen(),
              ),
              GoRoute(
                path: 'help-safety',
                name: 'help-safety',
                builder: (context, state) => const HelpSafetyScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'withdraw',
            name: 'withdraw',
            builder: (context, state) => const WithdrawalScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/offer-ride',
        name: 'offer-ride',
        builder: (context, state) => const OfferRideScreen(),
      ),
      GoRoute(
        path: '/request-management',
        name: 'request-management',
        builder: (context, state) => const RequestManagementScreen(),
      ),
      GoRoute(
        path: '/booking-status',
        name: 'booking-status',
        builder: (context, state) => const BookingStatusScreen(),
      ),
      GoRoute(
        path: '/driver-dashboard',
        name: 'driver-dashboard',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
    ],
  );
});
