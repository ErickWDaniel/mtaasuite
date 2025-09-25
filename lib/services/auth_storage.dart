import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';

class AuthStorage {
  static const _userKey = 'mtaasuite_user_json';

  /// Save the user as JSON to SharedPreferences.
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(user.toJson());
    await prefs.setString(_userKey, jsonStr);
  }

  /// Load the user from SharedPreferences. Returns null if not found or parse fails.
  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final Map<String, dynamic> map = json.decode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clear the persisted user.
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Save temporary user data with a specific key (e.g., for pending registration)
  static Future<void> saveUserData(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(data);
    await prefs.setString('mtaasuite_$key', jsonStr);
  }

  /// Get temporary user data by key
  static Future<Map<String, dynamic>?> getUserData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('mtaasuite_$key');
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear temporary user data by key
  static Future<void> clearUserData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mtaasuite_$key');
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('mtaasuite_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}