import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/vehicle_card.dart';
import '../services/geohash_service.dart';
import 'lat_lng_point.dart';

enum RideStatus { active, ongoing, completed, cancelled }

class RideModel {
  final String? id;
  final List<LatLngPoint> routePath;
  final String driverUid;
  final String driverName;
  final String originAddress;
  final double originLat;
  final double originLng;
  final String originGeohash;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final String destinationGeohash;
  final VehicleType vehicleType;
  final int totalSeats;
  final int availableSeats;
  final double price;
  final DateTime startTime;
  final RideStatus status;
  final List<String> riderUids;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? distanceText;
  final String? durationText;
  // Real-time location tracking fields
  final double? currentDriverLat;
  final double? currentDriverLng;
  final DateTime? lastLocationUpdate;

  RideModel({
    this.id,
    required this.driverUid,
    required this.driverName,
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    String? originGeohash,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    String? destinationGeohash,
    required this.vehicleType,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    required this.startTime,
    required this.routePath,
    this.status = RideStatus.active,
    this.riderUids = const [],
    this.distanceMeters,
    this.durationSeconds,
    this.distanceText,
    this.durationText,
    this.currentDriverLat,
    this.currentDriverLng,
    this.lastLocationUpdate,
  })  : originGeohash =
            originGeohash ?? GeohashService.encode(originLat, originLng),
        destinationGeohash = destinationGeohash ??
            GeohashService.encode(destinationLat, destinationLng);

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final oLat = (data['originLat'] ?? 0.0).toDouble();
    final oLng = (data['originLng'] ?? 0.0).toDouble();
    final dLat = (data['destinationLat'] ?? 0.0).toDouble();
    final dLng = (data['destinationLng'] ?? 0.0).toDouble();

    return RideModel(
      id: doc.id,
      driverUid: data['driverUid'] ?? '',
      driverName: data['driverName'] ?? '',
      originAddress: data['originAddress'] ?? '',
      originLat: oLat,
      originLng: oLng,
      originGeohash: data['originGeohash'] ?? GeohashService.encode(oLat, oLng),
      destinationAddress: data['destinationAddress'] ?? '',
      destinationLat: dLat,
      destinationLng: dLng,
      destinationGeohash:
          data['destinationGeohash'] ?? GeohashService.encode(dLat, dLng),
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == data['vehicleType'],
        orElse: () => VehicleType.bike,
      ),
      totalSeats: data['totalSeats'] ?? 1,
      availableSeats: data['availableSeats'] ?? 1,
      price: (data['price'] ?? 0.0).toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      status: RideStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RideStatus.active,
      ),
      routePath: (data['routePath'] as List<dynamic>?)
              ?.map((item) =>
                  LatLngPoint.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [
            LatLngPoint(lat: oLat, lng: oLng),
            LatLngPoint(lat: dLat, lng: dLng),
          ],
      riderUids: List<String>.from(data['riderUids'] ?? []),
      distanceMeters: data['distanceMeters'],
      durationSeconds: data['durationSeconds'],
      distanceText: data['distanceText'],
      durationText: data['durationText'],
      currentDriverLat: (data['currentDriverLat'] as num?)?.toDouble(),
      currentDriverLng: (data['currentDriverLng'] as num?)?.toDouble(),
      lastLocationUpdate: data['lastLocationUpdate'] != null
          ? (data['lastLocationUpdate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverUid': driverUid,
      'driverName': driverName,
      'originAddress': originAddress,
      'originLat': originLat,
      'originLng': originLng,
      'originGeohash': originGeohash,
      'destinationAddress': destinationAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'destinationGeohash': destinationGeohash,
      'vehicleType': vehicleType.name,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'price': price,
      'startTime': Timestamp.fromDate(startTime),
      'status': status.name,
      'routePath': routePath.map((p) => p.toMap()).toList(),
      'riderUids': riderUids,
      if (distanceMeters != null) 'distanceMeters': distanceMeters,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (distanceText != null) 'distanceText': distanceText,
      if (durationText != null) 'durationText': durationText,
      if (currentDriverLat != null) 'currentDriverLat': currentDriverLat,
      if (currentDriverLng != null) 'currentDriverLng': currentDriverLng,
      if (lastLocationUpdate != null)
        'lastLocationUpdate': Timestamp.fromDate(lastLocationUpdate!),
    };
  }
}
