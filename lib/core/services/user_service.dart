// lib/core/services/user_service.dart
import 'base_api_service.dart';
import 'auth_service.dart';

class UserService extends BaseApiService {
  // Get doctors available for a patient
  Future<List<Map<String, dynamic>>> getDoctorsForPatient(String patientId) async {
    try {
      final response = await get('/auth/users', queryParams: {
        'role': 'doctor',
        'patientId': patientId // This assumes your API can filter doctors by patientId
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