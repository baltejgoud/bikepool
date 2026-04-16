import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/models/user_model.dart' as model;
import '../../../../core/providers/data_providers.dart';

enum VerificationMethod { governmentId, companyId }

enum VerificationStatus { incomplete, submitted, verified }

class ProfileSetupState {
  final int currentStep;
  final String fullName;
  final String phoneNumber;
  final String emergencyContact;
  final String homeHub;
  final VerificationMethod? verificationMethod;
  final String governmentIdType;
  final String governmentIdNumber;
  final String companyName;
  final String companyEmail;
  final String employeeId;
  final VerificationStatus verificationStatus;
  // Document images (kept as bytes for preview; upload happens on final save)
  final Uint8List? frontImageBytes;
  final Uint8List? backImageBytes;
  final String? frontImageName;
  final String? backImageName;
  // Company email verification state
  final bool isEmailVerificationSent;
  final bool isLoading;
  final String? error;

  const ProfileSetupState({
    this.currentStep = 0,
    this.fullName = '',
    this.phoneNumber = '',
    this.emergencyContact = '',
    this.homeHub = '',
    this.verificationMethod,
    this.governmentIdType = '',
    this.governmentIdNumber = '',
    this.companyName = '',
    this.companyEmail = '',
    this.employeeId = '',
    this.verificationStatus = VerificationStatus.incomplete,
    this.frontImageBytes,
    this.backImageBytes,
    this.frontImageName,
    this.backImageName,
    this.isEmailVerificationSent = false,
    this.isLoading = false,
    this.error,
  });

  /// Both sides must be chosen for the document to be considered complete.
  bool get isFrontUploaded => frontImageBytes != null;
  bool get isBackUploaded => backImageBytes != null;
  bool get isDocumentUploaded => isFrontUploaded && isBackUploaded;

  ProfileSetupState copyWith({
    int? currentStep,
    String? fullName,
    String? phoneNumber,
    String? emergencyContact,
    String? homeHub,
    VerificationMethod? verificationMethod,
    String? governmentIdType,
    String? governmentIdNumber,
    String? companyName,
    String? companyEmail,
    String? employeeId,
    VerificationStatus? verificationStatus,
    Uint8List? frontImageBytes,
    Uint8List? backImageBytes,
    String? frontImageName,
    String? backImageName,
    bool? isEmailVerificationSent,
    bool? isLoading,
    String? error,
    bool clearFront = false,
    bool clearBack = false,
    bool clearError = false,
  }) {
    return ProfileSetupState(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      homeHub: homeHub ?? this.homeHub,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      governmentIdType: governmentIdType ?? this.governmentIdType,
      governmentIdNumber: governmentIdNumber ?? this.governmentIdNumber,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      employeeId: employeeId ?? this.employeeId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      frontImageBytes: clearFront ? null : (frontImageBytes ?? this.frontImageBytes),
      backImageBytes: clearBack ? null : (backImageBytes ?? this.backImageBytes),
      frontImageName: clearFront ? null : (frontImageName ?? this.frontImageName),
      backImageName: clearBack ? null : (backImageName ?? this.backImageName),
      isEmailVerificationSent:
          isEmailVerificationSent ?? this.isEmailVerificationSent,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasPersonalDetails =>
      fullName.trim().isNotEmpty &&
      emergencyContact.trim().length == 10 &&
      homeHub.trim().isNotEmpty;

  bool get hasVerificationChoice => verificationMethod != null;

  bool get hasVerificationDetails {
    switch (verificationMethod) {
      case VerificationMethod.governmentId:
        return governmentIdType.trim().isNotEmpty &&
            governmentIdNumber.trim().isNotEmpty &&
            isDocumentUploaded;
      case VerificationMethod.companyId:
        return companyName.trim().isNotEmpty &&
            companyEmail.trim().isNotEmpty &&
            employeeId.trim().isNotEmpty &&
            isEmailVerificationSent;
      case null:
        return false;
    }
  }

  bool get isComplete => hasPersonalDetails && hasVerificationDetails;

  String get verificationLabel {
    switch (verificationMethod) {
      case VerificationMethod.governmentId:
        return 'Government ID';
      case VerificationMethod.companyId:
        return 'Company ID';
      case null:
        return 'Not selected';
    }
  }

  String get verificationSummary {
    switch (verificationMethod) {
      case VerificationMethod.governmentId:
        if (governmentIdType.isEmpty || governmentIdNumber.isEmpty) {
          return 'Pending document details';
        }
        final suffix = governmentIdNumber.length >= 4
            ? governmentIdNumber.substring(governmentIdNumber.length - 4)
            : governmentIdNumber;
        return '$governmentIdType ending in $suffix';
      case VerificationMethod.companyId:
        if (companyName.isEmpty || companyEmail.isEmpty) {
          return 'Pending company details';
        }
        return '$companyName - $companyEmail';
      case null:
        return 'Choose verification method';
    }
  }

  String get verificationStatusLabel {
    switch (verificationStatus) {
      case VerificationStatus.incomplete:
        return 'Incomplete';
      case VerificationStatus.submitted:
        return 'Submitted';
      case VerificationStatus.verified:
        return 'Verified';
    }
  }
}

class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  final Ref _ref;

  ProfileSetupNotifier(this._ref) : super(const ProfileSetupState()) {
    final authUser = _ref.read(authStateProvider).value;
    if (authUser != null && authUser.phoneNumber != null) {
      state = state.copyWith(phoneNumber: authUser.phoneNumber);
    }
  }

  // ---------------------------------------------------------------------------
  // Step navigation
  // ---------------------------------------------------------------------------

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step.clamp(0, 3), clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ---------------------------------------------------------------------------
  // Field updates
  // ---------------------------------------------------------------------------

  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  void savePersonalDetails({
    required String fullName,
    required String emergencyContact,
    required String homeHub,
  }) {
    state = state.copyWith(
      fullName: fullName.trim(),
      emergencyContact: emergencyContact.trim(),
      homeHub: homeHub.trim(),
    );
  }

  void selectVerificationMethod(VerificationMethod method) {
    // Reset document images when switching methods
    state = state.copyWith(
      verificationMethod: method,
      clearFront: true,
      clearBack: true,
      clearError: true,
    );
  }

  void saveGovernmentVerification({
    required String idType,
    required String idNumber,
  }) {
    state = state.copyWith(
      verificationMethod: VerificationMethod.governmentId,
      governmentIdType: idType.trim(),
      governmentIdNumber: idNumber.trim(),
      verificationStatus: VerificationStatus.submitted,
    );
  }

  void saveCompanyVerification({
    required String companyName,
    required String companyEmail,
    required String employeeId,
  }) {
    state = state.copyWith(
      verificationMethod: VerificationMethod.companyId,
      companyName: companyName.trim(),
      companyEmail: companyEmail.trim(),
      employeeId: employeeId.trim(),
      verificationStatus: VerificationStatus.submitted,
    );
  }

  // ---------------------------------------------------------------------------
  // Document image selection (called from screen after ImagePicker resolves)
  // ---------------------------------------------------------------------------

  void setFrontImage(Uint8List bytes, String name) {
    state = state.copyWith(
      frontImageBytes: bytes,
      frontImageName: name,
      clearError: true,
    );
  }

  void setBackImage(Uint8List bytes, String name) {
    state = state.copyWith(
      backImageBytes: bytes,
      backImageName: name,
      clearError: true,
    );
  }

  void removeFrontImage() {
    state = state.copyWith(clearFront: true);
  }

  void removeBackImage() {
    state = state.copyWith(clearBack: true);
  }

  // ---------------------------------------------------------------------------
  // Company email verification
  // ---------------------------------------------------------------------------

  Future<void> simulateSendVerificationEmail() async {
    final authUser = _ref.read(authStateProvider).value;
    if (authUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    if (state.verificationMethod != VerificationMethod.companyId) {
      state = state.copyWith(error: 'Choose company ID verification first');
      return;
    }
    if (state.companyName.trim().isEmpty ||
        state.companyEmail.trim().isEmpty ||
        state.employeeId.trim().isEmpty) {
      state = state.copyWith(
          error: 'Enter your company details before sending verification email');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _ref
          .read(userRepositoryProvider)
          .updateUserProfileFields(authUser.uid, {
        'verificationMethod': VerificationMethod.companyId.name,
        'verificationDetail1': state.companyName,
        'verificationDetail2': state.companyEmail,
        'verificationDetail3': state.employeeId,
        'verificationStatus': VerificationStatus.submitted.name,
        'isEmailVerificationSent': true,
      });
      state = state.copyWith(
        isLoading: false,
        isEmailVerificationSent: true,
        verificationStatus: VerificationStatus.submitted,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Final save — uploads document bytes to Firestore metadata + marks complete
  // ---------------------------------------------------------------------------

  Future<bool> markProfileCompleted() async {
    if (!state.isComplete) return false;

    final authUser = _ref.read(authStateProvider).value;
    if (authUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userModel = model.UserModel(
        uid: authUser.uid,
        fullName: state.fullName,
        phoneNumber: authUser.phoneNumber ?? state.phoneNumber,
        emergencyContact: state.emergencyContact,
        homeHub: state.homeHub,
        isProfileCompleted: true,
        verificationMethod:
            state.verificationMethod == VerificationMethod.governmentId
                ? model.VerificationMethod.governmentId
                : model.VerificationMethod.companyId,
        verificationDetail1:
            state.verificationMethod == VerificationMethod.governmentId
                ? state.governmentIdNumber
                : state.companyName,
        verificationDetail2:
            state.verificationMethod == VerificationMethod.governmentId
                ? state.governmentIdType
                : state.companyEmail,
        verificationDetail3:
            state.verificationMethod == VerificationMethod.governmentId
                ? null
                : state.employeeId,
        isDocumentUploaded: state.isDocumentUploaded,
        frontDocUrl: null, // Will be updated if uploaded
        backDocUrl: null,
        isEmailVerificationSent: state.isEmailVerificationSent,
        verificationStatus: VerificationStatus.submitted.name,
      );

      model.UserModel userToSave = userModel;

      // Upload documents if needed
      if (state.verificationMethod == VerificationMethod.governmentId &&
          state.isDocumentUploaded) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('users/${authUser.uid}/verification_docs');

          String? frontUrl;
          if (state.frontImageBytes != null) {
            final frontRef = storageRef.child('front.jpg');
            await frontRef.putData(state.frontImageBytes!);
            frontUrl = await frontRef.getDownloadURL();
          }

          String? backUrl;
          if (state.backImageBytes != null) {
            final backRef = storageRef.child('back.jpg');
            await backRef.putData(state.backImageBytes!);
            backUrl = await backRef.getDownloadURL();
          }

          userToSave = userModel.copyWith(
            frontDocUrl: frontUrl,
            backDocUrl: backUrl,
          );
        } catch (e) {
          state = state.copyWith(isLoading: false, error: 'Failed to upload documents: $e');
          return false;
        }
      }

      await _ref.read(userRepositoryProvider).saveUserProfile(userToSave);

      state = state.copyWith(
        verificationStatus: VerificationStatus.submitted,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const ProfileSetupState();
  }
}

final profileSetupProvider =
    StateNotifierProvider<ProfileSetupNotifier, ProfileSetupState>((ref) {
  return ProfileSetupNotifier(ref);
});
