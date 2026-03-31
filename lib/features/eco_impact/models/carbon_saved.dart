class CarbonSaved {
  final double totalKg;
  final int totalRides;
  final double averagePerRide;
  final Map<String, double> monthlyBreakdown; // month -> kg saved

  const CarbonSaved({
    required this.totalKg,
    required this.totalRides,
    required this.averagePerRide,
    required this.monthlyBreakdown,
  });

  // Sample data for demo
  factory CarbonSaved.sample() {
    return const CarbonSaved(
      totalKg: 127.5,
      totalRides: 45,
      averagePerRide: 2.83,
      monthlyBreakdown: {
        'Jan': 12.5,
        'Feb': 18.3,
        'Mar': 25.7,
        'Apr': 22.1,
        'May': 28.9,
        'Jun': 20.0,
      },
    );
  }
}