import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';

class RegisterCore {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');

  /// Register a new user
  Future<UserModel> registerUser({
    required String phone,
    required String password,
    required String type, // citizen | ward
    required String name,
    required String gender,
    required String dob,
    required String address,
    required String region,
    required String district,
    required String ward,
    required String street,
    required String houseNumber,
    String? checkNumber,
    String? profilePicUrl,
  }) async {
    // 1️⃣ Create Firebase Auth user
    UserCredential userCred = await _auth.createUserWithEmailAndPassword(
      email: '$phone@mtaasuite.app', // Using phone as pseudo-email
      password: password,
    );

    String uid = userCred.user!.uid;
    int createdAt = DateTime.now().millisecondsSinceEpoch;

    // 2️⃣ Build UserModel
    UserModel user = UserModel(
      uid: uid,
      type: type,
      phone: phone,
      name: name,
      gender: gender,
      dob: dob,
      address: address,
      region: region,
      district: district,
      ward: ward,
      street: street,
      houseNumber: houseNumber,
      checkNumber: checkNumber,
      profilePicUrl: profilePicUrl,
      createdAt: createdAt,
    );

    // 3️⃣ Save to Firebase Realtime Database
    await _dbRef.child(user.uid).set(user.toJson());
    print('Saved user: ${user.uid}'); // Debug print the saved user's uid

    return user;
  }

  /// Fetch user by UID
  Future<UserModel?> fetchUser(String uid) async {
    final snapshot = await _dbRef.child(uid).get();
    if (!snapshot.exists) return null;
    return UserModel.fromJson(snapshot.value as Map<String, dynamic>);
  }

  /// Update existing user
  Future<void> updateUser(UserModel user) async {
    await _dbRef.child(user.uid).update(user.toJson());
  }
}
