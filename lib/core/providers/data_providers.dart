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
import '../models/message_model.dart';

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
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value([]);

  return ref.watch(rideRepositoryProvider).getMyRidesAsDriver(user.uid);
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
