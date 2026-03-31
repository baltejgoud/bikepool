import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/vehicle_card.dart';

enum RideBookingStatus { idle, requesting, pending, confirmed, declined }

class RideBookingState {
  final RideBookingStatus status;
  final RideOption? selectedRide;
  final String? rideId;

  RideBookingState({
    this.status = RideBookingStatus.idle,
    this.selectedRide,
    this.rideId,
  });

  RideBookingState copyWith({
    RideBookingStatus? status,
    RideOption? selectedRide,
    String? rideId,
  }) {
    return RideBookingState(
      status: status ?? this.status,
      selectedRide: selectedRide ?? this.selectedRide,
      rideId: rideId ?? this.rideId,
    );
  }
}

class RideBookingNotifier extends StateNotifier<RideBookingState> {
  RideBookingNotifier() : super(RideBookingState());

  void startRequesting(RideOption ride) {
    state = state.copyWith(
      status: RideBookingStatus.requesting,
      selectedRide: ride,
    );
  }

  void setPending() {
    state = state.copyWith(status: RideBookingStatus.pending);
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
