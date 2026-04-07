import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationMethod { governmentId, companyId }

class UserModel {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final String? emergencyContact;
  final String? homeHub;
  final bool isProfileCompleted;
  final VerificationMethod? verificationMethod;
  final String? verificationDetail1; // idNumber or companyName
  final String? verificationDetail2; // idType or companyEmail
  final String? verificationDetail3; // employeeId
  final double rating;
  final int totalRides;
  final double walletBalance;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    this.emergencyContact,
    this.homeHub,
    this.isProfileCompleted = false,
    this.verificationMethod,
    this.verificationDetail1,
    this.verificationDetail2,
    this.verificationDetail3,
    this.rating = 5.0,
    this.totalRides = 0,
    this.walletBalance = 0.0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      emergencyContact: data['emergencyContact'],
      homeHub: data['homeHub'],
      isProfileCompleted: data['isProfileCompleted'] ?? false,
      verificationMethod: data['verificationMethod'] != null
          ? VerificationMethod.values.firstWhere(
              (e) => e.name == data['verificationMethod'],
              orElse: () => VerificationMethod.governmentId,
            )
          : null,
      verificationDetail1: data['verificationDetail1'],
      verificationDetail2: data['verificationDetail2'],
      verificationDetail3: data['verificationDetail3'],
      rating: (data['rating'] ?? 5.0).toDouble(),
      totalRides: data['totalRides'] ?? 0,
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'emergencyContact': emergencyContact,
      'homeHub': homeHub,
      'isProfileCompleted': isProfileCompleted,
      'verificationMethod': verificationMethod?.name,
      'verificationDetail1': verificationDetail1,
      'verificationDetail2': verificationDetail2,
      'verificationDetail3': verificationDetail3,
      'rating': rating,
      'totalRides': totalRides,
      'walletBalance': walletBalance,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? emergencyContact,
    String? homeHub,
    bool? isProfileCompleted,
    VerificationMethod? verificationMethod,
    String? verificationDetail1,
    String? verificationDetail2,
    String? verificationDetail3,
    double? rating,
    int? totalRides,
    double? walletBalance,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      homeHub: homeHub ?? this.homeHub,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationDetail1: verificationDetail1 ?? this.verificationDetail1,
      verificationDetail2: verificationDetail2 ?? this.verificationDetail2,
      verificationDetail3: verificationDetail3 ?? this.verificationDetail3,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }
}
