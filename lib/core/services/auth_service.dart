import 'dart:convert';

import 'base_api_service.dart';

class AuthService extends BaseApiService {
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  @override
  void setAuthToken(String token) {
    super.setAuthToken(token);
    try {
      // Simple JWT parser (only works for standard JWT tokens)
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> data = json.decode(decoded);

        if (data.containsKey('id')) {
          _currentUserId = data['id'];
          print('Extracted user ID from token: $_currentUserId');
        }
      }
    } catch (e) {
      print('Failed to extract user ID from token: $e');
      _currentUserId = null;
    }
    // Will be set later when user profile is loaded
  }

  // Method to set user ID explicitly
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Verify API Connection
  Future<bool> verifyApiConnection() async {
    try {
      final response = await get(
        '/auth/users',
      );
      print('API Connection Test Response: $response');
      return true;
    } catch (e) {
      print('API Connection Test Error: $e');
      return false;
    }
  }

  void refreshToken(String token) {
    print('Refreshing auth token: ${token.substring(0, 10)}...');
    setAuthToken(token);
  }
}
