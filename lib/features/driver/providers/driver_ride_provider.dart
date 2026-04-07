import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/vehicle_card.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/models/lat_lng_point.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/auth/auth_provider.dart';

enum DriverRideStatus {
  none,
  posted,
  findingRiders,
  accepted,
  boarding,
  enRoute,
  completed,
  cancelled
}

class DriverRideState {
  final DriverRideStatus status;
  final String from;
  final String to;
  final String time;
  final int? seats;
  final double? price;
  final VehicleType vehicleType;
  final String? riderName;
  final double? riderRating;
  final String? riderPhoto;
  final String? riderPickup;
  final String? riderDrop;

  DriverRideState({
    this.status = DriverRideStatus.none,
    this.from = '',
    this.to = '',
    this.time = '',
    this.seats,
    this.price,
    this.vehicleType = VehicleType.bike,
    this.riderName,
    this.riderRating,
    this.riderPhoto,
    this.riderPickup,
    this.riderDrop,
  });

  DriverRideState copyWith({
    DriverRideStatus? status,
    String? from,
    String? to,
    String? time,
    int? seats,
    double? price,
    VehicleType? vehicleType,
    String? riderName,
    double? riderRating,
    String? riderPhoto,
    String? riderPickup,
    String? riderDrop,
  }) {
    return DriverRideState(
      status: status ?? this.status,
      from: from ?? this.from,
      to: to ?? this.to,
      time: time ?? this.time,
      seats: seats ?? this.seats,
      price: price ?? this.price,
      vehicleType: vehicleType ?? this.vehicleType,
      riderName: riderName ?? this.riderName,
      riderRating: riderRating ?? this.riderRating,
      riderPhoto: riderPhoto ?? this.riderPhoto,
      riderPickup: riderPickup ?? this.riderPickup,
      riderDrop: riderDrop ?? this.riderDrop,
    );
  }
}

class DriverRideNotifier extends StateNotifier<DriverRideState> {
  final Ref _ref;
  String? _currentRideId;
  DriverRideNotifier(this._ref) : super(DriverRideState());

  Future<void> postRide({
    required String from,
    required String to,
    required String time,
    required int seats,
    required double price,
    required VehicleType vehicleType,
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    List<LatLngPoint>? routePolyline,
    int? distanceMeters,
    int? durationSeconds,
    String? distanceText,
    String? durationText,
  }) async {
    final authState = _ref.read(authStateProvider);
    final userProfile = _ref.read(userProfileProvider).value;
    final user = authState.value;

    if (user == null || userProfile == null) return;

    final originPoint = LatLngPoint(lat: originLat, lng: originLng);
    final destinationPoint =
        LatLngPoint(lat: destinationLat, lng: destinationLng);

    final ride = RideModel(
      driverUid: user.uid,
      driverName: userProfile.fullName,
      originAddress: from,
      originLat: originPoint.lat,
      originLng: originPoint.lng,
      destinationAddress: to,
      destinationLat: destinationPoint.lat,
      destinationLng: destinationPoint.lng,
      vehicleType: vehicleType,
      totalSeats: seats,
      availableSeats: seats,
      price: price,
      startTime: DateTime.now(),
      routePath: routePolyline ?? [originPoint, destinationPoint],
      status: RideStatus.active,
      riderUids: [],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      distanceText: distanceText,
      durationText: durationText,
    );

    await _ref.read(rideRepositoryProvider).createRide(ride);

    // Store the ride ID for location tracking (this is a simplified approach)
    // In a real app, you'd get the actual document ID from Firestore
    _currentRideId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

    state = DriverRideState(
      status: DriverRideStatus.findingRiders,
      from: from,
      to: to,
      time: time,
      seats: seats,
      price: price,
      vehicleType: vehicleType,
    );
  }

  void acceptRider({
    required String name,
    required double rating,
    String? photo,
    required String pickup,
    required String drop,
  }) {
    state = state.copyWith(
      status: DriverRideStatus.accepted,
      riderName: name,
      riderRating: rating,
      riderPhoto: photo,
      riderPickup: pickup,
      riderDrop: drop,
    );
  }

  void updateStatus(DriverRideStatus newStatus) {
    state = state.copyWith(status: newStatus);
  }

  Future<void> startLocationTracking(String rideId) async {
    _currentRideId = rideId;
    final authState = _ref.read(authStateProvider);
    final user = authState.value;

    if (user != null) {
      await _ref.read(locationServiceProvider).startLocationTracking(
            rideId,
            user.uid,
          );
    }
  }

  Future<void> startRide() async {
    if (_currentRideId != null) {
      await startLocationTracking(_currentRideId!);
      state = state.copyWith(status: DriverRideStatus.enRoute);
    }
  }

  Future<void> cancelRide() async {
    await _ref.read(locationServiceProvider).stopLocationTracking();
    state = DriverRideState();
  }
}

final driverRideProvider =
    StateNotifierProvider<DriverRideNotifier, DriverRideState>((ref) {
  return DriverRideNotifier(ref);
});
