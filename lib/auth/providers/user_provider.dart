import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';
import 'package:mtaasuite/services/auth_storage.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null) {
    // Load persisted user on creation (non-blocking)
    loadFromStorage();
  }

  Future<void> setUser(UserModel user) async {
    state = user;
    await AuthStorage.saveUser(user);
  }

  Future<void> clearUser() async {
    state = null;
    await AuthStorage.clearUser();
  }

  Future<void> loadFromStorage() async {
    final stored = await AuthStorage.loadUser();
    if (stored != null) {
      state = stored;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});