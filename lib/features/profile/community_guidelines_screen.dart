import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';

class CommunityGuidelinesScreen extends ConsumerWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Community Guidelines',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildGuidelineSection(
            isDark: isDark,
            icon: Icons.directions_car,
            iconColor: const Color(0xFF3B82F6),
            title: 'Vehicle & Cleanliness',
            description:
                'Keep your vehicle clean and well-maintained. Smoking and eating inside the vehicle are not permitted.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineSection(
            isDark: isDark,
            icon: Icons.people_outline,
            iconColor: const Color(0xFF10B981),
            title: 'Respectful Behavior',
            description:
                'Treat all riders and drivers with courtesy and respect. No discrimination, harassment, or offensive language.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineSection(
            isDark: isDark,
            icon: Icons.schedule,
            iconColor: const Color(0xFFF59E0B),
            title: 'Punctuality',
            description:
                'Arrive on time for pickups and wait for riders within the agreed appointment window.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineSection(
            isDark: isDark,
            icon: Icons.safety_check_outlined,
            iconColor: const Color(0xFFEF4444),
            title: 'Safety First',
            description:
                'Follow traffic rules, maintain safe driving speeds, and prioritize the safety of all passengers.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineSection(
            isDark: isDark,
            icon: Icons.verified_user,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Identity Verification',
            description:
                'Always verify the identity of the person before starting your ride. Use the in-app features to confirm.',
          ),
          const SizedBox(height: 16),
          _buildGuidelineSection(
            isDark: isDark,
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF6366F1),
            title: 'Privacy & Security',
            description:
                'Never share personal information beyond what\'s necessary for the ride. Report any suspicious activity immediately.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_outlined,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Violations may result in account suspension or termination.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                      height: 1.5,
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

  Widget _buildGuidelineSection({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17201C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softStroke(isDark: isDark, highContrast: false),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
