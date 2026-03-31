import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F7F9),
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _ProfileHero(isDark: isDark, highContrast: highContrast),
          const SizedBox(height: 12),
          _StatsRow(isDark: isDark),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Account', isDark: isDark),
          const SizedBox(height: 10),
          _ProfileCard(
            icon: Icons.person_outline_rounded,
            iconBgColor: const Color(0xFF3B82F6),
            title: 'Personal Details',
            subtitle: 'Name, phone, emergency contacts',
            isDark: isDark,
          ),
          _ProfileCard(
            icon: Icons.shield_outlined,
            iconBgColor: const Color(0xFF10B981),
            title: 'Verification & Trust',
            subtitle: 'Government ID, company email, ride preferences',
            isDark: isDark,
          ),
          _ProfileCard(
            icon: Icons.eco_rounded,
            iconBgColor: const Color(0xFF059669),
            title: 'Carbon Footprint',
            subtitle: 'Track your environmental impact and CO₂ savings',
            isDark: isDark,
            onTap: () => context.go('/home/profile/carbon-dashboard'),
            trailingLabel: '12 kg saved',
            trailingColor: const Color(0xFF10B981),
          ),
          _ProfileCard(
            icon: Icons.emoji_events_rounded,
            iconBgColor: const Color(0xFFF59E0B),
            title: 'Achievements',
            subtitle: 'Badges, milestones, and tier progression',
            isDark: isDark,
            onTap: () => context.go('/home/profile/achievements'),
            trailingLabel: 'Gold tier',
            trailingColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Preferences', isDark: isDark),
          const SizedBox(height: 10),
          _ProfileCard(
            icon: Icons.notifications_none_rounded,
            iconBgColor: const Color(0xFF8B5CF6),
            title: 'Notifications',
            subtitle: 'Ride alerts, promotions, and updates',
            isDark: isDark,
          ),
          _ProfileCard(
            icon: Icons.tune_rounded,
            iconBgColor: const Color(0xFF6366F1),
            title: 'Ride Preferences',
            subtitle: 'Music, AC, silent ride, and more',
            isDark: isDark,
          ),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Support', isDark: isDark),
          const SizedBox(height: 10),
          _ProfileCard(
            icon: Icons.headset_mic_outlined,
            iconBgColor: const Color(0xFFEF4444),
            title: 'Help & Safety',
            subtitle: 'Trip support, safety center, and FAQs',
            isDark: isDark,
          ),
          _ProfileCard(
            icon: Icons.info_outline_rounded,
            iconBgColor: Colors.blueGrey,
            title: 'About BikePool',
            subtitle: 'Version, terms of service, and privacy policy',
            isDark: isDark,
          ),
          const SizedBox(height: 28),
          _SignOutButton(isDark: isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── PROFILE HERO ────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final bool isDark;
  final bool highContrast;

  const _ProfileHero({required this.isDark, required this.highContrast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    size: 38, color: Colors.white),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      width: 2),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aarav Sharma',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rider & Driver account',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TagChip(label: '⭐ 4.9', color: Color(0xFF9CA3AF)),
                    _TagChip(label: '✓ ID Verified', color: Color(0xFF10B981)),
                    _TagChip(label: '🏆 Gold', color: Color(0xFFF59E0B)),
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

// ── STATS ROW ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final bool isDark;
  const _StatsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '128', label: 'Rides', isDark: isDark),
        const SizedBox(width: 12),
        _StatCard(
            value: '4.9', label: 'Rating', isDark: isDark, highlight: true),
        const SizedBox(width: 12),
        _StatCard(value: '12 kg', label: 'CO₂ Saved', isDark: isDark),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final bool highlight;

  const _StatCard({
    required this.value,
    required this.label,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primary
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: (!highlight && !isDark)
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: highlight
                    ? Colors.black
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: highlight
                    ? Colors.black54
                    : (isDark ? Colors.white38 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION HEADER ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }
}

// ── PROFILE CARD ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatefulWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final String? trailingLabel;
  final Color? trailingColor;

  const _ProfileCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
    this.trailingLabel,
    this.trailingColor,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.iconBgColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.icon, color: widget.iconBgColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: widget.isDark ? Colors.white38 : Colors.black45,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing
              if (widget.trailingLabel != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.trailingColor!.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.trailingLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.trailingColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: widget.isDark ? Colors.white24 : Colors.black26,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SIGN OUT BUTTON ─────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final bool isDark;
  const _SignOutButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
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

// ── TAG CHIP ─────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
