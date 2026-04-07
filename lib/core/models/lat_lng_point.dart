class LatLngPoint {
  final double lat;
  final double lng;

  LatLngPoint({required this.lat, required this.lng});

  factory LatLngPoint.fromMap(Map<String, dynamic> map) {
    return LatLngPoint(
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}
