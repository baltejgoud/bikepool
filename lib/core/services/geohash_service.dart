import 'dart:math';

/// Lightweight geohash service for spatial indexing on Firestore.
/// Uses standard base32 geohash encoding. No external dependencies.
class GeohashService {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode a lat/lng pair to a geohash string.
  /// Default precision 7 gives ~150m x 150m cells.
  static String encode(double lat, double lng, {int precision = 7}) {
    double minLat = -90.0, maxLat = 90.0;
    double minLng = -180.0, maxLng = 180.0;
    bool isLng = true;
    int bit = 0;
    int ch = 0;
    final geohash = StringBuffer();

    while (geohash.length < precision) {
      if (isLng) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isLng = !isLng;
      bit++;

      if (bit == 5) {
        geohash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return geohash.toString();
  }

  /// Get the geohash query ranges that cover a circle of
  /// [radiusKm] around the given [lat]/[lng].
  ///
  /// Returns a list of (start, end) pairs for Firestore range queries.
  /// Based on the prefix-based neighbor expansion approach.
  static List<GeohashRange> getSearchRanges(
    double lat,
    double lng,
    double radiusKm,
  ) {
    // Determine appropriate precision based on radius
    final precision = _precisionForRadius(radiusKm);
    final centerHash = encode(lat, lng, precision: precision);

    // Get the 8 neighbors + center = 9 cells
    final neighbors = _getNeighbors(centerHash);
    final allCells = {centerHash, ...neighbors};

    return allCells.map((hash) {
      return GeohashRange(
        start: hash,
        end: '$hash~', // ~ is after z in ASCII, so this covers all children
      );
    }).toList();
  }

  /// Return the appropriate geohash precision for a given search radius.
  static int _precisionForRadius(double radiusKm) {
    // Approximate cell sizes (width at equator):
    // precision 1: ~5000 km
    // precision 2: ~1250 km
    // precision 3: ~156 km
    // precision 4: ~39 km
    // precision 5: ~4.9 km
    // precision 6: ~1.2 km
    // precision 7: ~0.15 km
    if (radiusKm > 50) return 3;
    if (radiusKm > 10) return 4;
    if (radiusKm > 2) return 5;
    if (radiusKm > 0.5) return 6;
    return 7;
  }

  /// Get the 8 neighboring geohash cells of [hash].
  static Set<String> _getNeighbors(String hash) {
    if (hash.isEmpty) return {};

    final neighbors = <String>{};
    // Directions: N, NE, E, SE, S, SW, W, NW
    final directions = [
      [1, 0],
      [1, 1],
      [0, 1],
      [-1, 1],
      [-1, 0],
      [-1, -1],
      [0, -1],
      [1, -1],
    ];

    // Decode center to lat/lng, then offset and re-encode
    final decoded = decode(hash);
    final precision = hash.length;

    // Approximate cell size in degrees
    final latErr = 90.0 / pow(2, (precision * 5 / 2).floor());
    final lngErr = 180.0 / pow(2, (precision * 5 / 2).ceil());

    for (final dir in directions) {
      final nLat = decoded.lat + dir[0] * latErr * 2;
      final nLng = decoded.lng + dir[1] * lngErr * 2;
      if (nLat >= -90 && nLat <= 90 && nLng >= -180 && nLng <= 180) {
        neighbors.add(encode(nLat, nLng, precision: precision));
      }
    }

    return neighbors;
  }

  /// Decode a geohash string back to lat/lng (center of cell).
  static LatLngDecoded decode(String hash) {
    double minLat = -90.0, maxLat = 90.0;
    double minLng = -180.0, maxLng = 180.0;
    bool isLng = true;

    for (int i = 0; i < hash.length; i++) {
      final idx = _base32.indexOf(hash[i]);
      if (idx == -1) continue;

      for (int bit = 4; bit >= 0; bit--) {
        if (isLng) {
          final mid = (minLng + maxLng) / 2;
          if ((idx >> bit) & 1 == 1) {
            minLng = mid;
          } else {
            maxLng = mid;
          }
        } else {
          final mid = (minLat + maxLat) / 2;
          if ((idx >> bit) & 1 == 1) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        isLng = !isLng;
      }
    }

    return LatLngDecoded(
      lat: (minLat + maxLat) / 2,
      lng: (minLng + maxLng) / 2,
    );
  }

  /// Haversine distance in km between two lat/lng points.
  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}

/// Result of decoding a geohash.
class LatLngDecoded {
  final double lat;
  final double lng;
  LatLngDecoded({required this.lat, required this.lng});
}

/// A geohash range for Firestore compound queries.
class GeohashRange {
  final String start;
  final String end;
  GeohashRange({required this.start, required this.end});
}
