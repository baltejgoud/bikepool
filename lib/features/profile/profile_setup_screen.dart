import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'providers/profile_setup_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final int initialStep;
  final bool returnToProfile;

  const ProfileSetupScreen({
    super.key,
    this.initialStep = 0,
    this.returnToProfile = false,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late int _currentStep;
  final _personalFormKey = GlobalKey<FormState>();
  final _verificationFormKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyController;
  late final TextEditingController _homeHubController;

  late final TextEditingController _governmentIdController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyEmailController;
  late final TextEditingController _employeeIdController;

  String _selectedGovernmentIdType = 'Aadhaar';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileSetupProvider);
    _currentStep = widget.initialStep.clamp(0, 3).toInt();
    _fullNameController = TextEditingController(text: profile.fullName);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _emergencyController =
        TextEditingController(text: profile.emergencyContact);
    _homeHubController = TextEditingController(text: profile.homeHub);
    _governmentIdController =
        TextEditingController(text: profile.governmentIdNumber);
    _companyNameController = TextEditingController(text: profile.companyName);
    _companyEmailController = TextEditingController(text: profile.companyEmail);
    _employeeIdController = TextEditingController(text: profile.employeeId);
    if (profile.governmentIdType.isNotEmpty) {
      _selectedGovernmentIdType = profile.governmentIdType;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _homeHubController.dispose();
    _governmentIdController.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _goNext(ProfileSetupState profile) async {
    if (_currentStep == 0) {
      if (!_personalFormKey.currentState!.validate()) {
        return;
      }
      ref.read(profileSetupProvider.notifier).savePersonalDetails(
            fullName: _fullNameController.text,
            emergencyContact: _emergencyController.text,
            homeHub: _homeHubController.text,
          );
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (!profile.hasVerificationChoice) {
        _showMessage('Choose a verification method to continue.');
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      if (!_verificationFormKey.currentState!.validate()) {
        return;
      }

      if (profile.verificationMethod == VerificationMethod.governmentId && !profile.isDocumentUploaded) {
        _showMessage('Please upload your document first.');
        return;
      }
      if (profile.verificationMethod == VerificationMethod.companyId && !profile.isEmailVerificationSent) {
        _showMessage('Please send the verification link first.');
        return;
      }

      if (profile.verificationMethod == VerificationMethod.governmentId) {
        ref.read(profileSetupProvider.notifier).saveGovernmentVerification(
              idType: _selectedGovernmentIdType,
              idNumber: _governmentIdController.text,
            );
      } else {
        ref.read(profileSetupProvider.notifier).saveCompanyVerification(
              companyName: _companyNameController.text,
              companyEmail: _companyEmailController.text,
              employeeId: _employeeIdController.text,
            );
      }
      setState(() => _currentStep = 3);
      return;
    }

    // Final step: Save to Firestore
    final success = await ref.read(profileSetupProvider.notifier).markProfileCompleted();
    
    if (!mounted) return;

    if (success) {
      if (widget.returnToProfile) {
        context.go('/home/profile');
      } else {
        context.goNamed('home');
      }
    } else {
      final error = ref.read(profileSetupProvider).error;
      _showMessage(error ?? 'Failed to save profile. Please try again.');
    }
  }

  void _goBack() {
    if (_currentStep == 0) {
      if (widget.returnToProfile) {
        context.pop();
      } else {
        context.goNamed('onboarding');
      }
      return;
    }
    setState(() => _currentStep -= 1);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileSetupProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_currentStep + 1) / 4;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1412) : const Color(0xFFF7F6F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${_currentStep + 1} of 4',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              _buildStepHeader(isDark),
              const SizedBox(height: 20),
              _buildStepBody(profile, isDark),
              const SizedBox(height: 24),
              _currentStep == 0
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _goNext(profile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _goBack,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? Colors.white : Colors.black87,
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _goNext(profile),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _currentStep == 3
                                  ? (widget.returnToProfile
                                      ? 'Save Profile'
                                      : 'Finish Setup')
                                  : 'Continue',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(bool isDark) {
    final title = switch (_currentStep) {
      0 => 'Tell us about yourself',
      1 => 'Choose your verification path',
      2 => 'Add your verification details',
      _ => 'Review before you continue',
    };

    final subtitle = switch (_currentStep) {
      0 => 'We use these details to build trust between riders and drivers.',
      1 => 'Pick the method that best matches how you use BikePool.',
      2 => 'These details stay attached to your account and trust profile.',
      _ => 'You can edit these later from the Profile section as well.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStepBody(ProfileSetupState profile, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildPersonalDetailsStep(isDark);
      case 1:
        return _buildVerificationChoiceStep(profile, isDark);
      case 2:
        return _buildVerificationDetailsStep(profile, isDark);
      default:
        return _buildReviewStep(profile, isDark);
    }
  }

  Widget _buildPersonalDetailsStep(bool isDark) {
    return Form(
      key: _personalFormKey,
      child: _buildCardShell(
        isDark: isDark,
        child: Column(
          children: [
            _buildTextField(
              controller: _fullNameController,
              label: 'Full name',
              hint: 'Enter your full name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Mobile number',
              hint: 'Verified mobile number',
              readOnly: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emergencyController,
              label: 'Emergency contact',
              hint: '10-digit emergency contact number',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().length != 10) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _homeHubController,
              label: 'Home or frequent pickup area',
              hint: 'Example: Hitech City, Hyderabad',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This helps us personalize rides';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationChoiceStep(
    ProfileSetupState profile,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildChoiceCard(
          isDark: isDark,
          title: 'Government ID',
          subtitle:
              'Best for general riders and drivers using Aadhaar, licence, or passport.',
          icon: Icons.badge_rounded,
          selected:
              profile.verificationMethod == VerificationMethod.governmentId,
          onTap: () => ref
              .read(profileSetupProvider.notifier)
              .selectVerificationMethod(VerificationMethod.governmentId),
        ),
        const SizedBox(height: 14),
        _buildChoiceCard(
          isDark: isDark,
          title: 'Company ID',
          subtitle:
              'Best for office commutes and employees verifying through workplace credentials.',
          icon: Icons.business_center_rounded,
          selected: profile.verificationMethod == VerificationMethod.companyId,
          onTap: () => ref
              .read(profileSetupProvider.notifier)
              .selectVerificationMethod(VerificationMethod.companyId),
        ),
      ],
    );
  }

  Widget _buildVerificationDetailsStep(
    ProfileSetupState profile,
    bool isDark,
  ) {
    if (profile.verificationMethod == null) {
      return _buildCardShell(
        isDark: isDark,
        child: Text(
          'Choose a verification method first.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }

    return Form(
      key: _verificationFormKey,
      child: _buildCardShell(
        isDark: isDark,
        child: profile.verificationMethod == VerificationMethod.governmentId
            ? Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGovernmentIdType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGovernmentIdType = value);
                      }
                    },
                    decoration: _inputDecoration(
                      label: 'Government ID type',
                      hint: 'Choose your document type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Aadhaar',
                        child: Text('Aadhaar'),
                      ),
                      DropdownMenuItem(
                        value: 'Driving Licence',
                        child: Text('Driving Licence'),
                      ),
                      DropdownMenuItem(
                        value: 'Passport',
                        child: Text('Passport'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _governmentIdController,
                    readOnly: profile.isDocumentUploaded,
                    label: 'Document number',
                    hint: 'Enter your document number',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Document number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (profile.isDocumentUploaded)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Document uploaded successfully!'),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: profile.isLoading
                            ? null
                            : () {
                                if (_verificationFormKey.currentState!
                                    .validate()) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .simulateDocumentUpload();
                                }
                              },
                        icon: profile.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: const Text('Upload Document Front & Back'),
                      ),
                    ),
                ],
              )
            : Column(
                children: [
                  _buildTextField(
                    controller: _companyNameController,
                    label: 'Company name',
                    hint: 'Enter your company name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Company name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _companyEmailController,
                    label: 'Work email',
                    hint: 'name@company.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty || !text.contains('@')) {
                        return 'Enter a valid work email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _employeeIdController,
                    label: 'Employee ID',
                    hint: 'Enter your employee ID',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Employee ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (profile.isEmailVerificationSent)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Verification sent! Check your inbox.'),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: profile.isLoading
                            ? null
                            : () {
                                if (_verificationFormKey.currentState!
                                    .validate()) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .simulateSendVerificationEmail();
                                }
                              },
                        child: profile.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send Verification Link'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildReviewStep(ProfileSetupState profile, bool isDark) {
    return Column(
      children: [
        _buildCardShell(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Full name', profile.fullName, isDark),
              _buildSummaryRow('Mobile', '+91 ${profile.phoneNumber}', isDark),
              _buildSummaryRow(
                'Emergency contact',
                '+91 ${profile.emergencyContact}',
                isDark,
              ),
              _buildSummaryRow('Frequent pickup', profile.homeHub, isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildCardShell(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                'Verification type',
                profile.verificationLabel,
                isDark,
              ),
              _buildSummaryRow(
                'Verification details',
                profile.verificationSummary,
                isDark,
              ),
              _buildSummaryRow(
                'Trust status',
                profile.verificationStatusLabel,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardShell({
    required bool isDark,
    required Widget child,
  }) {
    final highContrast = MediaQuery.of(context).highContrast;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171D1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: highContrast,
          strength: 0.95,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: highContrast,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildChoiceCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final highContrast = MediaQuery.of(context).highContrast;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10)
              : (isDark ? const Color(0xFF171D1A) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.softElevation(
            isDark: isDark,
            highContrast: highContrast,
            tint: selected ? AppColors.primary : null,
            strength: selected ? 0.95 : 0.85,
          ),
          border: Border.all(
            color: selected
                ? AppColors.softStroke(
                    isDark: isDark,
                    highContrast: highContrast,
                    tint: AppColors.primary,
                    strength: 1.2,
                  )
                : AppColors.softStroke(
                    isDark: isDark,
                    highContrast: highContrast,
                  ),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.white24 : Colors.black26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label: label, hint: hint),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
