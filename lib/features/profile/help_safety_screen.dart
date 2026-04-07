import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import 'trusted_contacts_screen.dart';
import 'community_guidelines_screen.dart';
import 'help_center_screen.dart';
import 'report_issue_screen.dart';
import 'contact_support_screen.dart';

class HelpSafetyScreen extends ConsumerWidget {
  const HelpSafetyScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

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
          'Help & Safety',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildEmergencyCard(context, isDark),
          const SizedBox(height: 28),
          _buildSectionHeader('Safety Center', isDark),
          const SizedBox(height: 12),
          _buildActionCard(
            isDark: isDark,
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Trusted Contacts',
            subtitle: 'Manage family and friends who get your ride alerts',
            onTap: () => _navigateTo(context, const TrustedContactsScreen()),
          ),
          _buildActionCard(
            isDark: isDark,
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Community Guidelines',
            subtitle: 'Rules and expectations for ridesharing',
            onTap: () =>
                _navigateTo(context, const CommunityGuidelinesScreen()),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader('Support', isDark),
          const SizedBox(height: 12),
          _buildActionCard(
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Help Center',
            subtitle: 'FAQs and common troubleshooting',
            onTap: () => _navigateTo(context, const HelpCenterScreen()),
          ),
          _buildActionCard(
            isDark: isDark,
            icon: Icons.article_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Report an issue',
            subtitle: 'Get help with a specific ride or account problem',
            onTap: () => _navigateTo(context, const ReportIssueScreen()),
          ),
          _buildActionCard(
            isDark: isDark,
            icon: Icons.headset_mic_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Contact Support',
            subtitle: 'Chat with our 24/7 team',
            onTap: () => _navigateTo(context, const ContactSupportScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1A1A) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.8,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_rounded,
                color: Color(0xFFEF4444), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Emergency Assistance',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If you\'re in immediate danger, contact local authorities right away.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _makePhoneCall('112'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'CALL 112',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }

  Widget _buildActionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17201C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softElevation(
            isDark: isDark,
            highContrast: false,
            strength: 0.8,
          ),
          border: Border.all(
            color: AppColors.softStroke(
              isDark: isDark,
              highContrast: false,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
