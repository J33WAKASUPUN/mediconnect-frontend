import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../models/user_model.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Save JWT token
  Future<void> saveToken(String token) async {
    await _prefs.setString(AppConfig.tokenKey, token);
  }

  // Get JWT token
  String? getToken() {
    return _prefs.getString(AppConfig.tokenKey);
  }

  // Save user data
  Future<void> saveUser(User user) async {
    await _prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  // Get user data
  User? getUser() {
    final userStr = _prefs.getString(AppConfig.userKey);
    if (userStr != null) {
      return User.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  // Clear all stored data (logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}