import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/auth/auth_provider.dart';

class RidePreferencesScreen extends ConsumerWidget {
  const RidePreferencesScreen({super.key});

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
          title: const Text('Ride Preferences'),
        ),
        body: const Center(child: Text('Please sign in')),
      );
    }

    final preferencesAsync = ref.watch(currentRidePreferencesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Ride Preferences',
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
              _buildSectionHeader('General Atmosphere', isDark),
              const SizedBox(height: 12),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Silent Ride',
                    subtitle: 'Prefer less talking during the ride',
                    value: preferences.silentRide,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'silentRide',
                      val,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Pets Allowed',
                    subtitle: 'Comfortable with pets in the vehicle',
                    value: preferences.petsAllowed,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'petsAllowed',
                      val,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildToggleItem(
                    isDark: isDark,
                    title: 'Smoking Allowed',
                    subtitle: 'Comfortable with smoking during the ride',
                    value: preferences.smokingAllowed,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'smokingAllowed',
                      val,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionHeader('Comfort & Routing', isDark),
              const SizedBox(height: 12),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildDropdownItem(
                    isDark: isDark,
                    title: 'Preferred Comfort',
                    subtitle: 'Sets expectation for vehicle types',
                    value: preferences.comfortLevel,
                    items: ['Basic', 'Standard', 'Premium'],
                    onChanged: (val) {
                      if (val != null) {
                        _updatePreference(
                          ref,
                          user.uid,
                          'comfortLevel',
                          val,
                        );
                      }
                    },
                  ),
                  _buildDivider(isDark),
                  _buildSliderItem(
                    isDark: isDark,
                    title: 'Max Detour Time',
                    subtitle:
                        'Up to ${preferences.maxDetourTime.toInt()} minutes',
                    value: preferences.maxDetourTime,
                    min: 5,
                    max: 30,
                    divisions: 5,
                    onChanged: (val) => _updatePreference(
                      ref,
                      user.uid,
                      'maxDetourTime',
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
    dynamic value,
  ) {
    ref.read(updateRidePreferenceMutationProvider(
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

  Widget _buildDropdownItem({
    required bool isDark,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: isDark ? const Color(0xFF2A3630) : Colors.white,
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required bool isDark,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
              Text(
                '${value.toInt()} min',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor:
                  isDark ? const Color(0xFF2A3630) : const Color(0xFFE5E7EB),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
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
