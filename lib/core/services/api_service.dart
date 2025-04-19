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
        final errorMessage =
            e.response?.data['message'] ?? 'Failed to load doctors';
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
            filename:
                'profile_${DateTimeHelper.getCurrentUTC().replaceAll(RegExp(r'[: ]'), '-')}${path.extension(profilePicture.path)}',
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
        if (currentMedications != null)
          'currentMedications': currentMedications,
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
        if (availableTimeSlots != null)
          'availableTimeSlots': availableTimeSlots,
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

// Get all appointments for the logged-in user (patient or doctor)
  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl(ApiEndpoints.appointmentsByUser),
      );
      if (response.data['success'] && response.data['appointments'] is List) {
        return List<Map<String, dynamic>>.from(response.data['appointments']);
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

// Doctor-specific appointments
  Future<List<Map<String, dynamic>>> getDoctorAppointments() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl(ApiEndpoints.appointmentsByDoctor),
      );
      if (response.data['success'] && response.data['appointments'] is List) {
        return List<Map<String, dynamic>>.from(response.data['appointments']);
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

// Create a new appointment
  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required String appointmentDate,
    required String timeSlot,
    required String reason,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getFullUrl(ApiEndpoints.appointments),
        data: {
          'doctorId': doctorId,
          'appointmentDate': appointmentDate,
          'timeSlot': timeSlot,
          'reason': reason,
          'amount': amount,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Update appointment status
  Future<Map<String, dynamic>> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.getFullUrl(
            '${ApiEndpoints.appointments}/$appointmentId/status'),
        data: {'status': status},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Add review to appointment
  Future<Map<String, dynamic>> addAppointmentReview(
      String appointmentId, int rating, String comment) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getFullUrl(
            '${ApiEndpoints.appointments}/$appointmentId/review'),
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Create medical record for an appointment
  Future<Map<String, dynamic>> createMedicalRecord(
      String appointmentId, Map<String, dynamic> medicalData) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getFullUrl(
            '${ApiEndpoints.appointments}/$appointmentId/medical-record'),
        data: medicalData,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Get doctor availability slots
  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl(
            '${ApiEndpoints.doctors}/$doctorId/availability'),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Update doctor availability
  Future<Map<String, dynamic>> updateDoctorAvailability(
      String doctorId, List<Map<String, dynamic>> availability) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.getFullUrl(
            '${ApiEndpoints.doctors}/$doctorId/availability'),
        data: {'availability': availability},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Create a payment
  Future<Map<String, dynamic>> createPayment({
    required String appointmentId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getFullUrl(ApiEndpoints.payments),
        data: {
          'appointmentId': appointmentId,
          'paymentMethod': paymentMethod,
          'amount': amount,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Verify a payment
  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String transactionId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getFullUrl(ApiEndpoints.paymentVerify),
        data: {
          'paymentId': paymentId,
          'transactionId': transactionId,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Get payment by appointment ID
  Future<Map<String, dynamic>> getPaymentForAppointment(
      String appointmentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl(
            '${ApiEndpoints.payments}/appointment/$appointmentId'),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Get all payments for a user (patient or doctor)
  Future<List<Map<String, dynamic>>> getUserPayments() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl('${ApiEndpoints.payments}/user'),
      );
      if (response.data['success'] && response.data['payments'] is List) {
        return List<Map<String, dynamic>>.from(response.data['payments']);
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get all medical records for a patient
  Future<List<Map<String, dynamic>>> getPatientMedicalRecords() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl(ApiEndpoints.patientMedicalRecords),
      );
      if (response.data['success'] && response.data['records'] is List) {
        return List<Map<String, dynamic>>.from(response.data['records']);
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

// Create a new medical record
  Future<Map<String, dynamic>> createMedicalRecord({
    required String appointmentId,
    required String diagnosis,
    required String symptoms,
    required String treatment,
    required String prescription,
    required List<String> tests,
    required String notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getFullUrl(ApiEndpoints.medicalRecords),
        data: {
          'appointmentId': appointmentId,
          'diagnosis': diagnosis,
          'symptoms': symptoms,
          'treatment': treatment,
          'prescription': prescription,
          'tests': tests,
          'notes': notes,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Get a single medical record
  Future<Map<String, dynamic>> getMedicalRecord(String recordId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl('${ApiEndpoints.medicalRecords}/$recordId'),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Get the PDF of a medical record
  Future<String?> getMedicalRecordPdf(String recordId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl('${ApiEndpoints.medicalRecords}/$recordId/pdf'),
      );
      if (response.data['success'] && response.data['pdfUrl'] != null) {
        return response.data['pdfUrl'];
      }
      return null;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get all notifications for the logged-in user
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getFullUrl(ApiEndpoints.notifications),
      );
      if (response.data['success'] && response.data['notifications'] is List) {
        return List<Map<String, dynamic>>.from(response.data['notifications']);
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

// Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.getFullUrl(
            '${ApiEndpoints.notifications}/$notificationId/read'),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

// Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.getFullUrl('${ApiEndpoints.notifications}/read-all'),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
