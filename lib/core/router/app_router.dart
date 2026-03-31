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
import '../../features/eco_impact/carbon_dashboard_screen.dart';
import '../../features/eco_impact/achievements_screen.dart';
import '../../features/ride_selection/booking_status_screen.dart';
import '../../features/wallet/withdrawal_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
