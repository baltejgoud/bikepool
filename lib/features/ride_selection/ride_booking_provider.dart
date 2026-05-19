import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/vehicle_card.dart';

enum RideBookingStatus { idle, requesting, pending, confirmed, declined }

class RideBookingState {
  final RideBookingStatus status;
  final RideOption? selectedRide;
  final String? rideId;
  final String? requestId;

  RideBookingState({
    this.status = RideBookingStatus.idle,
    this.selectedRide,
    this.rideId,
    this.requestId,
  });

  RideBookingState copyWith({
    RideBookingStatus? status,
    RideOption? selectedRide,
    String? rideId,
    String? requestId,
  }) {
    return RideBookingState(
      status: status ?? this.status,
      selectedRide: selectedRide ?? this.selectedRide,
      rideId: rideId ?? this.rideId,
      requestId: requestId ?? this.requestId,
    );
  }
}

class RideBookingNotifier extends StateNotifier<RideBookingState> {
  RideBookingNotifier() : super(RideBookingState());

  void startRequesting(RideOption ride, {String? requestId}) {
    state = state.copyWith(
      status: RideBookingStatus.requesting,
      selectedRide: ride,
      rideId: ride.rideId,
      requestId: requestId,
    );
  }

  void setPending({String? requestId}) {
    state = state.copyWith(
      status: RideBookingStatus.pending,
      requestId: requestId ?? state.requestId,
    );
  }

  void confirmRide(String rideId) {
    state = state.copyWith(
      status: RideBookingStatus.confirmed,
      rideId: rideId,
    );
  }

  void declineRide() {
    state = state.copyWith(status: RideBookingStatus.declined);
  }

  void reset() {
    state = RideBookingState();
  }
}

final rideBookingProvider =
    StateNotifierProvider<RideBookingNotifier, RideBookingState>((ref) {
  return RideBookingNotifier();
});
