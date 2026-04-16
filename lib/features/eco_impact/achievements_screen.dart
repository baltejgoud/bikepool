import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/data_providers.dart';
import '../../shared/widgets/app_back_button.dart';
import 'models/milestone.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // userMilestonesProvider is now a plain Provider — access its value directly.
    // The upstream myRidesAsRiderProvider is watched for loading/error states.
    final ridesAsync = ref.watch(myRidesAsRiderProvider);
    final milestones = ref.watch(userMilestonesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    return ridesAsync.when(
      data: (_) =>
          _buildAchievementsScreen(context, milestones, isDark, highContrast),
      loading: () => Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: Center(
          child: Text('Error loading achievements: $error'),
        ),
      ),
    );
  }

  Widget _buildAchievementsScreen(BuildContext context,
      List<Milestone> milestones, bool isDark, bool highContrast) {
    // Calculate tier based on completed milestones
    final completedCount = milestones.where((m) => m.isCompleted).length;
    final tier = _getTier(completedCount);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          'Achievements',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // Tier Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getTierColors(tier),
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softElevation(
                isDark: isDark,
                highContrast: highContrast,
                tint: _getTierColors(tier).first,
                strength: 1.0,
              ),
              border: Border.all(
                color: AppColors.softStroke(
                  isDark: isDark,
                  highContrast: highContrast,
                  tint: _getTierColors(tier).first,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  tier,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedCount achievements unlocked',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                // Progress to next tier
                if (tier != 'Eco Champion')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${milestones.length - completedCount} more to next tier',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: completedCount / milestones.length,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Milestones List
          Text(
            'Milestones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...milestones.map((milestone) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MilestoneCard(
                  milestone: milestone,
                  isDark: isDark,
                  highContrast: highContrast,
                ),
              )),
        ],
      ),
    );
  }

  String _getTier(int completedCount) {
    if (completedCount >= 6) return 'Eco Champion';
    if (completedCount >= 4) return 'Green Guardian';
    if (completedCount >= 2) return 'Earth Friend';
    return 'Seedling';
  }

  List<Color> _getTierColors(String tier) {
    switch (tier) {
      case 'Eco Champion':
        return [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
      case 'Green Guardian':
        return [const Color(0xFF059669), const Color(0xFF047857)];
      case 'Earth Friend':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      default:
        return [const Color(0xFF22C55E), const Color(0xFF16A34A)];
    }
  }
}

class _MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final bool isDark;
  final bool highContrast;

  const _MilestoneCard({
    required this.milestone,
    required this.isDark,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: milestone.isCompleted
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.panelBackground(
                isDark: isDark,
                highContrast: highContrast,
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: highContrast,
          tint: milestone.isCompleted ? AppColors.primary : null,
          strength: 0.9,
        ),
        border: Border.all(
          color: milestone.isCompleted
              ? AppColors.softStroke(
                  isDark: isDark,
                  highContrast: highContrast,
                  tint: AppColors.primary,
                  strength: 1.1,
                )
              : AppColors.softStroke(
                  isDark: isDark,
                  highContrast: highContrast,
                ),
        ),
      ),
      child: Row(
        children: [
          // Badge/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: milestone.isCompleted
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                milestone.badgeIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              milestone.isCompleted ? AppColors.primary : null,
                        ),
                      ),
                    ),
                    if (milestone.isCompleted)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.secondaryText(
                      isDark: isDark,
                      highContrast: highContrast,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Progress
                if (!milestone.isCompleted)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: milestone.progress,
                              backgroundColor: AppColors.outline(
                                isDark: isDark,
                                highContrast: highContrast,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${milestone.currentValue}/${milestone.targetValue}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText(
                                isDark: isDark,
                                highContrast: highContrast,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                // Completed date
                if (milestone.isCompleted && milestone.completedAt != null)
                  Text(
                    'Completed ${_formatDate(milestone.completedAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.secondaryText(
                        isDark: isDark,
                        highContrast: highContrast,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    return '${(difference / 30).round()} months ago';
  }
}
