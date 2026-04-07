import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_preferences_model.dart';
import '../models/ride_preferences_model.dart';
import 'package:flutter/foundation.dart';

class PreferencesException implements Exception {
  final String message;
  PreferencesException(this.message);

  @override
  String toString() => message;
}

class PreferencesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification Preferences Methods
  Stream<NotificationPreferences> streamNotificationPreferences(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('notification')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return NotificationPreferences(userId: userId);
      }
      return NotificationPreferences.fromFirestore(doc);
    });
  }

  Future<NotificationPreferences> getNotificationPreferences(
      String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification')
          .get();

      if (!doc.exists) {
        return NotificationPreferences(userId: userId);
      }

      return NotificationPreferences.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
      throw PreferencesException('Failed to load notification preferences. Please try again.');
    }
  }

  Future<void> updateNotificationPreferences(
      String userId, NotificationPreferences preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification')
          .set(preferences.toFirestore());
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      throw PreferencesException('Failed to update notification preferences. Please try again.');
    }
  }

  Future<void> updateNotificationPreferencesField(
    String userId,
    String field,
    bool value,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification')
          .update({
        field: value,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating notification preference field: $e');
      throw PreferencesException('Failed to update preference. Please try again.');
    }
  }

  // Ride Preferences Methods
  Stream<RidePreferences> streamRidePreferences(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('ride')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return RidePreferences(userId: userId);
      }
      return RidePreferences.fromFirestore(doc);
    });
  }

  Future<RidePreferences> getRidePreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('ride')
          .get();

      if (!doc.exists) {
        return RidePreferences(userId: userId);
      }

      return RidePreferences.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching ride preferences: $e');
      throw PreferencesException('Failed to load ride preferences. Please try again.');
    }
  }

  Future<void> updateRidePreferences(
      String userId, RidePreferences preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('ride')
          .set(preferences.toFirestore());
    } catch (e) {
      debugPrint('Error updating ride preferences: $e');
      throw PreferencesException('Failed to update ride preferences. Please try again.');
    }
  }

  Future<void> updateRidePreferenceField(
    String userId,
    String field,
    dynamic value,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('ride')
          .update({
        field: value,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating ride preference field: $e');
      throw PreferencesException('Failed to update ride preference. Please try again.');
    }
  }
}
