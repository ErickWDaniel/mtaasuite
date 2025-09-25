import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordCore {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = "";

  Future<void> sendOTP(
    String phoneNumber,
    VoidCallback onCodeSent,
    Function(String) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification (Android) - sign-in and let AuthWrapper handle routing
          try {
            await _auth.signInWithCredential(credential);
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Verification failed");
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
      onError(e.toString());
    }
  }

  Future<void> verifyOTP(
    String smsCode,
    BuildContext context,
    Function(String) onError,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      // Sign in; AuthWrapper (MaterialApp.home) handles navigation by authStateChanges()
      await _auth.signInWithCredential(credential);
    } catch (e) {
      onError(e.toString());
    }
  }
}