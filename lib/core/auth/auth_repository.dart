import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

/// Custom exception for authentication errors, providing structured error
/// information that callers (UI layer) can use to display appropriate messages.
class AuthException implements Exception {
  final String message;
  final String code;
  final Exception? cause;

  AuthException(this.message, {this.code = 'unknown', this.cause});

  @override
  String toString() => 'AuthException($code): $message';
}

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs in the user anonymously.
  ///
  /// Throws [AuthException] on failure so the caller can inform the user
  /// instead of silently swallowing the error.
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      dev.log(
        'Firebase Auth error during anonymous sign-in',
        name: 'AuthRepository.signInAnonymously',
        error: e,
      );
      throw AuthException(
        e.message ?? 'Failed to sign in anonymously.',
        code: e.code,
        cause: e,
      );
    } catch (e) {
      dev.log(
        'Unexpected error during anonymous sign-in',
        name: 'AuthRepository.signInAnonymously',
        error: e,
      );
      throw AuthException(
        'An unexpected error occurred during sign-in.',
        code: 'unexpected',
      );
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    // In debug mode on Android, disable app verification to bypass the
    // reCAPTCHA/Play Integrity flow which fails for sideloaded debug builds.
    // This is safe because it only runs in debug builds.
    if (kDebugMode && !kIsWeb) {
      await _auth.setSettings(appVerificationDisabledForTesting: true);
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Signs in the user with an OTP code.
  ///
  /// Throws [AuthException] on failure with the Firebase error code, so the UI
  /// can distinguish between invalid OTP, expired session, rate limiting, etc.
  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      dev.log(
        'Firebase Auth error during OTP sign-in',
        name: 'AuthRepository.signInWithOTP',
        error: e,
      );
      throw AuthException(
        _userFriendlyOTPMessage(e.code),
        code: e.code,
        cause: e,
      );
    } catch (e) {
      dev.log(
        'Unexpected error during OTP sign-in',
        name: 'AuthRepository.signInWithOTP',
        error: e,
      );
      throw AuthException(
        'An unexpected error occurred during verification.',
        code: 'unexpected',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _userFriendlyOTPMessage(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect. Please try again.';
      case 'session-expired':
        return 'Your verification session has expired. Please request a new code.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again after some time.';
      case 'invalid-verification-id':
        return 'Verification session is invalid. Please restart the process.';
      default:
        return 'Verification failed. Please try again.';
    }
  }
}
