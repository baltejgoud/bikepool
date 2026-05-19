import 'dart:async';
import 'dart:io' show Platform;
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

    // iOS only grants LocationPermission.whileInUse via the standard prompt.
    // The Geolocator stream is silently paused when the app is backgrounded
    // unless the user has granted LocationPermission.always. Request the
    // upgrade here; if the user declines we continue but log a warning so
    // the silent tracking failure is visible in the debug console.
    if (Platform.isIOS) {
      final current = await Geolocator.checkPermission();
      if (current == LocationPermission.whileInUse) {
        final upgraded = await Geolocator.requestPermission();
        if (upgraded != LocationPermission.always) {
          dev.log(
            'Background location permission not granted (got: $upgraded). '
            'Driver tracking will stop when the app is backgrounded on iOS.',
            name: 'LocationService',
          );
        }
      }
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
  /// Writes to a dedicated 'locations' collection to separate high-frequency 
  /// GPS updates from the slower-moving 'rides' document.
  Future<void> _updateDriverLocation(
    String rideId,
    String driverUid,
    Position position,
  ) async {
    await _firestore.collection('locations').doc(rideId).set({
      'driverUid': driverUid,
      'currentDriverLat': position.latitude,
      'currentDriverLng': position.longitude,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream the driver's current location from the dedicated locations document.
  Stream<LatLngPoint?> getDriverLocation(String rideId) {
    return _firestore
        .collection('locations')
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

}
