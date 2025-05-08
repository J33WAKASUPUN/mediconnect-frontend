// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mediconnect/config/api_endpoints.dart';
import 'package:mediconnect/core/services/review_service.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'appointment_service.dart';
import 'payment_service.dart';
import 'medical_record_service.dart';
import 'notification_service.dart';

/// Main API service that delegates to specialized services
class ApiService {
  final AuthService _authService;
  final ProfileService _profileService;
  final AppointmentService _appointmentService;
  final PaymentService _paymentService;
  final MedicalRecordService _medicalRecordService;
  final NotificationService _notificationService;
  final http.Client _httpClient = http.Client();
  final ReviewService _reviewService;

  ApiService()
      : _authService = AuthService(),
        _profileService = ProfileService(),
        _appointmentService = AppointmentService(),
        _paymentService = PaymentService(),
        _medicalRecordService = MedicalRecordService(),
        _notificationService = NotificationService(),
        _reviewService = ReviewService() {
    // Initialize review service with token if available
    if (_authService.hasValidToken()) {
      final token = _authService.getAuthToken();
      if (token.isNotEmpty) {
        _reviewService.setAuthToken(token);
      }
    }
  }
  // Auth methods
  void setAuthToken(String token) {
    _authService.setAuthToken(token);
    _profileService.setAuthToken(token);
    _appointmentService.setAuthToken(token);
    _paymentService.setAuthToken(token);
    _medicalRecordService.setAuthToken(token);
    _notificationService.setAuthToken(token);
    _reviewService.setAuthToken(token);
  }

// Direct synchronous auth token accessor (non-async)
  String getAuthToken() => _authService.getAuthToken();

// Receipt URLs
  String getReceiptViewerUrl(String paymentId) =>
      _paymentService.getReceiptViewerUrl(paymentId);
  String getReceiptPdfUrl(String paymentId) =>
      _paymentService.getReceiptPdfUrl(paymentId);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) =>
      _authService.login(email: email, password: password, role: role);

  Future<bool> verifyApiConnection() => _authService.verifyApiConnection();
  bool hasValidToken() => _authService.hasValidToken();
  void refreshToken(String token) => setAuthToken(token);
  Future<String?> getToken() => _authService.getToken();

  // Profile methods
  Future<Map<String, dynamic>> getProfile() => _profileService.getProfile();

  Future<Map<String, dynamic>> updateBasicProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    File? profilePicture,
  }) =>
      _profileService.updateBasicProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        address: address,
        profilePicture: profilePicture,
      );

  Future<Map<String, dynamic>> updatePatientProfile({
    String? bloodType,
    List<String>? medicalHistory,
    List<String>? allergies,
    List<String>? currentMedications,
    List<String>? chronicConditions,
    List<Map<String, dynamic>>? emergencyContacts,
    Map<String, dynamic>? insuranceInfo,
  }) =>
      _profileService.updatePatientProfile(
        bloodType: bloodType,
        medicalHistory: medicalHistory,
        allergies: allergies,
        currentMedications: currentMedications,
        chronicConditions: chronicConditions,
        emergencyContacts: emergencyContacts,
        insuranceInfo: insuranceInfo,
      );

  Future<Map<String, dynamic>> updateDoctorProfile({
    String? specialization,
    String? licenseNumber,
    int? yearsOfExperience,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? hospitalAffiliations,
    List<Map<String, dynamic>>? availableTimeSlots,
    double? consultationFees,
    List<String>? expertise,
  }) =>
      _profileService.updateDoctorProfile(
        specialization: specialization,
        licenseNumber: licenseNumber,
        yearsOfExperience: yearsOfExperience,
        education: education,
        hospitalAffiliations: hospitalAffiliations,
        availableTimeSlots: availableTimeSlots,
        consultationFees: consultationFees,
        expertise: expertise,
      );

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
  }) =>
      _profileService.register(
        email: email,
        password: password,
        role: role,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        gender: gender,
        address: address,
        profilePicture: profilePicture,
      );

  Future<Map<String, dynamic>?> getProfileById(String userId) =>
      _profileService.getProfileById(userId);

  Future<List<Map<String, dynamic>>> getAllDoctors() =>
      _profileService.getAllDoctors();

  // Appointment methods
  Future<dynamic> getUserAppointments() =>
      _appointmentService.getUserAppointments();

  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required String dateTime,
    required String timeSlot,
    required String reasonForVisit,
    required double amount,
  }) =>
      _appointmentService.createAppointment(
        doctorId: doctorId,
        dateTime: dateTime,
        timeSlot: timeSlot,
        reasonForVisit: reasonForVisit,
        amount: amount,
      );

  Future<Map<String, dynamic>> updateAppointmentStatus(
          String appointmentId, String status,
          {String? cancellationReason, String? notes}) =>
      _appointmentService.updateAppointmentStatus(
        appointmentId,
        status,
        cancellationReason: cancellationReason,
        notes: notes,
      );

  Future<Map<String, dynamic>> addAppointmentReview(
          String appointmentId, int rating, String comment) =>
      _appointmentService.addAppointmentReview(appointmentId, rating, comment);

  Future<List<Map<String, dynamic>>> getDoctorAppointments() =>
      _appointmentService.getDoctorAppointments();

  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId) =>
      _appointmentService.getDoctorAvailability(doctorId);

  Future<Map<String, dynamic>> updateDoctorAvailability(
          String doctorId, List<Map<String, dynamic>> availability) =>
      _appointmentService.updateDoctorAvailability(doctorId, availability);

  Future<Map<String, dynamic>> cancelAppointmentWithRefund({
    required String appointmentId,
    required String reason,
  }) =>
      _appointmentService.cancelAppointmentWithRefund(
        appointmentId: appointmentId,
        reason: reason,
      );

  // Payment methods
  Future<Map<String, dynamic>> createPayment({
    required String appointmentId,
    required String paymentMethod,
    required double amount,
  }) =>
      _paymentService.createPayment(
          appointmentId: appointmentId,
          paymentMethod: paymentMethod,
          amount: amount);

  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String transactionId,
  }) =>
      _paymentService.verifyPayment(
          paymentId: paymentId, transactionId: transactionId);

  Future<List<Map<String, dynamic>>> getUserPayments() =>
      _paymentService.getUserPayments();

  Future<List<Map<String, dynamic>>> getAppointments() =>
      _appointmentService.getAppointments();

  Future<Map<String, dynamic>> createPaymentOrder({
    required String appointmentId,
    required double amount,
  }) =>
      _paymentService.createPaymentOrder(
        appointmentId: appointmentId,
        amount: amount,
      );

  Future<Map<String, dynamic>> capturePayment(String orderId) =>
      _paymentService.capturePayment(orderId);

  Future<Map<String, dynamic>?> getReceiptDetails(String paymentId) =>
      _paymentService.getReceiptDetails(paymentId);

  Future<Map<String, dynamic>> getPaymentHistory({
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
    int limit = 10,
  }) =>
      _paymentService.getPaymentHistory(
        startDate: startDate,
        endDate: endDate,
        status: status,
        page: page,
        limit: limit,
      );

  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) =>
      _paymentService.getPaymentDetails(paymentId);

  Future<Map<String, dynamic>> getPaymentForAppointment(String appointmentId) =>
      _paymentService.getPaymentForAppointment(appointmentId);

  Future<Map<String, dynamic>> requestRefund(
          {required String paymentId, required String reason}) =>
      _paymentService.requestRefund(paymentId: paymentId, reason: reason);

  Future<String> getPaymentReceipt(String paymentId) =>
      _paymentService.getPaymentReceipt(paymentId);

  Future<Uint8List> getPaymentReceiptPdfData(String paymentId) =>
      _paymentService.getPaymentReceiptPdfData(paymentId);

  Future<String?> getAuthenticatedReceiptUrl(String paymentId) =>
      _paymentService.getAuthenticatedReceiptUrl(paymentId);

  Future<Map<String, dynamic>?> getReceiptToken(String paymentId) =>
      _paymentService.getReceiptToken(paymentId);

  Future<Map<String, dynamic>> linkPaymentToAppointment(
          String appointmentId, String paymentId) =>
      _paymentService.linkPaymentToAppointment(appointmentId, paymentId);

  Future<Map<String, dynamic>> updateAppointmentPayment(
          String appointmentId, String paymentId) =>
      _paymentService.linkPaymentToAppointment(appointmentId, paymentId);

  Future<Map<String, dynamic>> updateAppointmentWithPayment(
          String appointmentId, String paymentId) =>
      _paymentService.linkPaymentToAppointment(appointmentId, paymentId);

  // Medical record methods
  Future<dynamic> createMedicalRecord({
    required String appointmentId,
    required String diagnosis,
    required String notes,
    List<Map<String, dynamic>>? prescriptions,
    List<Map<String, dynamic>>? testResults,
    DateTime? nextVisitDate,
  }) async {
    return await _medicalRecordService.createMedicalRecord(
      appointmentId: appointmentId,
      diagnosis: diagnosis,
      notes: notes,
      prescriptions: prescriptions,
      testResults: testResults,
      nextVisitDate: nextVisitDate,
    );
  }

  Future<dynamic> getMedicalRecord(String recordId) async {
    return await _medicalRecordService.getMedicalRecord(recordId);
  }

  Future<dynamic> getPatientMedicalRecords() async {
    return await _medicalRecordService.getPatientMedicalRecords();
  }

  Future<dynamic> getPatientMedicalRecordsById(String patientId) async {
    return await _medicalRecordService.getPatientMedicalRecordsById(patientId);
  }

  Future<String?> generateMedicalRecordPdf(String recordId) async {
    return await _medicalRecordService.generatePdf(recordId);
  }

  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final baseService = BaseApiService();
      if (_authService.hasValidToken()) {
        baseService.setAuthToken(await _authService.getToken() ?? '');
      }
      final response = await baseService.post(endpoint, data: data);
      return response is Map<String, dynamic>
          ? response
          : {'success': false, 'message': 'Invalid response'};
    } catch (e) {
      print('Error making POST request to $endpoint: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Notification methods
  Future<List<Map<String, dynamic>>> getUserNotifications() =>
      _notificationService.getUserNotifications();

  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) =>
      _notificationService.markNotificationAsRead(notificationId);

  Future<Map<String, dynamic>> markAllNotificationsAsRead(
          List<String> notificationIds) =>
      _notificationService.markAllNotificationsAsRead(notificationIds);

  Future<Map<String, dynamic>> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) =>
      _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      );

  // Legacy support method for direct GET requests
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final baseService = BaseApiService();
      if (_authService.hasValidToken()) {
        baseService.setAuthToken(await _authService.getToken() ?? '');
      }
      final response = await baseService.get(endpoint);
      return response is Map<String, dynamic>
          ? response
          : {'success': false, 'message': 'Invalid response'};
    } catch (e) {
      print('Error making GET request to $endpoint: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  http.Client get httpClient => _httpClient;

  String? get _authToken => _authService.getAuthToken();

  String get authToken => _authToken ?? '';

  Future<Uint8List> downloadFile(String endpoint) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/octet-stream',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  // Create a review for an appointment
  Future<Map<String, dynamic>> createReview({
    required String appointmentId,
    required int rating,
    required String review,
    bool isAnonymous = false,
  }) =>
      _reviewService.createReview(
        appointmentId: appointmentId,
        rating: rating,
        review: review,
        isAnonymous: isAnonymous,
      );

// Get reviews for a doctor
  Future<Map<String, dynamic>> getDoctorReviews(
    String doctorId, {
    int page = 1,
    int limit = 10,
  }) =>
      _reviewService.getDoctorReviews(doctorId, page: page, limit: limit);

// Add doctor's response to a review
  Future<Map<String, dynamic>> addDoctorResponse({
    required String reviewId,
    required String response,
  }) =>
      _reviewService.addDoctorResponse(
        reviewId: reviewId,
        response: response,
      );

// Get doctor review analytics
  Future<Map<String, dynamic>> getDoctorReviewAnalytics(String doctorId) =>
      _reviewService.getDoctorReviewAnalytics(doctorId);
}
