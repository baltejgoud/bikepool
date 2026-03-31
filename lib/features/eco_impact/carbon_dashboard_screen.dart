import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/count_up_number.dart';
import 'models/carbon_saved.dart';

class CarbonDashboardScreen extends StatefulWidget {
  const CarbonDashboardScreen({super.key});

  @override
  State<CarbonDashboardScreen> createState() => _CarbonDashboardScreenState();
}

class _CarbonDashboardScreenState extends State<CarbonDashboardScreen> {
  final CarbonSaved _carbonData = CarbonSaved.sample();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          'Carbon Saved',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // Hero Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F3D2A), const Color(0xFF0A1F16)]
                    : [const Color(0xFFE8F5E8), const Color(0xFFD4EDDA)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outline(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  size: 48,
                  color: Color(0xFF22C55E),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total CO₂ Saved',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CountUpNumber(
                  value: _carbonData.totalKg,
                  suffix: ' kg',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Equivalent to planting ${_carbonData.totalKg ~/ 20} trees',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Rides',
                  value: '${_carbonData.totalRides}',
                  icon: Icons.directions_bike_rounded,
                  isDark: isDark,
                  highContrast: highContrast,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Avg per Ride',
                  value: '${_carbonData.averagePerRide.toStringAsFixed(1)} kg',
                  icon: Icons.trending_up_rounded,
                  isDark: isDark,
                  highContrast: highContrast,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Monthly Breakdown
          Text(
            'Monthly Breakdown',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.panelBackground(
                isDark: isDark,
                highContrast: highContrast,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outline(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
              ),
            ),
            child: _MonthlyChart(
              data: _carbonData.monthlyBreakdown,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 24),

          // Impact Message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.panelBackground(
                isDark: isDark,
                highContrast: highContrast,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.outline(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  size: 32,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Impact',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By choosing to pool instead of driving alone, you\'ve helped reduce greenhouse gas emissions and made Hyderabad a greener city. Keep riding!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;
  final bool highContrast;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground(
          isDark: isDark,
          highContrast: highContrast,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outline(
            isDark: isDark,
            highContrast: highContrast,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.secondaryText(
                isDark: isDark,
                highContrast: highContrast,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const _MonthlyChart({
    required this.data,
    required this.isDark,
  });

  @override
  State<_MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<_MonthlyChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.data.values.reduce((a, b) => a > b ? a : b);
    final months = widget.data.keys.toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((month) {
              final value = widget.data[month]!;
              final maxValueDouble = maxValue.toDouble();
              final index = months.indexOf(month);
              final stagger = (index / months.length) * 0.5;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final t = (_controller.value - stagger).clamp(0.0, 1.0) / (1.0 - stagger);
                          final easedT = Curves.easeOutBack.transform(t);
                          final height = (value / maxValueDouble) * 150 * easedT;
                          
                          return Container(
                            width: double.infinity,
                            height: height.clamp(0.0, double.infinity),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        month,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.secondaryText(
                            isDark: widget.isDark,
                            highContrast: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CO₂ saved (kg)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.secondaryText(
                  isDark: widget.isDark,
                  highContrast: false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}