import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'phone_validator.dart';

class FirebaseAuthHelper {
  static Future<void> signInWithTzPhone({
    required String rawPhone,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException error) onError,
    required Function(UserCredential credential) onSuccess,
    int? timeoutSeconds,
  }) async {
    final phone = TzPhone.normalizeTzMsisdn(rawPhone);
    if (phone == null) {
      onError(
        FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Invalid Tanzanian mobile number.',
        ),
      );
      return;
    }
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: Duration(seconds: timeoutSeconds ?? 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCred = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        onSuccess(userCred);
      },
      verificationFailed: onError,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  static Future<UserCredential> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// Ensures all required user fields are present before saving to DB.
  static Map<String, dynamic> completeUserData(Map<String, dynamic> userData) {
    return {
      'uid': userData['uid'] ?? '',
      'name': userData['name'] ?? '',
      'phone': userData['phone'] ?? '',
      'address': userData['address'] ?? '',
      'region': userData['region'] ?? '',
      'district': userData['district'] ?? '',
      'ward': userData['ward'] ?? '',
      'street': userData['street'] ?? '',
      'houseNumber': userData['houseNumber'] ?? '',
      'dob': userData['dob'] ?? '',
      'gender': userData['gender'] ?? '',
      'type': userData['type'] ?? 'citizen',
      'createdAt':
          userData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Save user data to Firebase Realtime Database under /users/{uid}
  static Future<void> saveUserToDb(Map<String, dynamic> userData) async {
    final completeData = completeUserData(userData);
    final uid = completeData['uid'];
    if (uid == null || uid.isEmpty) throw Exception('Missing UID');
    await FirebaseDatabase.instance.ref('users/$uid').set(completeData);
  }
}
