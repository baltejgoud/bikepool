import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_preferences_model.dart';
import '../models/ride_preferences_model.dart';
import '../user/preferences_repository.dart';
import '../auth/auth_provider.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository();
});

// Notification Preferences Providers
final notificationPreferencesProvider =
    StreamProvider.family<NotificationPreferences, String>((ref, userId) {
  return ref
      .watch(preferencesRepositoryProvider)
      .streamNotificationPreferences(userId);
});

final currentNotificationPreferencesProvider =
    StreamProvider<NotificationPreferences>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(NotificationPreferences(userId: ''));
  }

  return ref
      .watch(preferencesRepositoryProvider)
      .streamNotificationPreferences(user.uid);
});

// Ride Preferences Providers
final ridePreferencesProvider =
    StreamProvider.family<RidePreferences, String>((ref, userId) {
  return ref.watch(preferencesRepositoryProvider).streamRidePreferences(userId);
});

final currentRidePreferencesProvider = StreamProvider<RidePreferences>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(RidePreferences(userId: ''));
  }

  return ref
      .watch(preferencesRepositoryProvider)
      .streamRidePreferences(user.uid);
});

// Mutation Providers
final updateNotificationPreferenceMutationProvider =
    FutureProvider.family<void, ({String userId, String field, bool value})>(
        (ref, params) async {
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  await preferencesRepository.updateNotificationPreferencesField(
    params.userId,
    params.field,
    params.value,
  );
});

final updateRidePreferenceMutationProvider =
    FutureProvider.family<void, ({String userId, String field, dynamic value})>(
        (ref, params) async {
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  await preferencesRepository.updateRidePreferenceField(
    params.userId,
    params.field,
    params.value,
  );
});
