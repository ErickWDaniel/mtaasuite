import 'package:firebase_database/firebase_database.dart';

class UserModel {
  final String uid;
  final String type; // citizen | ward
  final String phone;
  final String name;
  final String gender;
  final String dob;
  final String address;
  final String ward;
  final String street;
  final String houseNumber;
  final String region;
  final String district;
  final String? checkNumber;
  final String? profilePicUrl;
  final int createdAt;

  UserModel({
    required this.uid,
    required this.type,
    required this.phone,
    required this.name,
    required this.gender,
    required this.dob,
    required this.address,
    required this.ward,
    required this.street,
    required this.houseNumber,
    required this.region,
    required this.district,
    this.checkNumber,
    this.profilePicUrl,
    required this.createdAt,
  });

  /// JSON serialization (for local file checks)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      type: json['type'] ?? 'citizen',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      address: json['address'] ?? '',
      ward: json['ward'] ?? '',
      street: json['street'] ?? '',
      houseNumber: json['houseNumber'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      checkNumber: json['checkNumber'],
      profilePicUrl: json['profilePicUrl'],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'type': type,
      'phone': phone,
      'name': name,
      'gender': gender,
      'dob': dob,
      'address': address,
      'ward': ward,
      'street': street,
      'houseNumber': houseNumber,
      'region': region,
      'district': district,
      'checkNumber': checkNumber,
      'profilePicUrl': profilePicUrl,
      'createdAt': createdAt,
    };
  }

  /// Firebase snapshot parsing (for Realtime Database)
  factory UserModel.fromSnapshot(DataSnapshot snapshot) {
    final json = Map<String, dynamic>.from(snapshot.value as Map);
    return UserModel.fromJson(json);
  }

  /// Convert to Firebase Map (for saving)
  Map<String, dynamic> toMap() => toJson();
}
