import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import 'providers/profile_setup_provider.dart';

class VerificationTrustScreen extends ConsumerWidget {
  const VerificationTrustScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileSetupProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Verification & Trust',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrustHero(profile, isDark),
            const SizedBox(height: 32),
            Text(
              'TRUST INDICATORS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 12),
            _buildVerificationCard(
              title: 'Mobile Number',
              subtitle: '+91 ${profile.phoneNumber}',
              icon: Icons.phone_android_rounded,
              isVerified: true,
              isDark: isDark,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            if (profile.verificationMethod == VerificationMethod.governmentId)
              _buildVerificationCard(
                title: 'Government ID',
                subtitle:
                    '${profile.governmentIdType}: ${profile.governmentIdNumber.isNotEmpty ? 'Uploaded' : 'Pending'}',
                icon: Icons.badge_rounded,
                isVerified: profile.isDocumentUploaded,
                isDark: isDark,
                color: const Color(0xFF10B981),
              )
            else if (profile.verificationMethod == VerificationMethod.companyId)
              _buildVerificationCard(
                title: 'Corporate Email',
                subtitle: profile.companyEmail.isNotEmpty
                    ? profile.companyEmail
                    : 'Not provided',
                icon: Icons.business_center_rounded,
                isVerified: profile.isEmailVerificationSent,
                isDark: isDark,
                color: const Color(0xFF8B5CF6),
              )
            else
              _buildVerificationCard(
                title: 'Identity Document',
                subtitle: 'No verification method chosen',
                icon: Icons.error_outline_rounded,
                isVerified: false,
                isDark: isDark,
                color: const Color(0xFFEF4444),
                actionText: 'Add',
              ),
            const SizedBox(height: 12),
            _buildVerificationCard(
              title: 'Emergency Contact',
              subtitle: profile.emergencyContact.isNotEmpty
                  ? 'Added successfully'
                  : 'Not added',
              icon: Icons.health_and_safety_rounded,
              isVerified: profile.emergencyContact.isNotEmpty,
              isDark: isDark,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 32),
            _buildInfoBox(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustHero(ProfileSetupState profile, bool isDark) {
    final isVerified =
        profile.verificationStatus == VerificationStatus.submitted ||
            profile.verificationStatus == VerificationStatus.verified;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVerified
              ? [const Color(0xFF16A34A), const Color(0xFF047857)]
              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isVerified ? Colors.green : Colors.orange)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_user_rounded
                  : Icons.gpp_maybe_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isVerified ? 'Trusted Member' : 'Approval Pending',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.verificationSummary,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isVerified,
    required bool isDark,
    required Color color,
    String? actionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17201C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.softStroke(isDark: isDark, highContrast: false),
        ),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
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
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.green, size: 20),
            )
          else if (actionText != null)
            TextButton(
              onPressed: () {},
              child: Text(
                actionText,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your trust profile is visible only to people you match with. We never share your detailed credentials with any rider or driver.',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
