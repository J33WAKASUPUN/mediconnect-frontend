import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../config/api_endpoints.dart';
import '../utils/datetime_helper.dart';

class ApiService {
  late Dio _dio;
  // ignore: unused_field
  String? _authToken;

  ApiService() {
    print('Initializing ApiService with base URL: ${ApiEndpoints.baseUrl}');
    
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) {
        return status != null && status < 500;
      },
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
    ));

    print('ApiService initialized');
  }

  void setAuthToken(String token) {
    print('Setting auth token: ${token.substring(0, 10)}...');
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw 'No authentication token available';
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }

  // API Connection verification
  Future<bool> verifyApiConnection() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl('/auth/users'),
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      print('API Connection Test Response: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('API Connection Test Error: $e');
      return false;
    }
  }

  // Get all doctors
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      print('Fetching doctors with token: ${_authToken?.substring(0, 10)}...');
      
      final response = await _dio.get(
        ApiEndpoints.getFullUrl(ApiEndpoints.doctors),
        queryParameters: {
          'role': 'doctor',
        },
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      print('Raw API Response: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['users'] is List) {
          return List<Map<String, dynamic>>.from(response.data['users']);
        } else if (response.data is Map && response.data['data'] is List) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        } else if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
        print('Unexpected response format: ${response.data}');
        return [];
      } else {
        throw 'Failed to load doctors: ${response.statusCode}';
      }
    } on DioException catch (e) {
      print('DioException in getAllDoctors: ${e.message}');
      print('DioException response: ${e.response?.data}');
      
      if (e.response?.data is Map) {
        final errorMessage = e.response?.data['message'] ?? 'Failed to load doctors';
        throw errorMessage;
      }
      
      throw _handleDioError(e);
    } catch (e) {
      print('Error in getAllDoctors: $e');
      throw 'Error loading doctors: $e';
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
      final username = firstName.toUpperCase().padRight(12, '0').substring(0, 12);

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
            filename: '${username}_${DateTimeHelper.getCurrentUTC().replaceAll(RegExp(r'[: ]'), '-')}${path.extension(profilePicture.path)}',
            contentType: MediaType(
              'image',
              path.extension(profilePicture.path).replaceAll('.', ''),
            ),
          ),
      });

      final response = await _dio.post(
        ApiEndpoints.register,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Handle Dio Errors
  dynamic _handleDioError(DioException e) {
    print('Handling DioError: ${e.message}');
    print('Response: ${e.response?.data}');
    
    if (e.response != null) {
      if (e.response?.data is Map) {
        final message = e.response?.data['message'] ?? 'An error occurred';
        return Exception(message);
      }
      return Exception(e.response?.data?.toString() ?? 'An error occurred');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Server not responding');
    } else {
      return Exception('Network error occurred');
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      print("Raw API response: ${response.data}");
      return response.data;
    } on DioException catch (e) {
      print("API error: $e");
      throw _handleDioError(e);
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
            filename: 'profile_${DateTimeHelper.getCurrentUTC().replaceAll(RegExp(r'[: ]'), '-')}${path.extension(profilePicture.path)}',
            contentType: MediaType(
              'image',
              path.extension(profilePicture.path).replaceAll('.', ''),
            ),
          ),
      });

      final response = await _dio.put(
        '/profile',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
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
        if (currentMedications != null) 'currentMedications': currentMedications,
        if (chronicConditions != null) 'chronicConditions': chronicConditions,
        if (emergencyContacts != null) 'emergencyContacts': emergencyContacts,
        if (insuranceInfo != null) 'insuranceInfo': insuranceInfo,
      };

      final response = await _dio.put(
        '/profile/patient',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
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
        if (availableTimeSlots != null) 'availableTimeSlots': availableTimeSlots,
        if (consultationFees != null) 'consultationFees': consultationFees,
        if (expertise != null) 'expertise': expertise,
      };

      final response = await _dio.put(
        '/profile/doctor',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}

