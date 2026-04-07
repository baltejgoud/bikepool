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
  Timer? _locationUpdateTimer;

  /// Check if location services are enabled and permissions are granted
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

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw LocationServiceException('Failed to get current position. Please enable location services.', e);
    }
  }

  /// Start tracking location for a driver during a ride
  Future<void> startLocationTracking(String rideId, String driverUid) async {
    // Stop any existing tracking
    await stopLocationTracking();

    // Check permissions
    if (!await checkLocationPermissions()) {
      throw LocationServiceException('Location permissions are required to track rides.');
    }

    // Start periodic location updates (every 10 seconds)
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        try {
          final position = await getCurrentPosition();
          if (position != null) {
            await _updateDriverLocation(rideId, driverUid, position);
          }
        } catch (e) {
          // Log error but don't crash the timer
          dev.log('Background location update failed: $e', name: 'LocationService', error: e);
        }
      },
    );

    // Also listen to position changes for more responsive updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    ).listen((Position position) async {
      try {
        await _updateDriverLocation(rideId, driverUid, position);
      } catch (e) {
        dev.log('Background location stream failed: $e', name: 'LocationService', error: e);
      }
    });
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    _positionStream?.cancel();
    _positionStream = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Update driver's current location in Firestore
  Future<void> _updateDriverLocation(
      String rideId, String driverUid, Position position) async {
    final locationData = {
      'rideId': rideId,
      'driverUid': driverUid,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'heading': position.heading,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Store in a subcollection under the ride document
    await _firestore
        .collection('rides')
        .doc(rideId)
        .collection('driverLocation')
        .doc('current')
        .set(locationData);

    // Also update the ride document with current location
    await _firestore.collection('rides').doc(rideId).update({
      'currentDriverLat': position.latitude,
      'currentDriverLng': position.longitude,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });

    // Also store in a separate collection for easier querying
    await _firestore
        .collection('driverLocations')
        .doc('${rideId}_$driverUid')
        .set(locationData);
  }

  /// Get driver's current location for a ride
  Stream<LatLngPoint?> getDriverLocation(String rideId) {
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

  /// Get driver's location history for a ride (last 24 hours)
  Stream<List<LatLngPoint>> getDriverLocationHistory(String rideId) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return _firestore
        .collection('driverLocations')
        .where('rideId', isEqualTo: rideId)
        .where('timestamp', isGreaterThan: yesterday)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LatLngPoint(
          lat: data['latitude'] ?? 0.0,
          lng: data['longitude'] ?? 0.0,
        );
      }).toList();
    });
  }
}
