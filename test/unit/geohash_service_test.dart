import 'package:flutter_test/flutter_test.dart';
import 'package:bikepool/core/services/geohash_service.dart';

void main() {
  group('GeohashService', () {
    test('encode returns correct geohash for known coordinates', () {
      // Hyderabad coordinates
      const lat = 17.3850;
      const lng = 78.4867;
      
      final hash = GeohashService.encode(lat, lng, precision: 7);
      
      expect(hash, isNotEmpty);
      expect(hash.length, 7);
    });

    test('decode returns coordinates close to original', () {
      const lat = 17.3850;
      const lng = 78.4867;
      
      final hash = GeohashService.encode(lat, lng, precision: 10);
      final decoded = GeohashService.decode(hash);
      
      // Precision 10 should be very accurate
      expect(decoded.lat, closeTo(lat, 0.0001));
      expect(decoded.lng, closeTo(lng, 0.0001));
    });

    test('distanceKm calculates correct distance between two points', () {
      // Hyderabad to Secunderabad (roughly)
      const lat1 = 17.3850, lng1 = 78.4867; // Hyderabad
      const lat2 = 17.4399, lng2 = 78.4983; // Secunderabad
      
      final distance = GeohashService.distanceKm(lat1, lng1, lat2, lng2);
      
      expect(distance, greaterThan(5));
      expect(distance, lessThan(10));
    });

    test('getSearchRanges returns correct number of ranges', () {
      const lat = 17.3850;
      const lng = 78.4867;
      
      final ranges = GeohashService.getSearchRanges(lat, lng, 5.0);
      
      // Should return ranges for 9 cells (center + 8 neighbors)
      expect(ranges.length, 9);
      for (final range in ranges) {
        expect(range.start, isNotEmpty);
        expect(range.end, isNotEmpty);
        expect(range.end.endsWith('~'), true);
      }
    });
  });
}
