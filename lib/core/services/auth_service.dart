import 'base_api_service.dart';

class AuthService extends BaseApiService {
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
