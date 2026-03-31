enum AlertType { immediate, scheduled }

class RideAlert {
  final String id;
  final String source;
  final String destination;
  final AlertType type;
  final DateTime? scheduledTime;
  final DateTime createdAt;
  final bool isActive;

  const RideAlert({
    required this.id,
    required this.source,
    required this.destination,
    required this.type,
    this.scheduledTime,
    required this.createdAt,
    this.isActive = true,
  });

  factory RideAlert.create({
    required String source,
    required String destination,
    AlertType type = AlertType.immediate,
    DateTime? scheduledTime,
  }) {
    return RideAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      source: source,
      destination: destination,
      type: type,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
    );
  }
}
