import 'package:cloud_firestore/cloud_firestore.dart';

class RidePreferences {
  final String userId;
  final String comfortLevel; // 'Basic', 'Standard', 'Premium'
  final bool silentRide;
  final bool petsAllowed;
  final bool smokingAllowed;
  final double maxDetourTime; // in minutes: 5-30
  final DateTime lastUpdated;

  RidePreferences({
    required this.userId,
    this.comfortLevel = 'Standard',
    this.silentRide = false,
    this.petsAllowed = false,
    this.smokingAllowed = false,
    this.maxDetourTime = 10.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory RidePreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return RidePreferences(userId: doc.id);
    }

    return RidePreferences(
      userId: doc.id,
      comfortLevel: data['comfortLevel'] ?? 'Standard',
      silentRide: data['silentRide'] ?? false,
      petsAllowed: data['petsAllowed'] ?? false,
      smokingAllowed: data['smokingAllowed'] ?? false,
      maxDetourTime: (data['maxDetourTime'] ?? 10.0).toDouble(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'comfortLevel': comfortLevel,
      'silentRide': silentRide,
      'petsAllowed': petsAllowed,
      'smokingAllowed': smokingAllowed,
      'maxDetourTime': maxDetourTime,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  RidePreferences copyWith({
    String? comfortLevel,
    bool? silentRide,
    bool? petsAllowed,
    bool? smokingAllowed,
    double? maxDetourTime,
  }) {
    return RidePreferences(
      userId: userId,
      comfortLevel: comfortLevel ?? this.comfortLevel,
      silentRide: silentRide ?? this.silentRide,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      maxDetourTime: maxDetourTime ?? this.maxDetourTime,
      lastUpdated: DateTime.now(),
    );
  }
}
