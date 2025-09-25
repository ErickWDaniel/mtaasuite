import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';
import 'package:mtaasuite/services/auth_storage.dart';

class PhoneRegisterCore {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');
  static const String autoSignInMarker = 'AUTO_SIGNED_IN';
  final Map<String, UserModel?> _pendingUsersByPhone = {};
  UserModel? _pendingUser; // fallback for single-flow usage

  PhoneRegisterCore() {
    developer.log('Firebase Realtime Database URL: ${FirebaseDatabase.instance.databaseURL}', name: 'PhoneRegisterCore');
  }

  // Lightweight normalization: trim and remove common separators so keys match reliably.
  String _normalizePhone(String phone) {
    var p = phone.trim();
    p = p.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return p;
  }

  /// Sends an SMS verification code to the given E.164 phone number, returning a verificationId.
  Future<String> sendPhoneVerification(String phone, {UserModel? pendingUser}) async {
    final completer = Completer<String>();
    final normalizedPhone = _normalizePhone(phone);

    try {
      developer.log('Starting phone verification for: $phone (normalized: $normalizedPhone)', name: 'PhoneRegisterCore');
      // Keep pending user so verificationCompleted can persist it if auto-signed-in
      _pendingUser = pendingUser;
      if (pendingUser != null) {
        // store by normalized phone so verificationCompleted can match by signed-in phone number
        _pendingUsersByPhone[normalizedPhone] = pendingUser;
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          developer.log('verificationCompleted called', name: 'PhoneRegisterCore');
          try {
            final userCred = await _auth.signInWithCredential(credential);
            developer.log('Auto sign-in successful', name: 'PhoneRegisterCore');
            final uid = userCred.user?.uid;
            if (uid != null) {
              // Try to match pending user by the signed-in phone (E.164). Fallback to transient _pendingUser.
              final signedInPhone = userCred.user?.phoneNumber;
              final normalizedSignedInPhone = signedInPhone != null ? _normalizePhone(signedInPhone) : null;
              UserModel? pending = normalizedSignedInPhone != null ? _pendingUsersByPhone[normalizedSignedInPhone] : null;
              pending ??= _pendingUser;
              if (pending != null) {
                try {
                  final snap = await _dbRef.child(uid).get();
                  if (!snap.exists) {
                    // Build user from pending data and persist with retry
                    final user = UserModel(
                      uid: uid,
                      type: pending.type,
                      phone: pending.phone,
                      name: pending.name,
                      gender: pending.gender,
                      dob: pending.dob,
                      address: pending.address,
                      region: pending.region,
                      district: pending.district,
                      ward: pending.ward,
                      street: pending.street,
                      houseNumber: pending.houseNumber,
                      checkNumber: pending.checkNumber,
                      profilePicUrl: pending.profilePicUrl,
                      createdAt: pending.createdAt,
                    );
                    await _writeUserWithRetry(uid, user.toJson());
                    developer.log('Auto-saved user to Realtime Database: $uid', name: 'PhoneRegisterCore');
                    // Persist locally so UI can pick it up after auto sign-in
                    try {
                      await AuthStorage.saveUser(user);
                    } catch (e) {
                      developer.log('Failed to save user locally', error: e, name: 'PhoneRegisterCore');
                    }
                  } else {
                    developer.log('User already exists in Realtime Database: $uid', name: 'PhoneRegisterCore');
                  }
                } catch (e) {
                  developer.log('Failed to auto-save user to DB', error: e, name: 'PhoneRegisterCore');
                } finally {
                  if (normalizedSignedInPhone != null) {
                    _pendingUsersByPhone.remove(normalizedSignedInPhone);
                  } else {
                    // fallback remove by the originally requested phone
                    _pendingUsersByPhone.remove(normalizedPhone);
                  }
                  _pendingUser = null;
                }
              }
              // If the caller is awaiting a verificationId, notify them that an auto sign-in occurred.
              if (!completer.isCompleted) {
                completer.complete(autoSignInMarker);
              }
            }
          } catch (e) {
            developer.log('Auto sign-in failed', error: e, name: 'PhoneRegisterCore');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
           developer.log('verificationFailed: ${e.message}', name: 'PhoneRegisterCore', error: e);
           developer.log('Error code: ${e.code}', name: 'PhoneRegisterCore');
          // clean up pending entries for this phone
          _pendingUsersByPhone.remove(normalizedPhone);
          _pendingUser = null;
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log('codeSent; verificationId: $verificationId', name: 'PhoneRegisterCore');
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer.log('codeAutoRetrievalTimeout; verificationId: $verificationId', name: 'PhoneRegisterCore');
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );
    } catch (e) {
      developer.log('Failed to start phone verification', error: e, name: 'PhoneRegisterCore');
      // clean up pending entries for this phone
      _pendingUsersByPhone.remove(normalizedPhone);
      _pendingUser = null;
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  /// Write user to Realtime Database with simple exponential backoff retry.
  Future<void> _writeUserWithRetry(String uid, Map<String, dynamic> userJson, {int maxRetries = 3}) async {
    int attempt = 0;
    int delayMs = 500;
    while (true) {
      try {
        await _dbRef.child(uid).set(userJson);
        developer.log('Saved user to Realtime Database: $uid', name: 'PhoneRegisterCore');
        return;
      } catch (e) {
        attempt++;
        developer.log('Failed to write user (attempt $attempt): $e', error: e, name: 'PhoneRegisterCore');
        if (attempt >= maxRetries) {
          throw Exception('Failed to save user to Realtime Database after $attempt attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2; // exponential backoff
      }
    }
  }

  /// Verifies the SMS code and persists the user with the real Firebase UID.
  Future<UserModel> verifyAndRegister({
    required String verificationId,
    required String smsCode,
    required UserModel tempUser,
  }) async {
    try {
      developer.log('verifyAndRegister called', name: 'PhoneRegisterCore');
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final uid = userCred.user?.uid;
      if (uid == null) {
        developer.log('No UID after signInWithCredential', name: 'PhoneRegisterCore');
        throw Exception('Authentication succeeded but no UID was returned.');
      }

      final user = UserModel(
        uid: uid,
        type: tempUser.type,
        phone: tempUser.phone,
        name: tempUser.name,
        gender: tempUser.gender,
        dob: tempUser.dob,
        address: tempUser.address,
        region: tempUser.region,
        district: tempUser.district,
        ward: tempUser.ward,
        street: tempUser.street,
        houseNumber: tempUser.houseNumber,
        checkNumber: tempUser.checkNumber,
        profilePicUrl: tempUser.profilePicUrl,
        createdAt: tempUser.createdAt,
      );

      // Persist user data in Realtime Database with retry
      await _writeUserWithRetry(uid, user.toJson());
      developer.log('Saved user to Realtime Database: $uid', name: 'PhoneRegisterCore');

      // Persist locally so UI can pick it up after registration
      try {
        await AuthStorage.saveUser(user);
      } catch (e) {
        developer.log('Failed to save user locally in verifyAndRegister', error: e, name: 'PhoneRegisterCore');
      }

      // Clean up any pending entries for this temporary user
      _pendingUsersByPhone.removeWhere((_, v) => v == tempUser);
      _pendingUser = null;

      return user;
    } on FirebaseAuthException catch (e) {
      developer.log('FirebaseAuthException in verifyAndRegister', error: e, name: 'PhoneRegisterCore');
      rethrow;
    } on FirebaseException catch (e) {
      developer.log('FirebaseDatabaseException in verifyAndRegister', error: e, name: 'PhoneRegisterCore');
      rethrow;
    } catch (e) {
      developer.log('Unexpected error in verifyAndRegister', error: e, name: 'PhoneRegisterCore');
      rethrow;
    }
  }
}
