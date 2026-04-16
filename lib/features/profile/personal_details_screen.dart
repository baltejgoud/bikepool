import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import 'providers/profile_setup_provider.dart';

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  ConsumerState<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyController;
  late final TextEditingController _homeHubController;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileSetupProvider);
    _fullNameController = TextEditingController(text: profile.fullName);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _emergencyController =
        TextEditingController(text: profile.emergencyContact);
    _homeHubController = TextEditingController(text: profile.homeHub);

    void listener() {
      final hasChanged = _fullNameController.text != profile.fullName ||
          _emergencyController.text != profile.emergencyContact ||
          _homeHubController.text != profile.homeHub;
      if (_hasChanges != hasChanged) {
        setState(() => _hasChanges = hasChanged);
      }
    }

    _fullNameController.addListener(listener);
    _emergencyController.addListener(listener);
    _homeHubController.addListener(listener);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _homeHubController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    ref.read(profileSetupProvider.notifier).savePersonalDetails(
          fullName: _fullNameController.text.trim(),
          emergencyContact: _emergencyController.text.trim(),
          homeHub: _homeHubController.text.trim(),
        );

    final success =
        await ref.read(profileSetupProvider.notifier).markProfileCompleted();

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal details updated successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save changes. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Personal Details',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderProfile(isDark),
              const SizedBox(height: 32),
              _buildInputField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _phoneController,
                label: 'Mobile Number',
                hint: '+91 00000 00000',
                icon: Icons.phone_outlined,
                isDark: isDark,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _emergencyController,
                label: 'Emergency Contact',
                hint: 'Enter 10-digit number',
                icon: Icons.health_and_safety_outlined,
                keyboardType: TextInputType.phone,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().length != 10) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _homeHubController,
                label: 'Frequent Pickup Area',
                hint: 'E.g., Hitech City',
                icon: Icons.home_work_outlined,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _hasChanges
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Hero(
                  tag: 'saveBtn',
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderProfile(bool isDark) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF17201C) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppColors.softElevation(
              isDark: isDark,
              highContrast: false,
              strength: 0.8,
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.face_retouching_natural_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your Identity',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Used to build trust and personalize your rides.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly
                ? (isDark ? Colors.white38 : Colors.black38)
                : (isDark ? Colors.white : Colors.black87),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            prefixIcon: Icon(
              icon,
              color: readOnly
                  ? (isDark ? Colors.white24 : Colors.black26)
                  : AppColors.primary,
              size: 22,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF17201C) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}
