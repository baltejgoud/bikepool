enum MilestoneType {
  rides,
  distance,
  carbon,
  streak,
}

class Milestone {
  final String id;
  final String title;
  final String description;
  final MilestoneType type;
  final int targetValue;
  final int currentValue;
  final String badgeIcon;
  final bool isCompleted;
  final DateTime? completedAt;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.badgeIcon,
    this.isCompleted = false,
    this.completedAt,
  });

  double get progress => currentValue / targetValue;
  bool get isInProgress => !isCompleted && currentValue > 0;

  // Sample milestones
  static List<Milestone> sampleMilestones = [
    Milestone(
      id: 'first_ride',
      title: 'First Pool',
      description: 'Complete your first shared ride',
      type: MilestoneType.rides,
      targetValue: 1,
      currentValue: 1,
      badgeIcon: '🌱',
      isCompleted: true,
      completedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    const Milestone(
      id: 'silver_pooler',
      title: 'Silver Pooler',
      description: 'Complete 25 shared rides',
      type: MilestoneType.rides,
      targetValue: 25,
      currentValue: 18,
      badgeIcon: '🥈',
    ),
    const Milestone(
      id: 'gold_pooler',
      title: 'Gold Pooler',
      description: 'Complete 50 shared rides',
      type: MilestoneType.rides,
      targetValue: 50,
      currentValue: 18,
      badgeIcon: '🥇',
    ),
    const Milestone(
      id: 'carbon_saver',
      title: 'Carbon Saver',
      description: 'Save 100kg of CO2',
      type: MilestoneType.carbon,
      targetValue: 100,
      currentValue: 85,
      badgeIcon: '🌍',
    ),
    const Milestone(
      id: 'eco_warrior',
      title: 'Eco Warrior',
      description: 'Save 250kg of CO2',
      type: MilestoneType.carbon,
      targetValue: 250,
      currentValue: 127,
      badgeIcon: '🛡️',
    ),
    const Milestone(
      id: 'streak_master',
      title: 'Streak Master',
      description: 'Complete rides for 7 consecutive days',
      type: MilestoneType.streak,
      targetValue: 7,
      currentValue: 5,
      badgeIcon: '🔥',
    ),
  ];
}
