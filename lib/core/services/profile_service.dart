import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mediconnect/config/api_endpoints.dart';
import 'package:path/path.dart' as path;
import 'base_api_service.dart';
import '../utils/datetime_helper.dart';

class ProfileService extends BaseApiService {
  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await get('/profile');
      print("Raw API response: $response");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update basic profile (with optional profile picture)
  Future<Map<String, dynamic>> updateBasicProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    File? profilePicture,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'address': address,
        if (profilePicture != null)
          'profilePicture': await MultipartFile.fromFile(
            profilePicture.path,
            filename:
                'profile_${DateTimeHelper.getCurrentUTC().replaceAll(RegExp(r'[: ]'), '-')}${path.extension(profilePicture.path)}',
            contentType: MediaType(
              'image',
              path.extension(profilePicture.path).replaceAll('.', ''),
            ),
          ),
      });

      final response = await put(
        '/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update patient profile
  Future<Map<String, dynamic>> updatePatientProfile({
    String? bloodType,
    List<String>? medicalHistory,
    List<String>? allergies,
    List<String>? currentMedications,
    List<String>? chronicConditions,
    List<Map<String, dynamic>>? emergencyContacts,
    Map<String, dynamic>? insuranceInfo,
  }) async {
    try {
      final data = {
        if (bloodType != null) 'bloodType': bloodType,
        if (medicalHistory != null) 'medicalHistory': medicalHistory,
        if (allergies != null) 'allergies': allergies,
        if (currentMedications != null)
          'currentMedications': currentMedications,
        if (chronicConditions != null) 'chronicConditions': chronicConditions,
        if (emergencyContacts != null) 'emergencyContacts': emergencyContacts,
        if (insuranceInfo != null) 'insuranceInfo': insuranceInfo,
      };

      final response = await put('/profile/patient', data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update doctor profile
  Future<Map<String, dynamic>> updateDoctorProfile({
    String? specialization,
    String? licenseNumber,
    int? yearsOfExperience,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? hospitalAffiliations,
    List<Map<String, dynamic>>? availableTimeSlots,
    double? consultationFees,
    List<String>? expertise,
  }) async {
    try {
      final data = {
        if (specialization != null) 'specialization': specialization,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
        if (education != null) 'education': education,
        if (hospitalAffiliations != null)
          'hospitalAffiliations': hospitalAffiliations,
        if (availableTimeSlots != null)
          'availableTimeSlots': availableTimeSlots,
        if (consultationFees != null) 'consultationFees': consultationFees,
        if (expertise != null) 'expertise': expertise,
      };

      final response = await put('/profile/doctor', data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Register with profile picture
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String gender,
    required String address,
    File? profilePicture,
  }) async {
    try {
      // Generate username based on firstName
      final username =
          firstName.toUpperCase().padRight(12, '0').substring(0, 12);

      // Validate image if provided
      if (profilePicture != null) {
        final extension = path.extension(profilePicture.path).toLowerCase();
        if (!['.jpg', '.jpeg', '.png'].contains(extension)) {
          throw Exception('Only .png, .jpg and .jpeg format allowed!');
        }
      }

      FormData formData = FormData.fromMap({
        'email': email,
        'password': password,
        'role': role,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'address': address,
        if (profilePicture != null)
          'profilePicture': await MultipartFile.fromFile(
            profilePicture.path,
            filename:
                '${username}_${DateTimeHelper.getCurrentUTC().replaceAll(RegExp(r'[: ]'), '-')}${path.extension(profilePicture.path)}',
            contentType: MediaType(
              'image',
              path.extension(profilePicture.path).replaceAll('.', ''),
            ),
          ),
      });

      final response = await post(
        '/auth/register',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get profile by ID
  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final response = await get('/auth/users', queryParams: {'id': userId});

      if (response['success'] == true &&
          response['data'] != null &&
          response['data'].isNotEmpty) {
        return {'success': true, 'data': response['data'][0]};
      }

      throw Exception('User not found');
    } catch (e) {
      print('Error in getProfileById: $e');
      return null;
    }
  }

  // Get all doctors
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      print(
          'Fetching doctors with token: ${currentToken?.substring(0, 10)}...');

      final response = await get(
        ApiEndpoints.doctors, // Use consistent endpoint path
        queryParams: {'role': 'doctor'},
      );

      print('Raw API Response: $response');

      if (response is Map) {
        if (response['users'] is List) {
          return List<Map<String, dynamic>>.from(response['users']);
        } else if (response['data'] is List) {
          return List<Map<String, dynamic>>.from(response['data']);
        }
      } else if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }

      print('Unexpected response format: $response');
      return [];
    } catch (e) {
      print('Error in getAllDoctors: $e');
      throw 'Error loading doctors: $e';
    }
  }
}
