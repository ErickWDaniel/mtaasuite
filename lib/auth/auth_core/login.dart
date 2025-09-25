// login_core.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Callback typedefs for clearer and safer function signatures
typedef CodeSentCallback = void Function();
typedef ErrorCallback = void Function(String message);

class LoginCore {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // _verificationId is set during codeSent/callbacks and is used in OTP verification.
  // Be sure only one verification flow runs at a time to avoid race conditions.
  String _verificationId = "";

  // Validates phone number. Basic E.164 check (starts with + and at least 10 digits)
  bool _validatePhoneNumber(String phoneNumber) {
    // E.164: leading + and 10-15 digits total
    final regex = RegExp(r'^\+[1-9]\d{9,14}$');
    return regex.hasMatch(phoneNumber);
  }

  // Validates code (simple length check, usually 6)
  bool _validateSMSCode(String smsCode) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(smsCode);
  }

  // Step 1: Send OTP
  Future<void> sendOTP(
    String phoneNumber,
    CodeSentCallback onCodeSent,
    ErrorCallback onError,
  ) async {
    if (!_validatePhoneNumber(phoneNumber)) {
      onError("Invalid phone number format. Please use E.164 format (e.g., +12345678900)");
      return;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification (Android only) - rely on AuthWrapper for routing
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            developer.log('Auto sign-in error', error: e, name: 'LoginCore');
            onError("Automatic verification failed. Please enter the OTP manually if you receive one.");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          final msg = e.message ?? "Verification failed. Please try again.";
          developer.log('Verification failed', error: e, name: 'LoginCore');
          onError(msg);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      developer.log('Failed during sendOTP', error: e, name: 'LoginCore');
      onError("Unexpected error during OTP request. Please try again later.");
    }
  }

  // Step 2: Verify OTP
  Future<void> verifyOTP(
    String smsCode,
    BuildContext context,
    ErrorCallback onError,
  ) async {
    if (!_validateSMSCode(smsCode)) {
      onError("Invalid OTP format. OTP must be 6 digits.");
      return;
    }

    // Ensure a verification flow was started
    if (_verificationId.isEmpty) {
      onError("No verification id found. Request an OTP first.");
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      // Sign in; navigation is handled by AuthWrapper via authStateChanges()
      await _auth.signInWithCredential(credential);
    } catch (e) {
      developer.log('Failed during verifyOTP', error: e, name: 'LoginCore');
      onError("Incorrect OTP or expired code. Please try again.");
    }
  }
}
