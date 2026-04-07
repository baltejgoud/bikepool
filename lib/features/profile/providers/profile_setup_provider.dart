import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/models/user_model.dart' as model;
import '../../../../core/providers/data_providers.dart';

enum VerificationMethod { governmentId, companyId }

enum VerificationStatus { incomplete, submitted, verified }

class ProfileSetupState {
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
  final bool isDocumentUploaded;
  final bool isEmailVerificationSent;
  final bool isLoading;
  final String? error;

  const ProfileSetupState({
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
    this.isDocumentUploaded = false,
    this.isEmailVerificationSent = false,
    this.isLoading = false,
    this.error,
  });

  ProfileSetupState copyWith({
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
    bool? isDocumentUploaded,
    bool? isEmailVerificationSent,
    bool? isLoading,
    String? error,
  }) {
    return ProfileSetupState(
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
      isDocumentUploaded: isDocumentUploaded ?? this.isDocumentUploaded,
      isEmailVerificationSent: isEmailVerificationSent ?? this.isEmailVerificationSent,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
    // Initialize phone number from auth if available
    final authUser = _ref.read(authStateProvider).value;
    if (authUser != null && authUser.phoneNumber != null) {
      state = state.copyWith(phoneNumber: authUser.phoneNumber);
    }
  }

  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  Future<void> simulateDocumentUpload() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false, isDocumentUploaded: true);
  }

  Future<void> simulateSendVerificationEmail() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false, isEmailVerificationSent: true);
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
    state = state.copyWith(verificationMethod: method);
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

  Future<bool> markProfileCompleted() async {
    if (!state.isComplete) {
      return false;
    }

    final authUser = _ref.read(authStateProvider).value;
    if (authUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userModel = model.UserModel(
        uid: authUser.uid,
        fullName: state.fullName,
        phoneNumber: authUser.phoneNumber ?? state.phoneNumber,
        emergencyContact: state.emergencyContact,
        homeHub: state.homeHub,
        isProfileCompleted: true,
        verificationMethod: state.verificationMethod == VerificationMethod.governmentId
            ? model.VerificationMethod.governmentId
            : model.VerificationMethod.companyId,
        verificationDetail1: state.verificationMethod == VerificationMethod.governmentId
            ? state.governmentIdNumber
            : state.companyName,
        verificationDetail2: state.verificationMethod == VerificationMethod.governmentId
            ? state.governmentIdType
            : state.companyEmail,
        verificationDetail3: state.verificationMethod == VerificationMethod.governmentId
            ? null
            : state.employeeId,
      );

      await _ref.read(userRepositoryProvider).saveUserProfile(userModel);
      
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
