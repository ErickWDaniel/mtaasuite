import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';

void main() {
  group('UserModel', () {
    const testJson = {
      'uid': 'test-uid-123',
      'type': 'citizen',
      'phone': '+255123456789',
      'name': 'John Doe',
      'gender': 'male',
      'dob': '1990-01-01',
      'address': '123 Main St',
      'ward': 'Test Ward',
      'street': 'Test Street',
      'houseNumber': '123',
      'region': 'Dar es Salaam',
      'district': 'Kinondoni',
      'checkNumber': 'CHK123',
      'profilePicUrl': 'https://example.com/pic.jpg',
      'createdAt': 1640995200000, // 2022-01-01 00:00:00 UTC
    };

    test('fromJson creates UserModel with all fields', () {
      final user = UserModel.fromJson(testJson);

      expect(user.uid, 'test-uid-123');
      expect(user.type, 'citizen');
      expect(user.phone, '+255123456789');
      expect(user.name, 'John Doe');
      expect(user.gender, 'male');
      expect(user.dob, '1990-01-01');
      expect(user.address, '123 Main St');
      expect(user.ward, 'Test Ward');
      expect(user.street, 'Test Street');
      expect(user.houseNumber, '123');
      expect(user.region, 'Dar es Salaam');
      expect(user.district, 'Kinondoni');
      expect(user.checkNumber, 'CHK123');
      expect(user.profilePicUrl, 'https://example.com/pic.jpg');
      expect(user.createdAt, 1640995200000);
    });

    test('fromJson handles missing optional fields', () {
      final incompleteJson = {
        'uid': 'test-uid-123',
        'type': 'ward',
        'phone': '+255123456789',
        'name': 'Jane Doe',
        'gender': 'female',
        'dob': '1995-05-05',
        'address': '456 Elm St',
        'ward': 'Ward 2',
        'street': 'Elm Street',
        'houseNumber': '456',
        'region': 'Arusha',
        'district': 'Arusha District',
        // checkNumber and profilePicUrl are missing
        'createdAt': 1641081600000,
      };

      final user = UserModel.fromJson(incompleteJson);

      expect(user.checkNumber, null);
      expect(user.profilePicUrl, null);
    });

    test('fromJson provides defaults for missing required fields', () {
      final minimalJson = <String, dynamic>{};

      final user = UserModel.fromJson(minimalJson);

      expect(user.uid, '');
      expect(user.type, 'citizen');
      expect(user.phone, '');
      expect(user.name, '');
      expect(user.gender, '');
      expect(user.dob, '');
      expect(user.address, '');
      expect(user.ward, '');
      expect(user.street, '');
      expect(user.houseNumber, '');
      expect(user.region, '');
      expect(user.district, '');
      expect(user.createdAt, isNotNull); // Should use current timestamp
    });

    test('toJson converts UserModel back to map', () {
      final user = UserModel(
        uid: 'test-uid-123',
        type: 'citizen',
        phone: '+255123456789',
        name: 'John Doe',
        gender: 'male',
        dob: '1990-01-01',
        address: '123 Main St',
        ward: 'Test Ward',
        street: 'Test Street',
        houseNumber: '123',
        region: 'Dar es Salaam',
        district: 'Kinondoni',
        checkNumber: 'CHK123',
        profilePicUrl: 'https://example.com/pic.jpg',
        createdAt: 1640995200000,
      );

      final json = user.toJson();

      expect(json['uid'], 'test-uid-123');
      expect(json['type'], 'citizen');
      expect(json['phone'], '+255123456789');
      expect(json['name'], 'John Doe');
      expect(json['gender'], 'male');
      expect(json['dob'], '1990-01-01');
      expect(json['address'], '123 Main St');
      expect(json['ward'], 'Test Ward');
      expect(json['street'], 'Test Street');
      expect(json['houseNumber'], '123');
      expect(json['region'], 'Dar es Salaam');
      expect(json['district'], 'Kinondoni');
      expect(json['checkNumber'], 'CHK123');
      expect(json['profilePicUrl'], 'https://example.com/pic.jpg');
      expect(json['createdAt'], 1640995200000);
    });

    test('toMap is alias for toJson', () {
      final user = UserModel(
        uid: 'test-uid-123',
        type: 'ward',
        phone: '+255123456789',
        name: 'Jane Doe',
        gender: 'female',
        dob: '1995-05-05',
        address: '456 Elm St',
        ward: 'Ward 2',
        street: 'Elm Street',
        houseNumber: '456',
        region: 'Arusha',
        district: 'Arusha District',
        createdAt: 1641081600000,
      );

      expect(user.toMap(), equals(user.toJson()));
    });

    test('fromSnapshot creates UserModel from Firebase DataSnapshot', () {
      // Mock DataSnapshot
      final mockSnapshot = _MockDataSnapshot(testJson);

      final user = UserModel.fromSnapshot(mockSnapshot);

      expect(user.uid, 'test-uid-123');
      expect(user.type, 'citizen');
      expect(user.phone, '+255123456789');
      expect(user.name, 'John Doe');
    });

    test('UserModel handles null optional fields in toJson', () {
      final user = UserModel(
        uid: 'test-uid-123',
        type: 'citizen',
        phone: '+255123456789',
        name: 'John Doe',
        gender: 'male',
        dob: '1990-01-01',
        address: '123 Main St',
        ward: 'Test Ward',
        street: 'Test Street',
        houseNumber: '123',
        region: 'Dar es Salaam',
        district: 'Kinondoni',
        checkNumber: null,
        profilePicUrl: null,
        createdAt: 1640995200000,
      );

      final json = user.toJson();

      expect(json['checkNumber'], null);
      expect(json['profilePicUrl'], null);
    });
  });
}

// Mock DataSnapshot for testing
class _MockDataSnapshot implements DataSnapshot {
  final Map<dynamic, dynamic> _value;

  _MockDataSnapshot(this._value);

  @override
  dynamic get value => _value;

  @override
  bool get exists => true;

  @override
  String? get key => 'mock-key';

  @override
  DataSnapshot child(String path) => throw UnimplementedError();

  @override
  Iterable<DataSnapshot> get children => throw UnimplementedError();

  @override
  int get childrenCount => throw UnimplementedError();

  @override
  DatabaseReference get ref => throw UnimplementedError();

  @override
  DataSnapshot childAt(int index) => throw UnimplementedError();

  @override
  bool hasChild(String path) => throw UnimplementedError();

  @override
  bool hasChildren() => throw UnimplementedError();

  @override
  DataSnapshot? nextChild(String name) => throw UnimplementedError();

  @override
  DataSnapshot? previousChild(String name) => throw UnimplementedError();

  @override
  String get priority => throw UnimplementedError();
}