import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lat_lng_point.dart';

class LocationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream driver's current location for a specific ride.
  /// Now reads directly from the ride document's top-level fields for speed and cost-efficiency.
  Stream<LatLngPoint?> getDriverCurrentLocation(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final lat = (data['currentDriverLat'] as num?)?.toDouble();
        final lng = (data['currentDriverLng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return LatLngPoint(lat: lat, lng: lng);
        }
      }
      return null;
    });
  }

  /// Get driver's last known location for a ride (useful for initial map centering).
  Future<LatLngPoint?> getDriverLastLocation(String rideId) async {
    final doc = await _firestore.collection('rides').doc(rideId).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final lat = (data['currentDriverLat'] as num?)?.toDouble();
      final lng = (data['currentDriverLng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return LatLngPoint(lat: lat, lng: lng);
      }
    }
    return null;
  }

  /// Update driver's current location in the ride document.
  Future<void> updateDriverLocationInRide(
      String rideId, LatLngPoint location) async {
    await _firestore.collection('rides').doc(rideId).update({
      'currentDriverLat': location.lat,
      'currentDriverLng': location.lng,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Stream multiple drivers' locations for riders to see nearby drivers.
  Stream<Map<String, LatLngPoint>> getNearbyDriversLocations(
      List<String> rideIds) {
    if (rideIds.isEmpty) return Stream.value({});

    // Observe the entire rides collection for specific ride IDs to get real-time location updates
    return _firestore
        .collection('rides')
        .where(FieldPath.documentId, whereIn: rideIds)
        .snapshots()
        .map((snapshot) {
      final locations = <String, LatLngPoint>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat = (data['currentDriverLat'] as num?)?.toDouble();
        final lng = (data['currentDriverLng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          locations[doc.id] = LatLngPoint(lat: lat, lng: lng);
        }
      }
      return locations;
    });
  }
}
