import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';

class ContactSupportScreen extends ConsumerWidget {
  const ContactSupportScreen({super.key});

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'BikePool Support Request',
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
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
          'Contact Support',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17201C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    AppColors.softStroke(isDark: isDark, highContrast: false),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24/7 Support Available',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Our support team is here to help you anytime. Choose your preferred method of contact below.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildContactOption(
            isDark: isDark,
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Live Chat',
            subtitle: 'Chat with our support team instantly',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            isDark: isDark,
            icon: Icons.mail_outline_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Email',
            subtitle: 'support@bikepool.app',
            onTap: () => _launchEmail('support@bikepool.app'),
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            isDark: isDark,
            icon: Icons.call_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Phone',
            subtitle: '+1 (800) BIKEPOOL',
            onTap: () => _makePhoneCall('+18002453766'),
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            isDark: isDark,
            icon: Icons.schedule_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Schedule a Callback',
            subtitle: 'We\'ll call you at a time that works best',
            onTap: () => _showCallbackDialog(context, isDark),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader('FAQ Topics', isDark),
          const SizedBox(height: 12),
          _buildQuickLink(
            isDark: isDark,
            title: 'Account & Verification',
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 8),
          _buildQuickLink(
            isDark: isDark,
            title: 'Rides & Payments',
            icon: Icons.payment_outlined,
          ),
          const SizedBox(height: 8),
          _buildQuickLink(
            isDark: isDark,
            title: 'Safety & Security',
            icon: Icons.security_outlined,
          ),
          const SizedBox(height: 8),
          _buildQuickLink(
            isDark: isDark,
            title: 'Complaints & Appeals',
            icon: Icons.flag_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17201C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.softStroke(isDark: isDark, highContrast: false),
          ),
        ),
        child: Row(
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

  Widget _buildQuickLink({
    required bool isDark,
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17201C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softStroke(isDark: isDark, highContrast: false),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white24 : Colors.black26,
            size: 18,
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCallbackDialog(BuildContext context, bool isDark) {
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF17201C) : Colors.white,
        title: Text(
          'Schedule a Callback',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When would you like us to call?',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              readOnly: true,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Select Time',
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.access_time),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  if (!context.mounted) return;
                  timeController.text = time.format(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (timeController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('We\'ll call you at ${timeController.text}'),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Schedule',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
