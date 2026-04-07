import '../../models/lat_lng_point.dart';

class RouteResult {
  final List<LatLngPoint> polylinePoints;
  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final int durationSeconds;
  final LatLngPoint northEast;
  final LatLngPoint southWest;

  const RouteResult({
    required this.polylinePoints,
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    required this.northEast,
    required this.southWest,
  });
}
