import 'dart:async';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lat_lng_point.dart';
import '../models/ride_model.dart';
import '../models/ride_request_model.dart';
import '../services/geohash_service.dart';
import '../services/google_maps_service.dart';

class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleMapsService _mapsService;

  RideRepository({GoogleMapsService? mapsService})
      : _mapsService = mapsService ?? GoogleMapsService();

  /// Creates a ride in Firestore and returns its auto-generated document ID.
  Future<String> createRide(RideModel ride) async {
    try {
      final payload = ride.toFirestore();
      dev.log('Sending ride to Firestore', name: 'RideRepository.createRide');
      dev.log('Payload keys: ${payload.keys.toList()}',
          name: 'RideRepository.createRide');
      final docRef = await _firestore.collection('rides').add(payload);
      dev.log('Successfully created ride: ${docRef.id}',
          name: 'RideRepository.createRide');
      return docRef.id;
    } on FirebaseException catch (e) {
      dev.log(
        'Firebase error while creating ride',
        name: 'RideRepository.createRide',
        error: e,
      );
      throw Exception(
          'Firebase Error (${e.code}): ${e.message ?? "Unknown error"}');
    } catch (e, stackTrace) {
      dev.log(
        'Unknown error while creating ride',
        name: 'RideRepository.createRide',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to post ride: $e');
    }
  }

  /// Query rides whose origin is within [radiusKm] of the given point
  /// using geohash prefix range queries on Firestore.
  Stream<List<RideModel>> getNearbyRides({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) {
    final ranges = GeohashService.getSearchRanges(lat, lng, radiusKm);

    // Create a stream for each geohash range and merge them
    final streams = ranges.map((range) {
      return _firestore
          .collection('rides')
          .where('status', isEqualTo: RideStatus.active.name)
          .where('originGeohash', isGreaterThanOrEqualTo: range.start)
          .where('originGeohash', isLessThanOrEqualTo: range.end)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RideModel.fromFirestore(doc))
              .toList());
    }).toList();

    // Merge all streams and deduplicate + do final distance filter
    return _mergeRideStreams(streams).map((allRides) {
      // Deduplicate by ride ID
      final seen = <String>{};
      final unique = <RideModel>[];
      for (final ride in allRides) {
        if (ride.id != null && seen.add(ride.id!)) {
          // Final precise Haversine filter
          final dist = GeohashService.distanceKm(
            lat,
            lng,
            ride.originLat,
            ride.originLng,
          );
          if (dist <= radiusKm) {
            unique.add(ride);
          }
        }
      }
      // Sort by start time
      unique.sort((a, b) => a.startTime.compareTo(b.startTime));
      return unique;
    });
  }

  /// Legacy method — redirects to geohash-based query
  Stream<List<RideModel>> getAvailableRides({String? originCity}) {
    // Fallback: if no geo coordinates, use basic query
    Query query = _firestore
        .collection('rides')
        .where('status', isEqualTo: RideStatus.active.name)
        .limit(50);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList();
    });
  }

  Future<bool> bookSeat(String rideId, String riderUid) async {
    final rideRef = _firestore.collection('rides').doc(rideId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists) return false;

      final ride = RideModel.fromFirestore(snapshot);
      if (ride.availableSeats <= 0) return false;
      if (ride.riderUids.contains(riderUid)) return true;

      transaction.update(rideRef, {
        'availableSeats': FieldValue.increment(-1),
        'riderUids': FieldValue.arrayUnion([riderUid]),
      });

      return true;
    });
  }

  Stream<List<RideModel>> getMyRidesAsDriver(String driverUid) {
    return _firestore
        .collection('rides')
        .where('driverUid', isEqualTo: driverUid)
        .snapshots()
        .map((snapshot) {
      final rides =
          snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList();
      rides.sort((a, b) => b.startTime.compareTo(a.startTime));
      return rides;
    });
  }

  Stream<List<RideModel>> getMyRidesAsRider(String riderUid) {
    return _firestore
        .collection('rides')
        .where('riderUids', arrayContains: riderUid)
        .snapshots()
        .map((snapshot) {
      final rides =
          snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList();
      rides.sort((a, b) => b.startTime.compareTo(a.startTime));
      return rides;
    });
  }

  Stream<RideModel?> streamRide(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((doc) => doc.exists ? RideModel.fromFirestore(doc) : null);
  }

  // --- Ride Requests ---

  /// Creates a ride request inside a Firestore transaction so that the seat-
  /// availability check and the request creation happen atomically.  This
  /// prevents two concurrent riders from both seeing `availableSeats > 0` and
  /// creating requests that would overbook the ride.
  Future<String> requestRide(RideRequestModel request) async {
    final requestRef = _firestore.collection('ride_requests').doc();

    await _firestore.runTransaction((transaction) async {
      final rideDoc = await transaction.get(
        _firestore.collection('rides').doc(request.rideId),
      );

      if (!rideDoc.exists) {
        throw Exception('Ride not found.');
      }

      final ride = RideModel.fromFirestore(rideDoc);
      if (ride.availableSeats <= 0) {
        throw Exception('No seats available for this ride.');
      }

      transaction.set(requestRef, request.toFirestore());
    });

    return requestRef.id;
  }

  Stream<RideRequestModel?> streamRideRequest(String requestId) {
    return _firestore
        .collection('ride_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) => doc.exists ? RideRequestModel.fromFirestore(doc) : null);
  }

  Stream<List<RideRequestModel>> streamRideRequestsForRide(String rideId) {
    return _firestore
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('status', isEqualTo: RideRequestStatus.pending.name)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateRideRequestStatus(
      String requestId, RideRequestStatus status) async {
    await _firestore.collection('ride_requests').doc(requestId).update({
      'status': status.name,
    });
  }

  Stream<List<RideModel>> getMatchedRides({
    required LatLngPoint riderOrigin,
    required LatLngPoint riderDestination,
    int maxDetourSeconds = 900, // 15 mins
    int maxDetourMeters = 5000, // 5 km
    double searchRadiusKm = 15.0,
    List<String>? preferences,
  }) {
    return getNearbyRides(
      lat: riderOrigin.lat,
      lng: riderOrigin.lng,
      radiusKm: searchRadiusKm,
    ).asyncMap((nearbyRides) async {
      if (nearbyRides.isEmpty) return <RideModel>[];

      final matchedRides = <RideModel>[];

      for (final ride in nearbyRides) {
        if (preferences != null && preferences.isNotEmpty) {
          final ridePrefs = ride.preferences;
          bool hasAllPrefs = true;
          for (final pref in preferences) {
            if (!ridePrefs.contains(pref)) {
              hasAllPrefs = false;
              break;
            }
          }
          if (!hasAllPrefs) {
            continue; // Skip this ride if it doesn't match preferences
          }
        }

        try {
          final originalDuration = ride.durationSeconds ?? 0;
          final originalDistance = ride.distanceMeters ?? 0;

          // Fallback for legacy rides missing duration/distance
          if (originalDuration == 0) {
            matchedRides.add(ride);
            continue;
          }

          final driverOrigin =
              LatLngPoint(lat: ride.originLat, lng: ride.originLng);
          final driverDestination =
              LatLngPoint(lat: ride.destinationLat, lng: ride.destinationLng);

          final detourRoute = await _mapsService.getDirections(
            origin: driverOrigin,
            destination: driverDestination,
            waypoints: [riderOrigin, riderDestination],
          ).timeout(const Duration(seconds: 8));

          if (detourRoute != null) {
            final detourSeconds =
                detourRoute.durationSeconds - originalDuration;
            final detourMeters = detourRoute.distanceMeters - originalDistance;

            if (detourSeconds <= maxDetourSeconds &&
                detourMeters <= maxDetourMeters) {
              matchedRides.add(ride);
            }
          } else {
            // Fallback if API fails
            matchedRides.add(ride);
          }
        } catch (e, st) {
          dev.log(
            'Directions API detour check failed for ride ${ride.id}: $e',
            name: 'RideRepository',
            error: e,
            stackTrace: st,
          );
          // Fallback on error
          matchedRides.add(ride);
        }
      }

      return matchedRides;
    });
  }

  /// Use Distance Matrix API for accurate fare computation.
  Future<double> getServerFare({
    required LatLngPoint origin,
    required LatLngPoint destination,
    required String vehicleType,
    required double demandFactor,
  }) async {
    if (vehicleType != 'car' && vehicleType != 'bike') {
      throw ArgumentError('Invalid vehicleType. Must be "car" or "bike".');
    }
    final clampedDemand = demandFactor.clamp(1.0, 3.0);

    try {
      final matrix = await _mapsService.getDistanceMatrix(
        origin: origin,
        destination: destination,
      );

      if (matrix != null) {
        final distanceMeters = (matrix['distanceMeters'] as num).toInt();
        final distanceKm = (distanceMeters / 1000).clamp(1.0, double.infinity);

        final baseRate = vehicleType == 'car' ? 14.0 : 6.0;
        final fixed = vehicleType == 'car' ? 40.0 : 20.0;

        return (fixed + (distanceKm * baseRate)) * clampedDemand;
      }
    } catch (e) {
      // Fall back to Haversine calculation
    }

    return _fallbackFare(origin, destination, vehicleType, clampedDemand);
  }

  double _fallbackFare(
    LatLngPoint origin,
    LatLngPoint destination,
    String vehicleType,
    double demandFactor,
  ) {
    if (vehicleType != 'car' && vehicleType != 'bike') {
      throw ArgumentError('Invalid vehicleType. Must be "car" or "bike".');
    }
    final clampedDemand = demandFactor.clamp(1.0, 3.0);

    final distanceKm = GeohashService.distanceKm(
      origin.lat,
      origin.lng,
      destination.lat,
      destination.lng,
    ).clamp(1.0, double.infinity);

    final baseRate = vehicleType == 'car' ? 14.0 : 6.0;
    final fixed = vehicleType == 'car' ? 40.0 : 20.0;

    return (fixed + (distanceKm * baseRate)) * clampedDemand;
  }

  // ─── Private helpers ──────────────────────────────────────────────

  Stream<List<RideModel>> _mergeRideStreams(
      List<Stream<List<RideModel>>> streams) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;

    // Broadcast controller so multiple listeners (e.g. StreamBuilder rebuilds
    // during navigation) can subscribe without throwing "Stream already listened
    // to". onCancel still fires when the last listener unsubscribes, which is
    // when we cancel the underlying source stream subscriptions.
    final controller = StreamController<List<RideModel>>.broadcast();
    final latestData = List<List<RideModel>>.filled(streams.length, []);
    final subscriptions = <StreamSubscription>[];
    int activeCount = streams.length;

    for (int i = 0; i < streams.length; i++) {
      final sub = streams[i].listen(
        (data) {
          latestData[i] = data;
          controller.add(latestData.expand((e) => e).toList());
        },
        onError: (e) => controller.addError(e),
        onDone: () {
          activeCount--;
          if (activeCount == 0) controller.close();
        },
      );
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Update ride status in Firestore
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': status.name,
    });
  }

  /// Accept a rider request and update the ride in Firestore.
  ///
  /// Delegates to [bookSeat] — the transaction logic lives in one place so
  /// any future additions (notifications, audit logging, etc.) only need a
  /// single change.
  Future<bool> acceptRider(String rideId, String riderUid) =>
      bookSeat(rideId, riderUid);

  /// Update driver's current location in the dedicated locations document
  Future<void> updateDriverLocation(
    String rideId,
    double lat,
    double lng,
  ) async {
    await _firestore.collection('locations').doc(rideId).set({
      'currentDriverLat': lat,
      'currentDriverLng': lng,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
