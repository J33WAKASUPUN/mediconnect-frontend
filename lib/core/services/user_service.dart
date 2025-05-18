import 'package:mediconnect/core/services/api_service.dart';
import 'base_api_service.dart';
import 'auth_service.dart';

// Update UserService to ensure token is properly set
class UserService extends BaseApiService {
  final ApiService? _apiService;

  // Add constructor to accept ApiService
  UserService({ApiService? apiService}) : _apiService = apiService {
    // Get token from ApiService if provided
    if (apiService != null) {
      final token = apiService.getAuthToken();
      if (token.isNotEmpty) {
        setAuthToken(token);
        print('UserService initialized with token from ApiService');
      }
    }
  }

  // Get doctors available for a patient
  Future<List<Map<String, dynamic>>> getDoctorsForPatient(String patientId) async {
    try {
      // Ensure we have a valid token
      if (!hasValidToken() && _apiService != null) {
        final token = _apiService!.getAuthToken();
        if (token.isNotEmpty) {
          setAuthToken(token);
        }
      }
      
      if (!hasValidToken()) {
        print('UserService: No valid token for getDoctorsForPatient');
        return [];
      }

      final response = await get('/auth/users', queryParams: {
        'role': 'doctor',
        'patientId': patientId
      });
      
      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response['users'] != null) {
        return List<Map<String, dynamic>>.from(response['users']);
      }
      
      return [];
    } catch (e) {
      print('Error getting doctors for patient: $e');
      return [];
    }
  }
  
  // Get all doctors
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      // Ensure we have a valid token
      if (!hasValidToken() && _apiService != null) {
        final token = _apiService!.getAuthToken();
        if (token.isNotEmpty) {
          setAuthToken(token);
        }
      }
      
      if (!hasValidToken()) {
        print('UserService: No valid token for getAllDoctors');
        return [];
      }

      final response = await get('/auth/users', queryParams: {'role': 'doctor'});
      
      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response['users'] != null) {
        return List<Map<String, dynamic>>.from(response['users']);
      }
      
      return [];
    } catch (e) {
      print('Error getting all doctors: $e');
      return [];
    }
  }
  
  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      // Ensure we have a valid token
      if (!hasValidToken() && _apiService != null) {
        final token = _apiService!.getAuthToken();
        if (token.isNotEmpty) {
          setAuthToken(token);
        }
      }
      
      if (!hasValidToken()) {
        print('UserService: No valid token for getUserById');
        return null;
      }

      final response = await get('/auth/users', queryParams: {'id': userId});
      
      if (response['success'] == true && response['data'] != null && response['data'].isNotEmpty) {
        return response['data'][0];
      } else if (response['users'] != null && response['users'].isNotEmpty) {
        return response['users'][0];
      }
      
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
}
