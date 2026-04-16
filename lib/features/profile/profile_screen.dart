import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_pill.dart';
import 'providers/profile_setup_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
          'Profile',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 24,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ProfileHero(profile: profile, isDark: isDark),
          const SizedBox(height: 14),
          _ProfileStats(profile: profile, isDark: isDark),
          const SizedBox(height: 28),
          _SectionLabel(title: 'Account', isDark: isDark),
          const SizedBox(height: 10),
          _ProfileActionCard(
            isDark: isDark,
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Personal Details',
            subtitle: profile.fullName.isEmpty
                ? 'Add your name, phone and emergency contact'
                : '${profile.fullName} - +91 ${profile.phoneNumber}',
            trailingLabel: profile.hasPersonalDetails ? 'Complete' : 'Required',
            trailingColor:
                profile.hasPersonalDetails ? AppColors.primary : Colors.orange,
            onTap: () => context.go('/home/profile/personal-details'),
          ),
          _ProfileActionCard(
            isDark: isDark,
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Verification & Trust',
            subtitle: profile.verificationSummary,
            trailingLabel: profile.verificationStatusLabel,
            trailingColor:
                profile.verificationStatus == VerificationStatus.submitted
                    ? const Color(0xFF10B981)
                    : Colors.orange,
            onTap: () => context.go('/home/profile/verification-trust'),
          ),
          const SizedBox(height: 28),
          _SectionLabel(title: 'Insights', isDark: isDark),
          const SizedBox(height: 10),
          _ProfileActionCard(
            isDark: isDark,
            icon: Icons.eco_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Carbon Footprint',
            subtitle: 'Track your environmental impact and shared trip savings',
            trailingLabel: '12 kg saved',
            trailingColor: const Color(0xFF10B981),
            onTap: () => context.go('/home/profile/carbon-dashboard'),
          ),
          _ProfileActionCard(
            isDark: isDark,
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Achievements',
            subtitle: 'Badges, milestones, and trust progression',
            trailingLabel: 'Gold tier',
            trailingColor: const Color(0xFFF59E0B),
            onTap: () => context.go('/home/profile/achievements'),
          ),
          const SizedBox(height: 28),
          _SectionLabel(title: 'Preferences', isDark: isDark),
          const SizedBox(height: 10),
          _ProfileActionCard(
            isDark: isDark,
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Notifications',
            subtitle: 'Ride alerts, approvals, and commute reminders',
            onTap: () => context.go('/home/profile/notifications'),
          ),
          _ProfileActionCard(
            isDark: isDark,
            icon: Icons.tune_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Ride Preferences',
            subtitle: 'Comfort, silent ride, and commute preferences',
            onTap: () => context.go('/home/profile/ride-preferences'),
          ),
          const SizedBox(height: 28),
          _SectionLabel(title: 'Support', isDark: isDark),
          const SizedBox(height: 10),
          _ProfileActionCard(
            isDark: isDark,
            icon: Icons.headset_mic_outlined,
            iconColor: const Color(0xFFEF4444),
            title: 'Help & Safety',
            subtitle: 'Trip support, safety center, and FAQs',
            onTap: () => context.go('/home/profile/help-safety'),
          ),
          const SizedBox(height: 28),
          _SignOutButton(
            isDark: isDark,
            onTap: () async {
              ref.read(profileSetupProvider.notifier).reset();
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final ProfileSetupState profile;
  final bool isDark;

  const _ProfileHero({
    required this.profile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17201C) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.95,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF174D3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName.isEmpty
                      ? 'Complete your profile'
                      : profile.fullName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phoneNumber.isEmpty
                      ? 'Shared rider and driver account'
                      : '+91 ${profile.phoneNumber} - Rider & Driver account',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                 Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppPill(
                      label: profile.isComplete
                          ? 'Setup complete'
                          : 'Setup pending',
                      pillContext: profile.isComplete
                          ? AppPillContext.primary
                          : AppPillContext.warning,
                      icon: profile.isComplete ? Icons.check_circle_rounded : Icons.pending_rounded,
                    ),
                    AppPill(
                      label: profile.verificationStatusLabel,
                      pillContext: profile.verificationStatus ==
                              VerificationStatus.submitted
                          ? AppPillContext.success
                          : AppPillContext.neutral,
                      icon: Icons.verified_user_rounded,
                    ),
                    AppPill(
                      label: profile.verificationLabel,
                      pillContext: AppPillContext.info,
                      icon: Icons.security_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final ProfileSetupState profile;
  final bool isDark;

  const _ProfileStats({
    required this.profile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBlock(
            isDark: isDark,
            value: profile.hasPersonalDetails ? '100%' : '60%',
            label: 'Identity',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBlock(
            isDark: isDark,
            value: profile.hasVerificationDetails ? 'Ready' : 'Pending',
            label: 'Trust',
            highlight: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBlock(
            isDark: isDark,
            value: 'Shared',
            label: 'Wallet',
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final bool isDark;
  final String value;
  final String label;
  final bool highlight;

  const _StatBlock({
    required this.isDark,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary
            : (isDark ? const Color(0xFF17201C) : Colors.white),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: highlight
                  ? Colors.white70
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionLabel({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _ProfileActionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingLabel;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _ProfileActionCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailingLabel,
    this.trailingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
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
            if (trailingLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: trailingColor!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailingLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trailingColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _SignOutButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _SignOutButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C1A1A) : const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded,
                color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
