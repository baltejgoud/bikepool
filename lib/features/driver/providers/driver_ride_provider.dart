import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/vehicle_card.dart';

enum DriverRideStatus { none, posted, findingRiders, accepted, boarding, enRoute, completed, cancelled }

class DriverRideState {
  final DriverRideStatus status;
  final String from;
  final String to;
  final String time;
  final int seats;
  final double price;
  final VehicleType vehicleType;
  final String? riderName;
  final double? riderRating;
  final String? riderPhoto;
  final String? riderPickup;  // Added the exact pickup loc
  final String? riderDrop;    // Added the exact drop loc

  DriverRideState({
    this.status = DriverRideStatus.none,
    this.from = '',
    this.to = '',
    this.time = '',
    this.seats = 1,
    this.price = 0,
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
  DriverRideNotifier() : super(DriverRideState());

  void postRide({
    required String from,
    required String to,
    required String time,
    required int seats,
    required double price,
    required VehicleType vehicleType,
  }) {
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

  void cancelRide() {
    state = DriverRideState();
  }
}

final driverRideProvider =
    StateNotifierProvider<DriverRideNotifier, DriverRideState>((ref) {
  return DriverRideNotifier();
});
