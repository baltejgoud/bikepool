import 'package:cloud_firestore/cloud_firestore.dart';

enum RideRequestStatus { pending, accepted, declined, cancelled }

class RideRequestModel {
  final String? id;
  final String rideId;
  final String driverUid;
  final String riderUid;
  final String riderName;
  final double riderRating;
  final String pickupLocation;
  final String pickupDistance;
  final String dropLocation;
  final String dropDistance;
  final String estimatedTime;
  final double price;
  final RideRequestStatus status;
  final DateTime timestamp;

  RideRequestModel({
    this.id,
    required this.rideId,
    required this.driverUid,
    required this.riderUid,
    required this.riderName,
    required this.riderRating,
    required this.pickupLocation,
    required this.pickupDistance,
    required this.dropLocation,
    required this.dropDistance,
    required this.estimatedTime,
    required this.price,
    this.status = RideRequestStatus.pending,
    required this.timestamp,
  });

  factory RideRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideRequestModel(
      id: doc.id,
      rideId: data['rideId'] ?? '',
      driverUid: data['driverUid'] ?? '',
      riderUid: data['riderUid'] ?? '',
      riderName: data['riderName'] ?? '',
      riderRating: (data['riderRating'] ?? 0.0).toDouble(),
      pickupLocation: data['pickupLocation'] ?? '',
      pickupDistance: data['pickupDistance'] ?? '',
      dropLocation: data['dropLocation'] ?? '',
      dropDistance: data['dropDistance'] ?? '',
      estimatedTime: data['estimatedTime'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      status: RideRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RideRequestStatus.pending,
      ),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'driverUid': driverUid,
      'riderUid': riderUid,
      'riderName': riderName,
      'riderRating': riderRating,
      'pickupLocation': pickupLocation,
      'pickupDistance': pickupDistance,
      'dropLocation': dropLocation,
      'dropDistance': dropDistance,
      'estimatedTime': estimatedTime,
      'price': price,
      'status': status.name,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  RideRequestModel copyWith({
    String? id,
    String? rideId,
    String? driverUid,
    String? riderUid,
    String? riderName,
    double? riderRating,
    String? pickupLocation,
    String? pickupDistance,
    String? dropLocation,
    String? dropDistance,
    String? estimatedTime,
    double? price,
    RideRequestStatus? status,
    DateTime? timestamp,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      driverUid: driverUid ?? this.driverUid,
      riderUid: riderUid ?? this.riderUid,
      riderName: riderName ?? this.riderName,
      riderRating: riderRating ?? this.riderRating,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupDistance: pickupDistance ?? this.pickupDistance,
      dropLocation: dropLocation ?? this.dropLocation,
      dropDistance: dropDistance ?? this.dropDistance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      price: price ?? this.price,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
