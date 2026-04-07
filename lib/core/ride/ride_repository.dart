import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lat_lng_point.dart';
import '../models/ride_model.dart';
import '../services/geohash_service.dart';
import '../services/google_maps_service.dart';

class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleMapsService _mapsService;

  RideRepository({GoogleMapsService? mapsService})
      : _mapsService = mapsService ?? GoogleMapsService();

  Future<void> createRide(RideModel ride) async {
    await _firestore.collection('rides').add(ride.toFirestore());
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
        .where('status', isEqualTo: RideStatus.active.name);

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
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList());
  }

  Stream<List<RideModel>> getMyRidesAsRider(String riderUid) {
    return _firestore
        .collection('rides')
        .where('riderUids', arrayContains: riderUid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList());
  }

  Stream<RideModel?> streamRide(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((doc) => doc.exists ? RideModel.fromFirestore(doc) : null);
  }

  /// Geohash-optimized ride matching: pre-filter by geohash,
  /// then run precise route-matching geometry.
  Stream<List<RideModel>> getMatchedRides({
    required LatLngPoint riderOrigin,
    required LatLngPoint riderDestination,
    double maxOffRouteMeters = 400,
    double requiredOverlapFraction = 0.4,
    double searchRadiusKm = 10.0,
  }) {
    return getNearbyRides(
      lat: riderOrigin.lat,
      lng: riderOrigin.lng,
      radiusKm: searchRadiusKm,
    ).asyncMap((nearbyRides) async {
      final riderRouteResult = await _mapsService.getDirections(
        origin: riderOrigin,
        destination: riderDestination,
      );

      if (riderRouteResult == null ||
          riderRouteResult.polylinePoints.length < 2) {
        return <RideModel>[];
      }

      final riderRoute = riderRouteResult.polylinePoints;
      final matchedRides = <RideModel>[];

      for (final ride in nearbyRides) {
        if (await _doesRouteMatchRequest(
          ride,
          riderOrigin,
          riderDestination,
          riderRoute,
          maxOffRouteMeters,
          requiredOverlapFraction,
        )) {
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
    try {
      final matrix = await _mapsService.getDistanceMatrix(
        origin: origin,
        destination: destination,
      );

      if (matrix != null) {
        final distanceMeters = matrix['distanceMeters'] as int;
        final distanceKm = (distanceMeters / 1000).clamp(1.0, double.infinity);

        final baseRate = vehicleType == 'car' ? 14.0 : 6.0;
        final fixed = vehicleType == 'car' ? 40.0 : 20.0;
        final surge = demandFactor > 1 ? demandFactor : 1.0;

        return (fixed + (distanceKm * baseRate)) * surge;
      }
    } catch (e) {
      // Fall back to Haversine calculation
    }

    return _fallbackFare(origin, destination, vehicleType, demandFactor);
  }

  double _fallbackFare(
    LatLngPoint origin,
    LatLngPoint destination,
    String vehicleType,
    double demandFactor,
  ) {
    final distanceKm = GeohashService.distanceKm(
      origin.lat,
      origin.lng,
      destination.lat,
      destination.lng,
    ).clamp(1.0, double.infinity);

    final baseRate = vehicleType == 'car' ? 14.0 : 6.0;
    final fixed = vehicleType == 'car' ? 40.0 : 20.0;
    final surge = demandFactor > 1 ? demandFactor : 1.0;
    return (fixed + (distanceKm * baseRate)) * surge;
  }

  // ─── Private helpers ──────────────────────────────────────────────

  Stream<List<RideModel>> _mergeRideStreams(
      List<Stream<List<RideModel>>> streams) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;

    // Use a StreamController to merge multiple streams
    final controller = StreamController<List<RideModel>>();
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

  Future<bool> _doesRouteMatchRequest(
    RideModel ride,
    LatLngPoint riderOrigin,
    LatLngPoint riderDestination,
    List<LatLngPoint> riderRoute,
    double maxOffRouteMeters,
    double requiredOverlapFraction,
  ) async {
    final driverRoute = ride.routePath;
    if (driverRoute.length < 2) return false;

    final routeLength = _routeLengthMeters(driverRoute);
    if (routeLength <= 0) return false;

    final originProjection = _projectOntoRoute(riderOrigin, driverRoute);
    final destinationProjection =
        _projectOntoRoute(riderDestination, driverRoute);

    if (originProjection == null || destinationProjection == null) {
      return false;
    }

    if (originProjection.distance > maxOffRouteMeters ||
        destinationProjection.distance > maxOffRouteMeters) {
      return false;
    }

    if (originProjection.frac > destinationProjection.frac) {
      return false;
    }

    final overlapFraction = _routeOverlapFraction(
      riderRoute,
      driverRoute,
      maxOffRouteMeters,
    );

    return overlapFraction >= requiredOverlapFraction;
  }

  double _routeOverlapFraction(
    List<LatLngPoint> candidateRoute,
    List<LatLngPoint> referenceRoute,
    double maxOffRouteMeters,
  ) {
    final totalLength = _routeLengthMeters(candidateRoute);
    if (totalLength <= 0) return 0.0;

    double overlapLength = 0.0;
    for (var i = 0; i < candidateRoute.length - 1; i++) {
      final start = candidateRoute[i];
      final end = candidateRoute[i + 1];
      final segmentLength = _distanceBetweenPoints(start, end);

      final startNear =
          _distanceToRoute(start, referenceRoute) <= maxOffRouteMeters;
      final endNear =
          _distanceToRoute(end, referenceRoute) <= maxOffRouteMeters;

      if (startNear && endNear) {
        overlapLength += segmentLength;
      } else if (startNear || endNear) {
        overlapLength += segmentLength * 0.5;
      }
    }

    return overlapLength / totalLength;
  }

  double _distanceToRoute(LatLngPoint point, List<LatLngPoint> route) {
    final projection = _projectOntoRoute(point, route);
    return projection?.distance ?? double.infinity;
  }

  _Projection? _projectOntoRoute(LatLngPoint point, List<LatLngPoint> route) {
    _Projection? best;
    double travelled = 0;
    final totalLength = _routeLengthMeters(route);

    for (var i = 0; i < route.length - 1; i++) {
      final s = route[i];
      final e = route[i + 1];
      final segLen = _distanceBetweenPoints(s, e);

      final segProjection = _projectToSegment(point, s, e);
      if (segProjection != null) {
        final currDist = _distanceBetweenPoints(
            point, LatLngPoint(lat: segProjection.lat, lng: segProjection.lng));
        final frac = (travelled + segLen * segProjection.t) / totalLength;

        if (best == null || currDist < best.distance) {
          best = _Projection(distance: currDist, frac: frac);
        }
      }

      travelled += segLen;
    }

    return best;
  }

  _SegmentProjection? _projectToSegment(
      LatLngPoint p, LatLngPoint a, LatLngPoint b) {
    final ax = _lngToX(a.lng, a.lat);
    final ay = _latToY(a.lat);
    final bx = _lngToX(b.lng, b.lat);
    final by = _latToY(b.lat);
    final px = _lngToX(p.lng, p.lat);
    final py = _latToY(p.lat);

    final dx = bx - ax;
    final dy = by - ay;
    final mag2 = dx * dx + dy * dy;
    if (mag2 == 0) return null;

    final t = ((px - ax) * dx + (py - ay) * dy) / mag2;
    final clamped = t.clamp(0.0, 1.0);
    final projX = ax + clamped * dx;
    final projY = ay + clamped * dy;
    final projLat = _yToLat(projY);
    final projLng = _xToLng(projX, projLat);

    return _SegmentProjection(lat: projLat, lng: projLng, t: clamped);
  }

  double _routeLengthMeters(List<LatLngPoint> route) {
    double length = 0;
    for (var i = 0; i < route.length - 1; i++) {
      length += _distanceBetweenPoints(route[i], route[i + 1]);
    }
    return length;
  }

  double _distanceBetweenPoints(LatLngPoint a, LatLngPoint b) {
    return GeohashService.distanceKm(a.lat, a.lng, b.lat, b.lng) * 1000;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180);
  double _latToY(double lat) => _degreesToRadians(lat);
  double _lngToX(double lng, double lat) =>
      _degreesToRadians(lng) * cos(_degreesToRadians(lat));
  double _yToLat(double y) => y * (180 / pi);
  double _xToLng(double x, double lat) =>
      x * (180 / pi) / cos(_degreesToRadians(lat));
}

class _Projection {
  final double distance;
  final double frac;

  _Projection({required this.distance, required this.frac});
}

class _SegmentProjection {
  final double lat;
  final double lng;
  final double t;

  _SegmentProjection({required this.lat, required this.lng, required this.t});
}
