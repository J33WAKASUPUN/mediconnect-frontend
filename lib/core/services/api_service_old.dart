// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart' as path;
// import 'package:dio/dio.dart';
// import 'package:http_parser/http_parser.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';
// import '../../config/api_endpoints.dart';
// import '../utils/datetime_helper.dart';

// class ApiService {
//   late Dio _dio;
//   // ignore: unused_field
//   String? _authToken;

//   ApiService() {
//     print('Initializing ApiService with base URL: ${ApiEndpoints.baseUrl}');

//     _dio = Dio(BaseOptions(
//       baseUrl: ApiEndpoints.baseUrl,
//       responseType: ResponseType.json,
//       connectTimeout: const Duration(seconds: 30),
//       receiveTimeout: const Duration(seconds: 30),
//       validateStatus: (status) {
//         return status != null && status < 500;
//       },
//       headers: {
//         'Accept': 'application/json',
//       },
//     ));

//     _dio.interceptors.add(PrettyDioLogger(
//       requestHeader: true,
//       requestBody: true,
//       responseHeader: true,
//       responseBody: true,
//       error: true,
//       compact: true,
//       maxWidth: 90,
//     ));

//     print('ApiService initialized');
//   }

//   void setAuthToken(String token) {
//     print('Setting auth token: ${token.substring(0, 10)}...');
//     _authToken = token;
//     _dio.options.headers['Authorization'] = 'Bearer $token';
//   }

//   String getReceiptViewerUrl(String paymentId) {
//     // Get the current token
//     final token = _authToken ?? '';

//     // Use the base URL of your web app
//     final appUrl = Uri.base.origin;

//     // For debugging
//     print('Creating receipt URL with token length: ${token.length}');

//     // Encode the token for URL safety
//     final encodedToken = Uri.encodeComponent(token);

//     // Return the URL to the PDF viewer bridge with token and paymentId
//     return '$appUrl/pdf_viewer.html?token=$encodedToken&id=$paymentId';
//   }

//   String getReceiptPdfUrl(String paymentId) {
//     // Get the base URL - adjust this to your actual backend URL in production
//     // For development, you might need to hardcode this to your backend URL
//     final baseUrl = 'http://localhost:3000'; // Change to your backend URL

//     // Get the auth token
//     final token = Uri.encodeComponent(_authToken ?? '');

//     // Return the URL to the PDF with token
//     return '$baseUrl/api/payments/$paymentId/receipt-with-token?token=$token';
//   }

//   String getAuthToken() {
//     // Get the token from your storage mechanism
//     final token = _authToken;

//     // Check if the token exists and is not expired
//     if (token == null || token.isEmpty) {
//       print('Warning: Auth token is missing or empty');
//       return '';
//     }

//     // Return the token
//     return token;
//   }

//   Future<Map<String, String>> _getAuthHeaders() async {
//     if (_authToken == null || _authToken!.isEmpty) {
//       throw 'No authentication token available';
//     }
//     return {
//       'Accept': 'application/json',
//       'Authorization': 'Bearer $_authToken',
//     };
//   }

//   // API Connection verification
//   Future<bool> verifyApiConnection() async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl('/auth/users'),
//         options: Options(
//           headers: await _getAuthHeaders(),
//         ),
//       );
//       print('API Connection Test Response: ${response.data}');
//       return response.statusCode == 200;
//     } catch (e) {
//       print('API Connection Test Error: $e');
//       return false;
//     }
//   }

//   // Get all doctors
//   Future<List<Map<String, dynamic>>> getAllDoctors() async {
//     try {
//       print('Fetching doctors with token: ${_authToken?.substring(0, 10)}...');

//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl(ApiEndpoints.doctors),
//         queryParameters: {
//           'role': 'doctor',
//         },
//         options: Options(
//           headers: await _getAuthHeaders(),
//         ),
//       );

//       print('Raw API Response: ${response.data}');

//       if (response.statusCode == 200) {
//         if (response.data is Map && response.data['users'] is List) {
//           return List<Map<String, dynamic>>.from(response.data['users']);
//         } else if (response.data is Map && response.data['data'] is List) {
//           return List<Map<String, dynamic>>.from(response.data['data']);
//         } else if (response.data is List) {
//           return List<Map<String, dynamic>>.from(response.data);
//         }
//         print('Unexpected response format: ${response.data}');
//         return [];
//       } else {
//         throw 'Failed to load doctors: ${response.statusCode}';
//       }
//     } on DioException catch (e) {
//       print('DioException in getAllDoctors: ${e.message}');
//       print('DioException response: ${e.response?.data}');

//       if (e.response?.data is Map) {
//         final errorMessage =
//             e.response?.data['message'] ?? 'Failed to load doctors';
//         throw errorMessage;
//       }

//       throw _handleDioError(e);
//     } catch (e) {
//       print('Error in getAllDoctors: $e');
//       throw 'Error loading doctors: $e';
//     }
//   }

//   // Register with profile picture
//   Future<Map<String, dynamic>> register({
//     required String email,
//     required String password,
//     required String role,
//     required String firstName,
//     required String lastName,
//     required String phoneNumber,
//     required String gender,
//     required String address,
//     File? profilePicture,
//   }) async {
//     try {
//       // Generate username based on firstName
//       final username =
//           firstName.toUpperCase().padRight(12, '0').substring(0, 12);

//       // Validate image if provided
//       if (profilePicture != null) {
//         final extension = path.extension(profilePicture.path).toLowerCase();
//         if (!['.jpg', '.jpeg', '.png'].contains(extension)) {
//           throw Exception('Only .png, .jpg and .jpeg format allowed!');
//         }
//       }

//       FormData formData = FormData.fromMap({
//         'email': email,
//         'password': password,
//         'role': role,
//         'username': username,
//         'firstName': firstName,
//         'lastName': lastName,
//         'phoneNumber': phoneNumber,
//         'gender': gender,
//         'address': address,
//         if (profilePicture != null)
//           'profilePicture': await MultipartFile.fromFile(
//             profilePicture.path,
//             filename:
//                 '${username}_${DateTimeHelper.getCurrentUTC().replaceAll(RegExp(r'[: ]'), '-')}${path.extension(profilePicture.path)}',
//             contentType: MediaType(
//               'image',
//               path.extension(profilePicture.path).replaceAll('.', ''),
//             ),
//           ),
//       });

//       final response = await _dio.post(
//         ApiEndpoints.register,
//         data: formData,
//         options: Options(
//           contentType: 'multipart/form-data',
//           headers: {
//             'Accept': 'application/json',
//           },
//         ),
//       );
//       return response.data;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // Handle Dio Errors
//   dynamic _handleDioError(DioException e) {
//     print('Handling DioError: ${e.message}');
//     print('Response: ${e.response?.data}');

//     if (e.response != null) {
//       if (e.response?.data is Map) {
//         final message = e.response?.data['message'] ?? 'An error occurred';
//         return Exception(message);
//       }
//       return Exception(e.response?.data?.toString() ?? 'An error occurred');
//     } else if (e.type == DioExceptionType.connectionTimeout) {
//       return Exception('Connection timeout');
//     } else if (e.type == DioExceptionType.receiveTimeout) {
//       return Exception('Server not responding');
//     } else {
//       return Exception('Network error occurred');
//     }
//   }

//   dynamic _handleError(dynamic e) {
//     if (e is DioException) {
//       return _handleDioError(e);
//     } else {
//       print('General API Error: $e');
//       return Exception('Error: $e');
//     }
//   }

//   // Login
//   Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//     required String role,
//   }) async {
//     try {
//       final response = await _dio.post(
//         ApiEndpoints.login,
//         data: {
//           'email': email,
//           'password': password,
//           'role': role,
//         },
//       );
//       return response.data;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // Get user profile
//   Future<Map<String, dynamic>> getProfile() async {
//     try {
//       final response = await _dio.get('/profile');
//       print("Raw API response: ${response.data}");
//       return response.data;
//     } on DioException catch (e) {
//       print("API error: $e");
//       throw _handleDioError(e);
//     }
//   }

//   // Update basic profile (with optional profile picture)
//   Future<Map<String, dynamic>> updateBasicProfile({
//     required String firstName,
//     required String lastName,
//     required String phoneNumber,
//     required String address,
//     File? profilePicture,
//   }) async {
//     try {
//       FormData formData = FormData.fromMap({
//         'firstName': firstName,
//         'lastName': lastName,
//         'phoneNumber': phoneNumber,
//         'address': address,
//         if (profilePicture != null)
//           'profilePicture': await MultipartFile.fromFile(
//             profilePicture.path,
//             filename:
//                 'profile_${DateTimeHelper.getCurrentUTC().replaceAll(RegExp(r'[: ]'), '-')}${path.extension(profilePicture.path)}',
//             contentType: MediaType(
//               'image',
//               path.extension(profilePicture.path).replaceAll('.', ''),
//             ),
//           ),
//       });

//       final response = await _dio.put(
//         '/profile',
//         data: formData,
//         options: Options(
//           contentType: 'multipart/form-data',
//         ),
//       );
//       return response.data;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // Update patient profile
//   Future<Map<String, dynamic>> updatePatientProfile({
//     String? bloodType,
//     List<String>? medicalHistory,
//     List<String>? allergies,
//     List<String>? currentMedications,
//     List<String>? chronicConditions,
//     List<Map<String, dynamic>>? emergencyContacts,
//     Map<String, dynamic>? insuranceInfo,
//   }) async {
//     try {
//       final data = {
//         if (bloodType != null) 'bloodType': bloodType,
//         if (medicalHistory != null) 'medicalHistory': medicalHistory,
//         if (allergies != null) 'allergies': allergies,
//         if (currentMedications != null)
//           'currentMedications': currentMedications,
//         if (chronicConditions != null) 'chronicConditions': chronicConditions,
//         if (emergencyContacts != null) 'emergencyContacts': emergencyContacts,
//         if (insuranceInfo != null) 'insuranceInfo': insuranceInfo,
//       };

//       final response = await _dio.put(
//         '/profile/patient',
//         data: data,
//       );
//       return response.data;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // Update doctor profile
//   Future<Map<String, dynamic>> updateDoctorProfile({
//     String? specialization,
//     String? licenseNumber,
//     int? yearsOfExperience,
//     List<Map<String, dynamic>>? education,
//     List<Map<String, dynamic>>? hospitalAffiliations,
//     List<Map<String, dynamic>>? availableTimeSlots,
//     double? consultationFees,
//     List<String>? expertise,
//   }) async {
//     try {
//       final data = {
//         if (specialization != null) 'specialization': specialization,
//         if (licenseNumber != null) 'licenseNumber': licenseNumber,
//         if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
//         if (education != null) 'education': education,
//         if (hospitalAffiliations != null)
//           'hospitalAffiliations': hospitalAffiliations,
//         if (availableTimeSlots != null)
//           'availableTimeSlots': availableTimeSlots,
//         if (consultationFees != null) 'consultationFees': consultationFees,
//         if (expertise != null) 'expertise': expertise,
//       };

//       final response = await _dio.put(
//         '/profile/doctor',
//         data: data,
//       );
//       return response.data;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

// // Get all appointments for the logged-in user (patient or doctor)
//   Future<List<Map<String, dynamic>>> getAppointments() async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl(ApiEndpoints.appointmentsByUser),
//       );
//       if (response.data['success'] && response.data['appointments'] is List) {
//         return List<Map<String, dynamic>>.from(response.data['appointments']);
//       }
//       return [];
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Doctor-specific appointments
//   Future<List<Map<String, dynamic>>> getDoctorAppointments() async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl(ApiEndpoints.appointmentsByDoctor),
//       );
//       if (response.data['success'] && response.data['appointments'] is List) {
//         return List<Map<String, dynamic>>.from(response.data['appointments']);
//       }
//       return [];
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Create a new appointment
//   Future<Map<String, dynamic>> createAppointment({
//     required String doctorId,
//     required String dateTime, // Changed from appointmentDate
//     required String timeSlot,
//     required String reasonForVisit, // Changed from reason
//     required double amount,
//   }) async {
//     try {
//       // Create a properly formatted appointment data object
//       final data = {
//         'doctorId': doctorId,
//         'dateTime': dateTime, // This should be a complete date-time string
//         'timeSlot': timeSlot,
//         'reasonForVisit': reasonForVisit,
//         'duration': 30 // Default duration in minutes as required by backend
//       };

//       print("Creating appointment with data: $data");

//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl(ApiEndpoints.appointments),
//         data: data,
//       );

//       return response.data;
//     } catch (e) {
//       print("Error creating appointment: $e");

//       if (e is DioException && e.response != null) {
//         // Handle error response from the server
//         final errorResponse = e.response!;
//         if (errorResponse.data is Map<String, dynamic>) {
//           return errorResponse.data as Map<String, dynamic>;
//         } else if (errorResponse.data is String) {
//           return {'success': false, 'message': errorResponse.data};
//         }
//       }

//       throw _handleError(e);
//     }
//   }

//   // Updated version with notes parameter
//   Future<Map<String, dynamic>> updateAppointmentStatus(
//       String appointmentId, String status,
//       {String? cancellationReason, String? notes}) async {
//     try {
//       Map<String, dynamic> data = {'status': status};

//       // If cancellation reason is provided, add it
//       if (cancellationReason != null && cancellationReason.isNotEmpty) {
//         data['reason'] =
//             cancellationReason; // Backend expects 'reason', not 'cancellationReason'
//       }

//       // If notes are provided, add them
//       if (notes != null && notes.isNotEmpty) {
//         data['notes'] = notes;
//       }

//       print("Updating appointment $appointmentId to status: $status");
//       print("Using data: $data");

//       // Use the correct endpoint and HTTP method
//       final response = await _dio.put(
//         '/appointments/$appointmentId/status', // This is the correct endpoint
//         data: data,
//       );

//       print("Update response: ${response.data}");

//       if (response.statusCode == 200) {
//         return response.data;
//       } else {
//         return {
//           'success': false,
//           'message':
//               response.data['message'] ?? 'Failed to update appointment status'
//         };
//       }
//     } catch (e) {
//       print("Error updating appointment status: $e");
//       return {'success': false, 'message': 'Error: ${e.toString()}'};
//     }
//   }

// // Add review to appointment
//   Future<Map<String, dynamic>> addAppointmentReview(
//       String appointmentId, int rating, String comment) async {
//     try {
//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl(
//             '${ApiEndpoints.appointments}/$appointmentId/review'),
//         data: {
//           'rating': rating,
//           'comment': comment,
//         },
//       );
//       return response.data;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Get doctor availability slots
//   Future<Map<String, dynamic>> getDoctorAvailability(String doctorId) async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl(
//             '${ApiEndpoints.doctors}/$doctorId/availability'),
//       );
//       return response.data;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Update doctor availability
//   Future<Map<String, dynamic>> updateDoctorAvailability(
//       String doctorId, List<Map<String, dynamic>> availability) async {
//     try {
//       final response = await _dio.put(
//         ApiEndpoints.getFullUrl(
//             '${ApiEndpoints.doctors}/$doctorId/availability'),
//         data: {'availability': availability},
//       );
//       return response.data;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

//   // Create a payment
//   Future<Map<String, dynamic>> createPayment({
//     required String appointmentId,
//     required String paymentMethod,
//     required double amount,
//   }) async {
//     try {
//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl(ApiEndpoints.payments),
//         data: {
//           'appointmentId': appointmentId,
//           'paymentMethod': paymentMethod,
//           'amount': amount,
//         },
//       );
//       return response.data;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Verify a payment
//   Future<Map<String, dynamic>> verifyPayment({
//     required String paymentId,
//     required String transactionId,
//   }) async {
//     try {
//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl(ApiEndpoints.paymentVerify),
//         data: {
//           'paymentId': paymentId,
//           'transactionId': transactionId,
//         },
//       );
//       return response.data;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Get payment by appointment ID
// // Get payment for a specific appointment
//   Future<Map<String, dynamic>> getPaymentForAppointment(
//       String appointmentId) async {
//     try {
//       final response =
//           await _dio.get('/payments/by-appointment/$appointmentId');

//       if (response.statusCode == 200) {
//         return {'success': true, 'data': response.data['data']};
//       } else {
//         return {
//           'success': false,
//           'message':
//               response.data['message'] ?? 'Failed to get payment information'
//         };
//       }
//     } catch (e) {
//       print('Error getting payment for appointment: $e');
//       return {'success': false, 'message': 'Error: $e'};
//     }
//   }

// // Request a refund
//   Future<Map<String, dynamic>> requestRefund(
//       {required String paymentId, required String reason}) async {
//     try {
//       final response = await _dio.post(
//         '/payments/$paymentId/refund',
//         data: {'reason': reason},
//       );

//       if (response.statusCode == 200) {
//         return {'success': true, 'data': response.data['data']};
//       } else {
//         return {
//           'success': false,
//           'message': response.data['message'] ?? 'Failed to process refund'
//         };
//       }
//     } catch (e) {
//       print('Error processing refund: $e');
//       return {'success': false, 'message': 'Error: $e'};
//     }
//   }

// // Get all payments for a user (patient or doctor)
//   Future<List<Map<String, dynamic>>> getUserPayments() async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.payments}/user'),
//       );
//       if (response.data['success'] && response.data['payments'] is List) {
//         return List<Map<String, dynamic>>.from(response.data['payments']);
//       }
//       return [];
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

//   // Get all medical records for a patient
//   Future<List<Map<String, dynamic>>> getPatientMedicalRecords() async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl(ApiEndpoints.patientMedicalRecords),
//       );
//       if (response.data['success'] && response.data['records'] is List) {
//         return List<Map<String, dynamic>>.from(response.data['records']);
//       }
//       return [];
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Create a new medical record
//   // Replace the existing createMedicalRecord method (around line 560-587) with this:

// // Create a new detailed medical record
//   // Create medical record for an appointment
//   // Create a new medical record
//   Future<Map<String, dynamic>> createMedicalRecord({
//     required String appointmentId,
//     required String diagnosis,
//     required String symptoms,
//     required String treatment,
//     required String prescription,
//     required List<String> tests, // Changed from String to List<String>
//     required String notes,
//   }) async {
//     try {
//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl(
//             '${ApiEndpoints.appointments}/$appointmentId/medical-record'),
//         data: {
//           'diagnosis': diagnosis,
//           'symptoms': symptoms,
//           'treatment': treatment,
//           'prescription': prescription,
//           'tests': tests, // Pass the list directly
//           'notes': notes,
//         },
//       );
//       return response.data;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Get a single medical record
//   Future<Map<String, dynamic>> getMedicalRecord(String recordId) async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.medicalRecords}/$recordId'),
//       );
//       return response.data;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

// // Get the PDF of a medical record
//   Future<String?> getMedicalRecordPdf(String recordId) async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.medicalRecords}/$recordId/pdf'),
//       );
//       if (response.data['success'] && response.data['pdfUrl'] != null) {
//         return response.data['pdfUrl'];
//       }
//       return null;
//     } catch (e) {
//       throw _handleError(e);
//     }
//   }

//   // Get all notifications for the logged-in user
//   Future<List<Map<String, dynamic>>> getUserNotifications() async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl(ApiEndpoints.notifications),
//       );

//       print("Notifications response status: ${response.statusCode}");

//       // Check for successful response
//       if (response.statusCode == 200) {
//         // Handle the response data structure
//         if (response.data is Map<String, dynamic> &&
//             response.data.containsKey('data')) {
//           // If response has a 'data' field containing the array
//           final List<dynamic> notificationsData = response.data['data'];
//           print("Found ${notificationsData.length} notifications in response");
//           return List<Map<String, dynamic>>.from(notificationsData);
//         } else if (response.data is List) {
//           // If response is directly the array
//           print(
//               "Found ${response.data.length} notifications in response (direct list)");
//           return List<Map<String, dynamic>>.from(response.data);
//         }
//       }

//       print("No notifications found in response or invalid format");
//       return [];
//     } catch (e) {
//       print("Error fetching notifications: $e");
//       throw _handleError(e);
//     }
//   }

// // Mark notification as read
//   Future<Map<String, dynamic>> markNotificationAsRead(
//       String notificationId) async {
//     try {
//       print("Marking notification as read: $notificationId");
//       final response = await _dio.put(
//         ApiEndpoints.getFullUrl(
//             '${ApiEndpoints.notifications}/$notificationId'),
//       );

//       return response.data;
//     } catch (e) {
//       print("Error marking notification as read: $e");
//       return {
//         'success': false,
//         'message': 'Failed to mark notification as read: $e'
//       };
//     }
//   }

// // Mark all notifications as read
//   Future<Map<String, dynamic>> markAllNotificationsAsRead(
//       List<String> notificationIds) async {
//     try {
//       print("Marking all notifications as read with individual requests");

//       // Track success count
//       int successCount = 0;

//       // Make individual requests for each notification
//       for (String id in notificationIds) {
//         try {
//           final result = await markNotificationAsRead(id);
//           if (result['success'] == true) {
//             successCount++;
//           }
//         } catch (e) {
//           print("Error marking notification $id as read: $e");
//         }
//       }

//       return {
//         'success': true,
//         'message':
//             'Marked $successCount/${notificationIds.length} notifications as read',
//         'count': successCount
//       };
//     } catch (e) {
//       print("Error in batch mark as read: $e");
//       return {
//         'success': false,
//         'message': 'Failed to mark notifications as read: $e'
//       };
//     }
//   }

//   Future<Map<String, dynamic>> createNotification({
//     required String userId,
//     required String title,
//     required String message,
//     required String type,
//     String? relatedId,
//   }) async {
//     try {
//       final data = {
//         'userId': userId,
//         'title': title,
//         'message': message,
//         'type': type,
//         'relatedId': relatedId,
//       };

//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl(ApiEndpoints.notifications),
//         data: data,
//       );

//       return response.data;
//     } catch (e) {
//       // Just log the error, don't throw since the notification is not critical
//       print("Error creating notification (this is not critical): $e");
//       return {'success': false, 'message': 'Notification API unavailable'};
//     }
//   }

//   Future<dynamic> getUserAppointments() async {
//     try {
//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl(ApiEndpoints.appointments),
//       );

//       print("Raw API response for appointments: ${response.statusCode}");
//       return response.data;
//     } catch (e) {
//       print("API error getting appointments: $e");
//       throw _handleError(e);
//     }
//   }

//   // Create a payment order (uses PayPal)
//   Future<Map<String, dynamic>> createPaymentOrder({
//     required String appointmentId,
//     required double amount,
//   }) async {
//     try {
//       print(
//           "Creating payment order for appointment: $appointmentId with amount: $amount");

//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.payments}/create-order'),
//         data: {
//           'appointmentId': appointmentId,
//           'amount': amount,
//         },
//       );

//       print("Payment order creation response: ${response.data}");
//       return response.data;
//     } catch (e) {
//       print("Error creating payment order: $e");
//       throw _handleError(e);
//     }
//   }

// // Capture a payment (confirms the PayPal payment)
//   Future<Map<String, dynamic>> capturePayment(String orderId) async {
//     try {
//       print("Capturing payment for order: $orderId");

//       final response = await _dio.post(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.payments}/capture/$orderId'),
//       );

//       print("Payment capture response: ${response.data}");
//       return response.data;
//     } catch (e) {
//       print("Error capturing payment: $e");
//       throw _handleError(e);
//     }
//   }

// // Get payment history
//   Future<Map<String, dynamic>> getPaymentHistory({
//     String? startDate,
//     String? endDate,
//     String? status,
//     int page = 1,
//     int limit = 10,
//   }) async {
//     try {
//       print("Fetching payment history");

//       final queryParams = {
//         'page': page.toString(),
//         'limit': limit.toString(),
//         if (startDate != null) 'startDate': startDate,
//         if (endDate != null) 'endDate': endDate,
//         if (status != null) 'status': status,
//       };

//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.payments}/history'),
//         queryParameters: queryParams,
//       );

//       print("Payment history response: ${response.data}");
//       return response.data;
//     } catch (e) {
//       print("Error fetching payment history: $e");
//       throw _handleError(e);
//     }
//   }

//   // Get payment receipt
//   Future<String> getPaymentReceipt(String paymentId) async {
//     try {
//       print("Fetching receipt for payment: $paymentId");

//       // For web or mobile, just return the URL
//       final receiptUrl =
//           '${ApiEndpoints.baseUrl}${ApiEndpoints.payments}/$paymentId/receipt';
//       return receiptUrl;
//     } catch (e) {
//       print("Error fetching payment receipt: $e");
//       throw _handleError(e);
//     }
//   }

// // Get payment details
//   Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
//     try {
//       print("Fetching payment details for: $paymentId");

//       final response = await _dio.get(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.payments}/$paymentId'),
//       );

//       print("Payment details response: ${response.data}");
//       return response.data;
//     } catch (e) {
//       print("Error fetching payment details: $e");
//       throw _handleError(e);
//     }
//   }

//   Future<Map<String, dynamic>> updateAppointmentPayment(
//       String appointmentId, String paymentId) async {
//     try {
//       print("Updating appointment $appointmentId with payment $paymentId");

//       final response = await _dio.patch(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.appointments}/$appointmentId'),
//         data: {
//           'paymentId': paymentId,
//         },
//       );

//       print("Update appointment payment response: ${response.data}");
//       return response.data;
//     } catch (e) {
//       print("Error updating appointment payment: $e");
//       throw _handleError(e);
//     }
//   }

//   Future<Map<String, dynamic>> linkPaymentToAppointment(
//       String appointmentId, String paymentId) async {
//     try {
//       print("Linking payment $paymentId to appointment $appointmentId");

//       // Try a direct PATCH to update the appointment
//       final response = await _dio.patch(
//         ApiEndpoints.getFullUrl('${ApiEndpoints.appointments}/$appointmentId'),
//         data: {
//           'paymentId': paymentId,
//         },
//       );

//       print("Link payment response: ${response.data}");
//       return response.data;
//     } catch (e) {
//       print("Error linking payment to appointment: $e");
//       try {
//         // If PATCH fails, try PUT instead (some APIs prefer PUT for updates)
//         final response = await _dio.put(
//           ApiEndpoints.getFullUrl(
//               '${ApiEndpoints.appointments}/$appointmentId'),
//           data: {
//             'paymentId': paymentId,
//           },
//         );

//         print("Link payment (PUT) response: ${response.data}");
//         return response.data;
//       } catch (e2) {
//         print("Error with PUT method too: $e2");

//         // As a final fallback, try a custom endpoint if available
//         try {
//           final response = await _dio.post(
//             ApiEndpoints.getFullUrl(
//                 '${ApiEndpoints.appointments}/$appointmentId/payment'),
//             data: {
//               'paymentId': paymentId,
//             },
//           );

//           print("Link payment (custom endpoint) response: ${response.data}");
//           return response.data;
//         } catch (e3) {
//           print("All methods failed to link payment: $e3");
//           throw _handleError(e3);
//         }
//       }
//     }
//   }

//   Future<Map<String, dynamic>> updateAppointmentWithPayment(
//       String appointmentId, String paymentId) async {
//     try {
//       print("Updating appointment $appointmentId with payment $paymentId");

//       // CRITICAL FIX: Remove the baseUrl from the path
//       final response = await _dio.patch(
//         '/appointments/$appointmentId', // Remove ${ApiEndpoints.baseUrl}/api
//         data: {
//           'paymentId': paymentId,
//         },
//       );

//       print("Update appointment response: ${response.data}");
//       return response.data;
//     } catch (e) {
//       print("Error updating appointment with payment: $e");
//       throw _handleError(e);
//     }
//   }

//   Future<String?> getToken() async {
//     return _authToken;
//   }

//   Future<Uint8List> getPaymentReceiptPdfData(String paymentId) async {
//     try {
//       print("Directly fetching receipt PDF data for payment: $paymentId");

//       final response = await _dio.get(
//         '${ApiEndpoints.baseUrl}${ApiEndpoints.payments}/$paymentId/receipt',
//         options: Options(
//           responseType: ResponseType.bytes,
//           headers: {
//             'Authorization': 'Bearer $_authToken',
//             'Accept': 'application/pdf',
//           },
//         ),
//       );

//       if (response.statusCode == 200) {
//         return Uint8List.fromList(response.data);
//       } else {
//         throw Exception(
//             'Failed to download receipt: Status ${response.statusCode}');
//       }
//     } catch (e) {
//       print("Error fetching receipt data: $e");
//       throw _handleError(e);
//     }
//   }

//   Future<String?> getAuthenticatedReceiptUrl(String paymentId) async {
//     try {
//       // Get the auth token
//       final token = await getToken();
//       if (token == null || token.isEmpty) {
//         throw Exception('Authentication token not available');
//       }

//       // Create the basic URL
//       final receiptUrl =
//           '${ApiEndpoints.baseUrl}${ApiEndpoints.payments}/$paymentId/receipt';

//       // Return a URL with the auth token as query parameter
//       return '$receiptUrl?auth_token=$token';
//     } catch (e) {
//       print("Error generating authenticated receipt URL: $e");
//       throw _handleError(e);
//     }
//   }

//   Future<Map<String, dynamic>?> getReceiptToken(String paymentId) async {
//     try {
//       print('Getting receipt token for payment: $paymentId');

//       final response = await _dio.get(
//         '/payments/$paymentId/receipt-token',
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer $_authToken',
//           },
//         ),
//       );

//       print('Receipt token response status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         print('Receipt token obtained successfully');
//         return response.data;
//       }

//       print('Failed to get receipt token: ${response.data}');
//       return null;
//     } catch (e) {
//       print('Error getting receipt token: $e');
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> getReceiptDetails(String paymentId) async {
//     try {
//       print('Getting receipt details for payment: $paymentId');

//       final response = await _dio.get('/payments/$paymentId/receipt-details');

//       if (response.statusCode == 200) {
//         print('Receipt details obtained successfully');
//         return response.data;
//       }

//       print('Failed to get receipt details: ${response.data}');
//       return null;
//     } catch (e) {
//       print('Error getting receipt details: $e');
//       return null;
//     }
//   }

//   // Modify in ApiService class
//   Future<Map<String, dynamic>> cancelAppointmentWithRefund({
//     required String appointmentId,
//     required String reason,
//   }) async {
//     try {
//       print('Cancelling appointment with refund: $appointmentId');

//       // First update the appointment status - CRITICAL FIX: use the correct path without prepending '/api'
//       final appointmentResponse = await _dio.put(
//         '/appointments/$appointmentId', // NOT '/api/appointments/$appointmentId'
//         data: {
//           'status': 'cancelled',
//           'cancelledBy': 'patient',
//           'cancellationReason': reason
//         },
//       );

//       if (appointmentResponse.statusCode == 200) {
//         print('Appointment status updated to cancelled');

//         // Now request the refund if there was a payment
//         final payment = appointmentResponse.data['data']?['payment'];

//         if (payment != null && payment['_id'] != null) {
//           final paymentId = payment['_id'];

//           // Process refund through the refund endpoint - CRITICAL FIX: use the correct path
//           final refundResponse = await _dio.post(
//             '/payments/$paymentId/refund', // NOT '/api/payments/$paymentId/refund'
//             data: {
//               'reason': reason,
//             },
//           );

//           if (refundResponse.statusCode == 200) {
//             print('Refund processed successfully');
//             return {
//               'success': true,
//               'message':
//                   'Appointment cancelled and refund initiated successfully',
//               'data': refundResponse.data['data']
//             };
//           } else {
//             print('Failed to process refund: ${refundResponse.data}');
//             return {
//               'success': false,
//               'message': refundResponse.data['message']?.toString() ??
//                   'Failed to process refund'
//             };
//           }
//         }

//         // If no payment found, just return success for the cancellation
//         return {
//           'success': true,
//           'message': 'Appointment cancelled successfully'
//         };
//       } else {
//         print('Failed to update appointment: ${appointmentResponse.data}');
//         return {
//           'success': false,
//           'message': appointmentResponse.data['message']?.toString() ??
//               'Failed to cancel appointment'
//         };
//       }
//     } catch (e) {
//       print('Error cancelling appointment: $e');
//       return {'success': false, 'message': 'Error: $e'};
//     }
//   }

//   bool hasValidToken() {
//     return _authToken != null && _authToken!.isNotEmpty;
//   }

//   void refreshToken(String token) {
//     print('Refreshing auth token: ${token.substring(0, 10)}...');
//     setAuthToken(token);
//   }

//   Future<Map<String, dynamic>?> getProfileById(String userId) async {
//     try {
//       // We'll use your API token to authenticate
//       // Then call one of your API endpoints that might help us

//       // First, try the auth/users endpoint with a query filter
//       final response = await _dio.get(
//         '${ApiEndpoints.baseUrl}/auth/users?id=${userId}',
//         options: Options(headers: await _getAuthHeaders()),
//       );

//       if (response.data['success'] == true &&
//           response.data['data'] != null &&
//           response.data['data'].isNotEmpty) {
//         // Found the user by id query filter
//         return {'success': true, 'data': response.data['data'][0]};
//       }

//       // If that fails, try directly calling the profile API with admin privileges
//       // NOTE: This might not work depending on your backend security
//       throw Exception('User not found');
//     } catch (e) {
//       print('Error in getProfileById: $e');

//       // Fallback - if we can't get the profile directly, try to get partial info from an appointment
//       try {
//         final appointments = await getUserAppointments();
//         if (appointments['success'] == true && appointments['data'] != null) {
//           final List<dynamic> appointmentsData = appointments['data'];
//           final targetAppointment = appointmentsData.firstWhere(
//             (apt) =>
//                 apt['patientId'] is Map && apt['patientId']['_id'] == userId,
//             orElse: () => null,
//           );

//           if (targetAppointment != null &&
//               targetAppointment['patientId'] is Map) {
//             return {'success': true, 'data': targetAppointment['patientId']};
//           }
//         }
//       } catch (e2) {
//         print('Fallback error: $e2');
//       }
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>> get(String endpoint) async {
//     try {
//       final response = await _dio.get(endpoint);
//       return response.data;
//     } catch (e) {
//       print('Error making GET request to $endpoint: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }
// }
