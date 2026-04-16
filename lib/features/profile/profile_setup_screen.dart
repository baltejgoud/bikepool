import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
  final _personalFormKey = GlobalKey<FormState>();
  final _verificationFormKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Loading state for individual image pickers (local only – not in provider)
  bool _isPickingFront = false;
  bool _isPickingBack = false;

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
    _fullNameController = TextEditingController(text: profile.fullName);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _emergencyController = TextEditingController(text: profile.emergencyContact);
    _homeHubController = TextEditingController(text: profile.homeHub);
    _governmentIdController = TextEditingController(text: profile.governmentIdNumber);
    _companyNameController = TextEditingController(text: profile.companyName);
    _companyEmailController = TextEditingController(text: profile.companyEmail);
    _employeeIdController = TextEditingController(text: profile.employeeId);
    if (profile.governmentIdType.isNotEmpty) {
      _selectedGovernmentIdType = profile.governmentIdType;
    }

    if (profile.currentStep == 0 && widget.initialStep > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileSetupProvider.notifier).setStep(widget.initialStep.clamp(0, 3));
      });
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

  // ---------------------------------------------------------------------------
  // Image picking
  // ---------------------------------------------------------------------------

  Future<void> _pickFrontImage() async {
    if (_isPickingFront) return;
    // Save ID details before opening picker so state is consistent
    if (!(_verificationFormKey.currentState?.validate() ?? false)) return;
    ref.read(profileSetupProvider.notifier).saveGovernmentVerification(
          idType: _selectedGovernmentIdType,
          idNumber: _governmentIdController.text,
        );

    setState(() => _isPickingFront = true);
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (xFile != null && mounted) {
        final bytes = await xFile.readAsBytes();
        ref.read(profileSetupProvider.notifier).setFrontImage(bytes, xFile.name);
      }
    } catch (e) {
      if (mounted) _showMessage('Could not open image picker: $e');
    } finally {
      if (mounted) setState(() => _isPickingFront = false);
    }
  }

  Future<void> _pickBackImage() async {
    if (_isPickingBack) return;
    if (!(_verificationFormKey.currentState?.validate() ?? false)) return;
    ref.read(profileSetupProvider.notifier).saveGovernmentVerification(
          idType: _selectedGovernmentIdType,
          idNumber: _governmentIdController.text,
        );

    setState(() => _isPickingBack = true);
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (xFile != null && mounted) {
        final bytes = await xFile.readAsBytes();
        ref.read(profileSetupProvider.notifier).setBackImage(bytes, xFile.name);
      }
    } catch (e) {
      if (mounted) _showMessage('Could not open image picker: $e');
    } finally {
      if (mounted) setState(() => _isPickingBack = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<void> _goNext(ProfileSetupState profile) async {
    final currentStep = profile.currentStep;

    if (currentStep == 0) {
      if (!_personalFormKey.currentState!.validate()) return;
      ref.read(profileSetupProvider.notifier).savePersonalDetails(
            fullName: _fullNameController.text,
            emergencyContact: _emergencyController.text,
            homeHub: _homeHubController.text,
          );
      ref.read(profileSetupProvider.notifier).nextStep();
      return;
    }

    if (currentStep == 1) {
      if (!profile.hasVerificationChoice) {
        _showMessage('Choose a verification method to continue.');
        return;
      }
      ref.read(profileSetupProvider.notifier).nextStep();
      return;
    }

    if (currentStep == 2) {
      if (!_verificationFormKey.currentState!.validate()) return;

      if (profile.verificationMethod == VerificationMethod.governmentId) {
        if (!profile.isFrontUploaded || !profile.isBackUploaded) {
          _showMessage(
            !profile.isFrontUploaded && !profile.isBackUploaded
                ? 'Please add both sides of your document.'
                : !profile.isFrontUploaded
                    ? 'Please add the front side of your document.'
                    : 'Please add the back side of your document.',
          );
          return;
        }
        ref.read(profileSetupProvider.notifier).saveGovernmentVerification(
              idType: _selectedGovernmentIdType,
              idNumber: _governmentIdController.text,
            );
      } else {
        if (!profile.isEmailVerificationSent) {
          _showMessage('Please send the verification link first.');
          return;
        }
        ref.read(profileSetupProvider.notifier).saveCompanyVerification(
              companyName: _companyNameController.text,
              companyEmail: _companyEmailController.text,
              employeeId: _employeeIdController.text,
            );
      }
      ref.read(profileSetupProvider.notifier).nextStep();
      return;
    }

    // Final step
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

  void _goBack(int currentStep) {
    if (currentStep == 0) {
      if (widget.returnToProfile) {
        context.pop();
      } else {
        context.goNamed('onboarding');
      }
      return;
    }
    ref.read(profileSetupProvider.notifier).previousStep();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileSetupProvider);
    final currentStep = profile.currentStep;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (currentStep + 1) / 4;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1412) : const Color(0xFFF7F6F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _goBack(currentStep),
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
                'Step ${currentStep + 1} of 4',
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
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              _buildStepHeader(currentStep, isDark),
              const SizedBox(height: 20),
              _buildStepBody(profile, isDark),
              const SizedBox(height: 24),
              currentStep == 0
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
                            onPressed: () => _goBack(currentStep),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black87,
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
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: profile.isLoading ? null : () => _goNext(profile),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: profile.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    currentStep == 3
                                        ? (widget.returnToProfile ? 'Save Profile' : 'Finish Setup')
                                        : 'Continue',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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

  Widget _buildStepHeader(int currentStep, bool isDark) {
    final title = switch (currentStep) {
      0 => 'Tell us about yourself',
      1 => 'Choose your verification path',
      2 => 'Add your verification details',
      _ => 'Review before you continue',
    };
    final subtitle = switch (currentStep) {
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
    switch (profile.currentStep) {
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

  // ---------------------------------------------------------------------------
  // Step 0 – Personal details
  // ---------------------------------------------------------------------------

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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
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
              validator: (v) =>
                  (v == null || v.trim().length != 10) ? 'Enter a valid 10-digit number' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _homeHubController,
              label: 'Home or frequent pickup area',
              hint: 'Example: Hitech City, Hyderabad',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'This helps us personalize rides' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 – Verification choice
  // ---------------------------------------------------------------------------

  Widget _buildVerificationChoiceStep(ProfileSetupState profile, bool isDark) {
    return Column(
      children: [
        _buildChoiceCard(
          isDark: isDark,
          title: 'Government ID',
          subtitle:
              'Best for general riders and drivers using Aadhaar, licence, or passport.',
          icon: Icons.badge_rounded,
          selected: profile.verificationMethod == VerificationMethod.governmentId,
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

  // ---------------------------------------------------------------------------
  // Step 2 – Verification details
  // ---------------------------------------------------------------------------

  Widget _buildVerificationDetailsStep(ProfileSetupState profile, bool isDark) {
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
      child: profile.verificationMethod == VerificationMethod.governmentId
          ? _buildGovernmentIdSection(profile, isDark)
          : _buildCardShell(isDark: isDark, child: _buildCompanyIdForm(profile, isDark)),
    );
  }

  // --- Government ID ---

  Widget _buildGovernmentIdSection(ProfileSetupState profile, bool isDark) {
    return Column(
      children: [
        _buildCardShell(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedGovernmentIdType,
                onChanged: profile.isDocumentUploaded
                    ? null
                    : (value) {
                        if (value != null) setState(() => _selectedGovernmentIdType = value);
                      },
                decoration: _inputDecoration(
                  label: 'Government ID type',
                  hint: 'Choose your document type',
                ),
                items: const [
                  DropdownMenuItem(value: 'Aadhaar', child: Text('Aadhaar')),
                  DropdownMenuItem(value: 'Driving Licence', child: Text('Driving Licence')),
                  DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _governmentIdController,
                label: 'Document number',
                hint: 'Enter your document number',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Document number is required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Upload section ---
        _buildCardShell(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Document Photos',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap each slot to choose a clear photo from your gallery. Both sides are required.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 16),

              // Front
              _buildImagePickerTile(
                isDark: isDark,
                label: 'Front side',
                sublabel: 'The side with your name & photo',
                imageBytes: profile.frontImageBytes,
                isPicking: _isPickingFront,
                onTap: _isPickingFront ? null : _pickFrontImage,
                onRemove: profile.isFrontUploaded
                    ? () => ref.read(profileSetupProvider.notifier).removeFrontImage()
                    : null,
              ),
              const SizedBox(height: 12),

              // Back
              _buildImagePickerTile(
                isDark: isDark,
                label: 'Back side',
                sublabel: 'The reverse side of the document',
                imageBytes: profile.backImageBytes,
                isPicking: _isPickingBack,
                onTap: _isPickingBack ? null : _pickBackImage,
                onRemove: profile.isBackUploaded
                    ? () => ref.read(profileSetupProvider.notifier).removeBackImage()
                    : null,
              ),

              // Both done banner
              if (profile.isDocumentUploaded) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Both sides added — you\'re good to continue!',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// A tappable image slot that shows a preview when an image is selected.
  Widget _buildImagePickerTile({
    required bool isDark,
    required String label,
    required String sublabel,
    required Uint8List? imageBytes,
    required bool isPicking,
    required VoidCallback? onTap,
    VoidCallback? onRemove,
  }) {
    final hasImage = imageBytes != null;

    return GestureDetector(
      onTap: hasImage ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasImage
              ? Colors.transparent
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? Colors.green.withValues(alpha: 0.45)
                : isPicking
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : (isDark ? Colors.white12 : Colors.black12),
            width: hasImage ? 1.5 : 1.2,
          ),
        ),
        child: hasImage
            ? _buildImagePreview(
                isDark: isDark,
                label: label,
                imageBytes: imageBytes,
                onRemove: onRemove,
                onReplace: onTap,
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPicking
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: isPicking
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            )
                          : Icon(
                              Icons.add_photo_alternate_rounded,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPicking ? 'Opening gallery…' : sublabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isPicking
                                  ? AppColors.primary
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isPicking)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildImagePreview({
    required bool isDark,
    required String label,
    required Uint8List imageBytes,
    VoidCallback? onRemove,
    VoidCallback? onReplace,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.memory(
                imageBytes,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            // Label badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Remove button
            if (onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 17),
                  ),
                ),
              ),
          ],
        ),
        // Replace / confirmed row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Image selected',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              if (onReplace != null)
                GestureDetector(
                  onTap: onReplace,
                  child: Text(
                    'Replace',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Company ID ---

  Widget _buildCompanyIdForm(ProfileSetupState profile, bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _companyNameController,
          label: 'Company name',
          hint: 'Enter your company name',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _companyEmailController,
          label: 'Work email',
          hint: 'name@company.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final t = v?.trim() ?? '';
            return (t.isEmpty || !t.contains('@')) ? 'Enter a valid work email' : null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _employeeIdController,
          label: 'Employee ID',
          hint: 'Enter your employee ID',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Employee ID is required' : null,
        ),
        const SizedBox(height: 16),
        if (profile.isEmailVerificationSent)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verification sent! Check your inbox.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: profile.isLoading
                  ? null
                  : () {
                      if (_verificationFormKey.currentState!.validate()) {
                        ref
                            .read(profileSetupProvider.notifier)
                            .saveCompanyVerification(
                              companyName: _companyNameController.text,
                              companyEmail: _companyEmailController.text,
                              employeeId: _employeeIdController.text,
                            );
                        ref
                            .read(profileSetupProvider.notifier)
                            .simulateSendVerificationEmail();
                      }
                    },
              child: profile.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Send Verification Link',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 – Review
  // ---------------------------------------------------------------------------

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
                'Emergency contact', '+91 ${profile.emergencyContact}', isDark),
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
              _buildSummaryRow('Verification type', profile.verificationLabel, isDark),
              _buildSummaryRow(
                  'Verification details', profile.verificationSummary, isDark),
              _buildSummaryRow(
                  'Trust status', profile.verificationStatusLabel, isDark),
            ],
          ),
        ),
        // Document thumbnails in review
        if (profile.verificationMethod == VerificationMethod.governmentId &&
            profile.isDocumentUploaded) ...[
          const SizedBox(height: 14),
          _buildCardShell(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Photos',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniThumb(
                          label: 'Front', bytes: profile.frontImageBytes),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniThumb(
                          label: 'Back', bytes: profile.backImageBytes),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniThumb({required String label, required Uint8List? bytes}) {
    if (bytes == null) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, height: 80, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade600,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  Widget _buildCardShell({required bool isDark, required Widget child}) {
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
          color: AppColors.softStroke(isDark: isDark, highContrast: highContrast),
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
                : AppColors.softStroke(isDark: isDark, highContrast: highContrast),
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

  InputDecoration _inputDecoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
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
