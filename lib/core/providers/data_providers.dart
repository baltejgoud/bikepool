import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../user/user_repository.dart';
import '../ride/ride_repository.dart';
import '../ride/location_repository.dart';
import '../services/location_service.dart';
import '../services/chat_service.dart';
import '../models/lat_lng_point.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/ride_request_model.dart';
import '../models/message_model.dart';
import '../../features/eco_impact/models/carbon_saved.dart';
import '../../features/eco_impact/models/milestone.dart';
import '../../shared/widgets/vehicle_card.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);

  return ref.watch(userRepositoryProvider).streamUserProfile(user.uid);
});

final availableRidesProvider =
    StreamProvider.family<List<RideModel>, String?>((ref, originCity) {
  return ref
      .watch(rideRepositoryProvider)
      .getAvailableRides(originCity: originCity);
});

/// Geohash-based nearby rides provider. Pass lat, lng, and optional radius.
final nearbyRidesProvider =
    StreamProvider.family<List<RideModel>, Map<String, double>>((ref, params) {
  return ref.watch(rideRepositoryProvider).getNearbyRides(
        lat: params['lat'] ?? 0.0,
        lng: params['lng'] ?? 0.0,
        radiusKm: params['radiusKm'] ?? 10.0,
      );
});

final myRidesAsDriverProvider = StreamProvider<List<RideModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  final repository = ref.watch(rideRepositoryProvider);
  return repository.getMyRidesAsDriver(user.uid);
});

final rideRequestsProvider = StreamProvider.family<List<RideRequestModel>, String>((ref, rideId) {
  if (rideId.isEmpty) return const Stream.empty();
  
  final repository = ref.watch(rideRepositoryProvider);
  return repository.streamRideRequestsForRide(rideId);
});

final myRidesAsRiderProvider = StreamProvider<List<RideModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value([]);

  return ref.watch(rideRepositoryProvider).getMyRidesAsRider(user.uid);
});
final matchedRidesProvider =
    StreamProvider.family<List<RideModel>, Map<String, double>>(
        (ref, coordinates) {
  final origin = LatLngPoint(
    lat: coordinates['originLat'] ?? 0.0,
    lng: coordinates['originLng'] ?? 0.0,
  );

  final destination = LatLngPoint(
    lat: coordinates['destinationLat'] ?? 0.0,
    lng: coordinates['destinationLng'] ?? 0.0,
  );

  return ref.watch(rideRepositoryProvider).getMatchedRides(
        riderOrigin: origin,
        riderDestination: destination,
      );
});

/// Provider for a single ride's real-time state
final rideProvider = StreamProvider.family<RideModel?, String>((ref, rideId) {
  return ref.watch(rideRepositoryProvider).streamRide(rideId);
});

/// Provider for driver's current location during a ride
final driverLocationProvider =
    StreamProvider.family<LatLngPoint?, String>((ref, rideId) {
  return ref.watch(locationRepositoryProvider).getDriverCurrentLocation(rideId);
});

/// Provider for driver's last known location (useful for initial map state)
final driverLastLocationProvider =
    FutureProvider.family<LatLngPoint?, String>((ref, rideId) {
  return ref.watch(locationRepositoryProvider).getDriverLastLocation(rideId);
});

/// Provider for chat messages in a specific ride
final rideMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, rideId) {
  return ref.watch(chatServiceProvider).getMessages(rideId);
});

/// Provider for calculating carbon saved from user's rides.
///
/// This is a synchronously-derived value computed from [myRidesAsRiderProvider].
/// Using a plain [Provider] instead of a [StreamProvider] returning Stream.value
/// communicates intent more clearly and avoids unnecessary stream overhead.
final carbonSavedProvider = Provider<CarbonSaved>((ref) {
  final ridesAsync = ref.watch(myRidesAsRiderProvider);

  return ridesAsync.when(
    data: (rides) {
      // Filter completed rides only
      final completedRides =
          rides.where((ride) => ride.status == RideStatus.completed).toList();

      if (completedRides.isEmpty) {
        return const CarbonSaved(
          totalKg: 0.0,
          totalRides: 0,
          averagePerRide: 0.0,
          monthlyBreakdown: {},
        );
      }

      // Average car CO2 emissions: ~0.25 kg per km
      // Bike CO2 emissions: ~0.12 kg per km
      double totalCo2Saved = 0.0;
      final monthlyBreakdown = <String, double>{};

      for (final ride in completedRides) {
        final distanceKm = (ride.distanceMeters?.toDouble() ?? 10.0) / 1000.0;
        final savingsFactor =
            ride.vehicleType == VehicleType.bike ? 0.12 : 0.25;
        final savedCo2 = distanceKm * savingsFactor;

        totalCo2Saved += savedCo2;

        final monthKey = _getMonthKey(ride.startTime);
        monthlyBreakdown[monthKey] =
            (monthlyBreakdown[monthKey] ?? 0.0) + savedCo2;
      }

      final averagePerRide = completedRides.isNotEmpty
          ? totalCo2Saved / completedRides.length
          : 0.0;

      return CarbonSaved(
        totalKg: totalCo2Saved,
        totalRides: completedRides.length,
        averagePerRide: averagePerRide,
        monthlyBreakdown: monthlyBreakdown,
      );
    },
    loading: () => const CarbonSaved(
      totalKg: 0.0,
      totalRides: 0,
      averagePerRide: 0.0,
      monthlyBreakdown: {},
    ),
    error: (_, __) => const CarbonSaved(
      totalKg: 0.0,
      totalRides: 0,
      averagePerRide: 0.0,
      monthlyBreakdown: {},
    ),
  );
});

String _getMonthKey(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[date.month - 1];
}

/// Provider for calculating user milestones based on actual rides.
///
/// Converted from [StreamProvider] to [Provider] — the value is computed
/// synchronously from the upstream [myRidesAsRiderProvider] stream. Riverpod
/// handles reactivity automatically, so no manual Stream.value wrapping is needed.
///
/// **completedAt fix**: Carbon-based milestone completion dates are now derived
/// from the ride that pushed the running total over the threshold, so they
/// remain stable across app restarts instead of being re-set to [DateTime.now]
/// every rebuild.
final userMilestonesProvider = Provider<List<Milestone>>((ref) {
  final ridesAsync = ref.watch(myRidesAsRiderProvider);

  return ridesAsync.when(
    data: (rides) {
      if (rides.isEmpty) return _generateDefaultMilestones();

      final completedRides =
          rides.where((r) => r.status == RideStatus.completed).toList();
      final totalRides = completedRides.length;

      // Running totals for carbon-based milestones
      double runningCo2 = 0.0;
      DateTime? carbon100CompletedAt;
      DateTime? carbon250CompletedAt;

      for (final ride in completedRides) {
        final distanceKm = (ride.distanceMeters?.toDouble() ?? 10.0) / 1000.0;
        final savingsFactor =
            ride.vehicleType == VehicleType.bike ? 0.12 : 0.25;
        runningCo2 += distanceKm * savingsFactor;

        // Record the exact ride date when the threshold was first crossed.
        if (carbon100CompletedAt == null && runningCo2 >= 100) {
          carbon100CompletedAt = ride.startTime;
        }
        if (carbon250CompletedAt == null && runningCo2 >= 250) {
          carbon250CompletedAt = ride.startTime;
        }
      }

      final totalCo2 = runningCo2;

      // Streak: # of rides in the last 7 days (simplified heuristic)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentRides = completedRides
          .where((r) => r.startTime.isAfter(sevenDaysAgo))
          .toList();
      final streakCompleted = recentRides.length >= 7;

      return [
        Milestone(
          id: 'first_ride',
          title: 'First Pool',
          description: 'Complete your first shared ride',
          type: MilestoneType.rides,
          targetValue: 1,
          currentValue: totalRides >= 1 ? 1 : 0,
          badgeIcon: '🌱',
          isCompleted: totalRides >= 1,
          completedAt: totalRides >= 1 ? completedRides.first.startTime : null,
        ),
        Milestone(
          id: 'silver_pooler',
          title: 'Silver Pooler',
          description: 'Complete 25 shared rides',
          type: MilestoneType.rides,
          targetValue: 25,
          currentValue: totalRides,
          badgeIcon: '🥈',
          isCompleted: totalRides >= 25,
          completedAt: totalRides >= 25 ? completedRides[24].startTime : null,
        ),
        Milestone(
          id: 'gold_pooler',
          title: 'Gold Pooler',
          description: 'Complete 50 shared rides',
          type: MilestoneType.rides,
          targetValue: 50,
          currentValue: totalRides,
          badgeIcon: '🥇',
          isCompleted: totalRides >= 50,
          completedAt: totalRides >= 50 ? completedRides[49].startTime : null,
        ),
        Milestone(
          id: 'carbon_saver',
          title: 'Carbon Saver',
          description: 'Save 100kg of CO2',
          type: MilestoneType.carbon,
          targetValue: 100,
          currentValue: totalCo2.toInt(),
          badgeIcon: '🌍',
          isCompleted: totalCo2 >= 100,
          // Stable date — the ride that pushed us over 100 kg, not DateTime.now()
          completedAt: carbon100CompletedAt,
        ),
        Milestone(
          id: 'eco_warrior',
          title: 'Eco Warrior',
          description: 'Save 250kg of CO2',
          type: MilestoneType.carbon,
          targetValue: 250,
          currentValue: totalCo2.toInt(),
          badgeIcon: '🛡️',
          isCompleted: totalCo2 >= 250,
          // Stable date — the ride that pushed us over 250 kg, not DateTime.now()
          completedAt: carbon250CompletedAt,
        ),
        Milestone(
          id: 'streak_master',
          title: 'Streak Master',
          description: 'Complete rides for 7 consecutive days',
          type: MilestoneType.streak,
          targetValue: 7,
          currentValue: recentRides.length,
          badgeIcon: '🔥',
          isCompleted: streakCompleted,
          completedAt:
              streakCompleted ? recentRides.last.startTime : null,
        ),
      ];
    },
    loading: () => _generateDefaultMilestones(),
    error: (_, __) => _generateDefaultMilestones(),
  );
});

/// Generate default milestones with no progress
List<Milestone> _generateDefaultMilestones() {
  return [
    const Milestone(
      id: 'first_ride',
      title: 'First Pool',
      description: 'Complete your first shared ride',
      type: MilestoneType.rides,
      targetValue: 1,
      currentValue: 0,
      badgeIcon: '🌱',
    ),
    const Milestone(
      id: 'silver_pooler',
      title: 'Silver Pooler',
      description: 'Complete 25 shared rides',
      type: MilestoneType.rides,
      targetValue: 25,
      currentValue: 0,
      badgeIcon: '🥈',
    ),
    const Milestone(
      id: 'gold_pooler',
      title: 'Gold Pooler',
      description: 'Complete 50 shared rides',
      type: MilestoneType.rides,
      targetValue: 50,
      currentValue: 0,
      badgeIcon: '🥇',
    ),
    const Milestone(
      id: 'carbon_saver',
      title: 'Carbon Saver',
      description: 'Save 100kg of CO2',
      type: MilestoneType.carbon,
      targetValue: 100,
      currentValue: 0,
      badgeIcon: '🌍',
    ),
    const Milestone(
      id: 'eco_warrior',
      title: 'Eco Warrior',
      description: 'Save 250kg of CO2',
      type: MilestoneType.carbon,
      targetValue: 250,
      currentValue: 0,
      badgeIcon: '🛡️',
    ),
    const Milestone(
      id: 'streak_master',
      title: 'Streak Master',
      description: 'Complete rides for 7 consecutive days',
      type: MilestoneType.streak,
      targetValue: 7,
      currentValue: 0,
      badgeIcon: '🔥',
    ),
  ];
}
