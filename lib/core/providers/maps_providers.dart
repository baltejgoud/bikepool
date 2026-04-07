import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_maps_service.dart';

final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService();
});
