import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/lat_lng_point.dart';
import 'models/place_prediction.dart';
import 'models/place_details.dart';
import 'models/route_result.dart';

/// Exception thrown for Google Maps API errors.
class MapsApiException implements Exception {
  final String message;
  final String? status;
  MapsApiException(this.message, {this.status});

  @override
  String toString() => 'MapsApiException: $message (status: $status)';
}

/// Central service for all Google Maps Platform REST API calls.
class GoogleMapsService {
  final Dio _dio;

  GoogleMapsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ─── Places Autocomplete ─────────────────────────────────────────

  /// Search for place predictions using the Places Autocomplete API.
  /// [sessionToken] groups autocomplete + detail requests for billing.
  /// Biased to India with no hard country restriction so it works pan-India.
  Future<List<PlacePrediction>> searchPlaces(
    String query, {
    String? sessionToken,
  }) async {
    if (query.trim().length < 2) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'components': 'country:in',
          'language': 'en',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        throw MapsApiException(
          data['error_message'] ?? 'Places API error',
          status: data['status'],
        );
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions.map((p) {
        final map = p as Map<String, dynamic>;
        return PlacePrediction(
          placeId: map['place_id'] ?? '',
          description: map['description'] ?? '',
          mainText: (map['structured_formatting']
                  as Map<String, dynamic>?)?['main_text'] ??
              map['description'] ??
              '',
          secondaryText: (map['structured_formatting']
                  as Map<String, dynamic>?)?['secondary_text'] ??
              '',
        );
      }).toList();
    } on DioException catch (e) {
      debugPrint('Places API network error: $e');
      throw MapsApiException(
        'Network error: Could not fetch places.',
        status: e.response?.statusCode?.toString(),
      );
    }
  }

  // ─── Place Details ────────────────────────────────────────────────

  /// Fetch lat/lng and formatted address for a place ID.
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry,formatted_address',
          'key': _apiKey,
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        throw MapsApiException(
          data['error_message'] ?? 'Place Details error',
          status: data['status'],
        );
      }

      final result = data['result'] as Map<String, dynamic>;
      final geometry = result['geometry'] as Map<String, dynamic>;
      final location = geometry['location'] as Map<String, dynamic>;

      return PlaceDetails(
        placeId: placeId,
        formattedAddress: result['formatted_address'] ?? '',
        lat: (location['lat'] as num).toDouble(),
        lng: (location['lng'] as num).toDouble(),
      );
    } on DioException catch (e) {
      debugPrint('Place Details API network error: $e');
      throw MapsApiException(
        'Network error: Could not fetch place details.',
        status: e.response?.statusCode?.toString(),
      );
    }
  }

  // ─── Directions API ───────────────────────────────────────────────

  /// Get driving directions between two points.
  /// Returns a [RouteResult] with decoded polyline, distance, duration, and bounds.
  Future<RouteResult?> getDirections({
    required LatLngPoint origin,
    required LatLngPoint destination,
    String mode = 'driving',
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.lat},${origin.lng}',
          'destination': '${destination.lat},${destination.lng}',
          'mode': mode,
          'key': _apiKey,
          'region': 'in',
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        debugPrint('Directions API status: ${data['status']}');
        return null;
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>;
      final leg = legs.first as Map<String, dynamic>;

      // Decode polyline
      final overviewPolyline =
          route['overview_polyline']['points'] as String;
      final polylinePointsDecoder = PolylinePoints();
      final decodedPoints =
          polylinePointsDecoder.decodePolyline(overviewPolyline);
      final polylineLatLngs = decodedPoints
          .map((p) => LatLngPoint(lat: p.latitude, lng: p.longitude))
          .toList();

      // Bounds
      final bounds = route['bounds'] as Map<String, dynamic>;
      final ne = bounds['northeast'] as Map<String, dynamic>;
      final sw = bounds['southwest'] as Map<String, dynamic>;

      return RouteResult(
        polylinePoints: polylineLatLngs,
        distanceText: leg['distance']['text'] ?? '',
        distanceMeters: leg['distance']['value'] ?? 0,
        durationText: leg['duration']['text'] ?? '',
        durationSeconds: leg['duration']['value'] ?? 0,
        northEast: LatLngPoint(
          lat: (ne['lat'] as num).toDouble(),
          lng: (ne['lng'] as num).toDouble(),
        ),
        southWest: LatLngPoint(
          lat: (sw['lat'] as num).toDouble(),
          lng: (sw['lng'] as num).toDouble(),
        ),
      );
    } on DioException catch (e) {
      debugPrint('Directions API network error: $e');
      return null;
    }
  }

  // ─── Distance Matrix API ──────────────────────────────────────────

  /// Get driving distance and duration between origin and destination.
  /// Returns a map with 'distanceText', 'distanceMeters', 'durationText', 'durationSeconds'.
  Future<Map<String, dynamic>?> getDistanceMatrix({
    required LatLngPoint origin,
    required LatLngPoint destination,
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/distancematrix/json',
        queryParameters: {
          'origins': '${origin.lat},${origin.lng}',
          'destinations': '${destination.lat},${destination.lng}',
          'key': _apiKey,
          'region': 'in',
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final rows = data['rows'] as List<dynamic>;
      if (rows.isEmpty) return null;

      final elements =
          (rows.first as Map<String, dynamic>)['elements'] as List<dynamic>;
      if (elements.isEmpty) return null;

      final element = elements.first as Map<String, dynamic>;
      if (element['status'] != 'OK') return null;

      return {
        'distanceText': element['distance']['text'],
        'distanceMeters': element['distance']['value'],
        'durationText': element['duration']['text'],
        'durationSeconds': element['duration']['value'],
      };
    } on DioException catch (e) {
      debugPrint('Distance Matrix API network error: $e');
      return null;
    }
  }
}
