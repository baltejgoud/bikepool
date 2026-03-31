import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride_alert.dart';

// Provider for managing ride alerts
final rideAlertsProvider =
    StateNotifierProvider<RideAlertNotifier, List<RideAlert>>((ref) {
  return RideAlertNotifier();
});

class RideAlertNotifier extends StateNotifier<List<RideAlert>> {
  RideAlertNotifier() : super([]);

  void addAlert(RideAlert alert) {
    state = [...state, alert];
  }

  void removeAlert(String alertId) {
    state = state.where((alert) => alert.id != alertId).toList();
  }

  void deactivateAlert(String alertId) {
    state = state
        .map((alert) => alert.id == alertId
            ? RideAlert(
                id: alert.id,
                source: alert.source,
                destination: alert.destination,
                type: alert.type,
                scheduledTime: alert.scheduledTime,
                createdAt: alert.createdAt,
                isActive: false,
              )
            : alert)
        .toList();
  }

  bool hasActiveAlertFor(String destination) {
    return state.any(
        (alert) => alert.isActive && alert.destination.contains(destination));
  }

  List<RideAlert> getActiveAlerts() {
    return state.where((alert) => alert.isActive).toList();
  }
}
