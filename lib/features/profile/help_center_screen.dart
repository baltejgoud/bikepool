import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

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
          'Help Center',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17201C) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    AppColors.softStroke(isDark: isDark, highContrast: false),
              ),
            ),
            child: TextField(
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search),
                prefixIconColor: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFAQCategory(
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            category: 'Getting Started',
            questions: [
              'How do I create an account?',
              'How do I verify my identity?',
              'How do I add payment methods?',
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQCategory(
            isDark: isDark,
            icon: Icons.directions_car_outlined,
            iconColor: const Color(0xFF10B981),
            category: 'Rides & Routing',
            questions: [
              'How do I request a ride?',
              'Can I share my ride details?',
              'What if my driver is late?',
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQCategory(
            isDark: isDark,
            icon: Icons.payment_outlined,
            iconColor: const Color(0xFFF59E0B),
            category: 'Payments & Billing',
            questions: [
              'How are fares calculated?',
              'What payment methods are accepted?',
              'Can I get a refund?',
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQCategory(
            isDark: isDark,
            icon: Icons.security_outlined,
            iconColor: const Color(0xFFEF4444),
            category: 'Safety & Security',
            questions: [
              'How is my data protected?',
              'What should I do if I feel unsafe?',
              'Can I contact support 24/7?',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCategory({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String category,
    required List<String> questions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17201C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softStroke(isDark: isDark, highContrast: false),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.softStroke(isDark: isDark, highContrast: false),
          ),
          ...questions.asMap().entries.map((entry) {
            final isLast = entry.key == questions.length - 1;
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    entry.value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  onTap: () => _showFAQDetail(entry.value),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.softStroke(
                        isDark: isDark, highContrast: false),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showFAQDetail(String question) {
    // This would navigate to a detailed FAQ page in a real app
    debugPrint('Clicked: $question');
  }
}
