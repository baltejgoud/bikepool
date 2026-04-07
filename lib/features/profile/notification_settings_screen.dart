import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/auth/auth_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const AppBackButton(),
          title: const Text('Notifications'),
        ),
        body: const Center(child: Text('Please sign in')),
      );
    }

    final preferencesAsync = ref.watch(currentNotificationPreferencesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
      ),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (preferences) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const SizedBox(height: 10),
              _buildSectionHeader('Push Notifications', isDark),
              const SizedBox(height: 12),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Ride Alerts',
                    subtitle: 'Updates about your requested or offered rides',
                    value: preferences.rideAlerts,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'rideAlerts',
                      val,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Messages',
                    subtitle: 'When other users message you',
                    value: preferences.messages,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'messages',
                      val,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Promotions',
                    subtitle: 'Discounts, campaigns, and news',
                    value: preferences.promotions,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'promotions',
                      val,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionHeader('Account & Security', isDark),
              const SizedBox(height: 12),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Security Alerts',
                    subtitle: 'Login attempts, password changes, etc.',
                    value: preferences.accountSecurity,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'accountSecurity',
                      val,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Email Updates',
                    subtitle: 'Receive monthly summaries and receipts',
                    value: preferences.emailUpdates,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'emailUpdates',
                      val,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _updatePreference(
    WidgetRef ref,
    String userId,
    String field,
    bool value,
  ) {
    ref.read(updateNotificationPreferenceMutationProvider(
      (userId: userId, field: field, value: value),
    ));
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

  Widget _buildSettingsCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildToggleItem({
    required bool isDark,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: isDark ? Colors.white54 : Colors.black38,
            inactiveTrackColor:
                isDark ? const Color(0xFF2A3630) : const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.softStroke(isDark: isDark, highContrast: false),
    );
  }
}
