import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPreferences {
  final String userId;
  final bool rideAlerts;
  final bool messages;
  final bool promotions;
  final bool accountSecurity;
  final bool emailUpdates;
  final DateTime lastUpdated;

  NotificationPreferences({
    required this.userId,
    this.rideAlerts = true,
    this.messages = true,
    this.promotions = false,
    this.accountSecurity = true,
    this.emailUpdates = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return NotificationPreferences(userId: doc.id);
    }

    return NotificationPreferences(
      userId: doc.id,
      rideAlerts: data['rideAlerts'] ?? true,
      messages: data['messages'] ?? true,
      promotions: data['promotions'] ?? false,
      accountSecurity: data['accountSecurity'] ?? true,
      emailUpdates: data['emailUpdates'] ?? false,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideAlerts': rideAlerts,
      'messages': messages,
      'promotions': promotions,
      'accountSecurity': accountSecurity,
      'emailUpdates': emailUpdates,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  NotificationPreferences copyWith({
    bool? rideAlerts,
    bool? messages,
    bool? promotions,
    bool? accountSecurity,
    bool? emailUpdates,
  }) {
    return NotificationPreferences(
      userId: userId,
      rideAlerts: rideAlerts ?? this.rideAlerts,
      messages: messages ?? this.messages,
      promotions: promotions ?? this.promotions,
      accountSecurity: accountSecurity ?? this.accountSecurity,
      emailUpdates: emailUpdates ?? this.emailUpdates,
      lastUpdated: DateTime.now(),
    );
  }
}
