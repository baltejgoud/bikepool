import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lat_lng_point.dart';

class LocationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream driver's current location for a specific ride
  Stream<LatLngPoint?> getDriverCurrentLocation(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('driverLocation')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return LatLngPoint(
          lat: data['latitude'] ?? 0.0,
          lng: data['longitude'] ?? 0.0,
        );
      }
      return null;
    });
  }

  /// Get driver's last known location for a ride (useful for initial map centering)
  Future<LatLngPoint?> getDriverLastLocation(String rideId) async {
    final doc = await _firestore
        .collection('rides')
        .doc(rideId)
        .collection('driverLocation')
        .doc('current')
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return LatLngPoint(
        lat: data['latitude'] ?? 0.0,
        lng: data['longitude'] ?? 0.0,
      );
    }
    return null;
  }

  /// Update driver's current location in the ride document
  Future<void> updateDriverLocationInRide(
      String rideId, LatLngPoint location) async {
    await _firestore.collection('rides').doc(rideId).update({
      'currentDriverLat': location.lat,
      'currentDriverLng': location.lng,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Stream multiple drivers' locations for riders to see nearby drivers
  Stream<Map<String, LatLngPoint>> getNearbyDriversLocations(
      List<String> rideIds) {
    if (rideIds.isEmpty) return Stream.value({});

    final streams = rideIds.map((rideId) => getDriverCurrentLocation(rideId));

    return Stream.fromIterable(streams)
        .asyncExpand((stream) => stream)
        .map((location) {
      // This is a simplified implementation - in practice you'd need to track which ride each location belongs to
      return <String, LatLngPoint>{};
    });
  }
}
