import 'dart:async';
import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lat_lng_point.dart';

class LocationServiceException implements Exception {
  final String message;
  final dynamic originalError;

  LocationServiceException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;

  /// Check if location services are enabled and permissions are granted.
  Future<bool> checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get the current device position. Throws [LocationServiceException] on failure.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw LocationServiceException(
        'Failed to get current position. Please enable location services.',
        e,
      );
    }
  }

  /// Start tracking the driver's location for a given ride.
  ///
  /// Uses a single distance-filtered position stream instead of the previous
  /// redundant combination of a [Timer] and a stream. Each new position triggers
  /// one consolidated Firestore write to the ride document, cutting write costs
  /// by ~67 % compared to the old three-collection fan-out.
  Future<void> startLocationTracking(String rideId, String driverUid) async {
    // Cancel any previous session first.
    await stopLocationTracking();

    if (!await checkLocationPermissions()) {
      throw LocationServiceException(
        'Location permissions are required to track rides.',
      );
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update only after moving ≥10 m
      ),
    ).listen(
      (Position position) async {
        try {
          await _updateDriverLocation(rideId, driverUid, position);
        } catch (e) {
          dev.log(
            'Location update failed: $e',
            name: 'LocationService',
            error: e,
          );
        }
      },
      onError: (Object e) {
        dev.log(
          'Position stream error: $e',
          name: 'LocationService',
          error: e,
        );
      },
    );
  }

  /// Stop location tracking and cancel any active subscriptions.
  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  /// Single consolidated Firestore write per location update.
  ///
  /// Writes only to the ride document. The previous implementation fanned out
  /// to three separate collections on every update, which tripled costs and
  /// write amplification. Consumers should read location data from the ride
  /// document via [getDriverLocation].
  Future<void> _updateDriverLocation(
    String rideId,
    String driverUid,
    Position position,
  ) async {
    await _firestore.collection('rides').doc(rideId).update({
      'currentDriverLat': position.latitude,
      'currentDriverLng': position.longitude,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Stream the driver's current location from the ride document.
  Stream<LatLngPoint?> getDriverLocation(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      final lat = (data['currentDriverLat'] as num?)?.toDouble();
      final lng = (data['currentDriverLng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLngPoint(lat: lat, lng: lng);
    });
  }

  /// Get the driver's location history for a ride over the last 24 hours.
  Stream<List<LatLngPoint>> getDriverLocationHistory(String rideId) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return _firestore
        .collection('driverLocations')
        .where('rideId', isEqualTo: rideId)
        .where('timestamp', isGreaterThan: yesterday)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return LatLngPoint(
                lat: (data['latitude'] as num?)?.toDouble() ?? 0.0,
                lng: (data['longitude'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList());
  }
}
