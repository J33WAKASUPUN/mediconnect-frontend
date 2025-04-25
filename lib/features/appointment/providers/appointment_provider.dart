import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/api_service.dart';

class AppointmentProvider with ChangeNotifier {
  final ApiService _apiService;

  AppointmentProvider({required ApiService apiService})
      : _apiService = apiService;

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  final Map<String, Map<String, List<String>>> _doctorAvailability = {};

  // Getters
  List<Appointment> get appointments => _appointments;
  List<Appointment> get pendingAppointments =>
      _appointments.where((apt) => apt.status == 'pending').toList();
  List<Appointment> get confirmedAppointments =>
      _appointments.where((apt) => apt.status == 'confirmed').toList();
  List<Appointment> get upcomingAppointments =>
      _appointments.where((apt) => apt.isUpcoming).toList();
  List<Appointment> get pastAppointments =>
      _appointments.where((apt) => apt.isPast).toList();
  List<Appointment> get todayAppointments {
    final today = DateTime.now();
    return _appointments
        .where((apt) =>
            apt.appointmentDate.year == today.year &&
            apt.appointmentDate.month == today.month &&
            apt.appointmentDate.day == today.day &&
            (apt.status == 'confirmed' || apt.status == 'pending'))
        .toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, Map<String, List<String>>> get doctorAvailability =>
      _doctorAvailability;

  // Load all appointments
  Future<void> loadAppointments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print("Loading appointments from API...");
      final response = await _apiService.getUserAppointments();
      print("API Response structure: ${response.runtimeType}");

      List<dynamic> appointmentsData = [];

      // Check if response has the correct structure - handle nested data
      if (response is Map<String, dynamic>) {
        if (response['data'] != null && response['data'] is List) {
          appointmentsData = response['data'] as List<dynamic>;
          print(
              "Found appointments in response['data']: ${appointmentsData.length}");
        } else if (response['appointments'] != null &&
            response['appointments'] is List) {
          appointmentsData = response['appointments'] as List<dynamic>;
          print(
              "Found appointments in response['appointments']: ${appointmentsData.length}");
        } else {
          print("No appointments list found in response map");
        }
      } else if (response is List<dynamic>) {
        // Direct list response
        appointmentsData = response;
        print("Response is already a list: ${appointmentsData.length}");
      } else {
        print("Unexpected response format: ${response.runtimeType}");
      }

      // Process the appointments data
      _appointments = [];
      for (var json in appointmentsData) {
        try {
          // Extract appointment data based on your API structure
          final appointment = _extractAppointmentFromJson(json);
          if (appointment != null) {
            _appointments.add(appointment);
          }
        } catch (e) {
          print("Error parsing appointment: $e");
          print("Problematic JSON: $json");
        }
      }

      print("Successfully parsed ${_appointments.length} appointments");

      // Sort appointments by date
      _appointments
          .sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      // Print debug info
      print("Upcoming appointments: ${upcomingAppointments.length}");
      print("Past appointments: ${pastAppointments.length}");

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error loading appointments: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

// Helper method to extract appointment data from API response
  Appointment? _extractAppointmentFromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      print("Invalid appointment data: $json");
      return null;
    }

    print("Processing appointment: ${json['_id']}");
    print("Status: ${json['status']}, CancelledBy: ${json['cancelledBy']}");

    // Handle appointment date - check various field names
    DateTime appointmentDate = DateTime.now();
    if (json['appointmentDate'] != null) {
      appointmentDate = DateTime.tryParse(json['appointmentDate'].toString()) ??
          DateTime.now();
    } else if (json['dateTime'] != null) {
      appointmentDate =
          DateTime.tryParse(json['dateTime'].toString()) ?? DateTime.now();
    }

    // Handle doctor and patient IDs
    String doctorId = '';
    Map<String, dynamic>? doctorDetails;
    if (json['doctorId'] != null) {
      if (json['doctorId'] is Map<String, dynamic>) {
        var doctorData = json['doctorId'] as Map<String, dynamic>;
        doctorId = doctorData['_id']?.toString() ?? '';
        doctorDetails = doctorData;
      } else {
        doctorId = json['doctorId'].toString();
      }
    }

    String patientId = '';
    Map<String, dynamic>? patientDetails;
    if (json['patientId'] != null) {
      if (json['patientId'] is Map<String, dynamic>) {
        var patientData = json['patientId'] as Map<String, dynamic>;
        patientId = patientData['_id']?.toString() ?? '';
        patientDetails = patientData;
      } else {
        patientId = json['patientId'].toString();
      }
    }

    // Extract time slot - could be in several formats
    String timeSlot = '';
    if (json['timeSlot'] != null) {
      timeSlot = json['timeSlot'].toString();
    } else if (json['duration'] != null) {
      // Create a time slot from duration and dateTime
      final int duration = int.tryParse(json['duration'].toString()) ?? 30;
      final startHour = appointmentDate.hour;
      final startMinute = appointmentDate.minute;

      // Calculate end time
      final endDateTime = appointmentDate.add(Duration(minutes: duration));
      final endHour = endDateTime.hour;
      final endMinute = endDateTime.minute;

      // Format as HH:MM - HH:MM
      timeSlot =
          '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - '
          '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    }

    // Get amount from doctor's consultation fees if available
    double amount = 0.0;
    if (json['amount'] != null) {
      amount = double.tryParse(json['amount'].toString()) ?? 0.0;
    } else if (doctorDetails != null &&
        doctorDetails['doctorProfile'] != null &&
        doctorDetails['doctorProfile']['consultationFees'] != null) {
      amount = double.tryParse(
              doctorDetails['doctorProfile']['consultationFees'].toString()) ??
          0.0;
    }

    // Create appointment object with extracted data
    return Appointment(
      id: json['_id']?.toString() ?? '',
      doctorId: doctorId,
      patientId: patientId,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      reason: json['reasonForVisit']?.toString() ??
          json['reason']?.toString() ??
          '',
      amount: amount,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      doctorDetails: doctorDetails,
      patientDetails: patientDetails,
      review: json['review'] as Map<String, dynamic>?,
      medicalRecord: json['medicalRecord'] as Map<String, dynamic>?,
      paymentId: json['paymentId']?.toString(),
      isNotified: json['isNotified'] == true,
      cancelledBy: json['cancelledBy']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
    );
  }

  // Book a new appointment
  Future<bool> bookAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    required String timeSlot,
    required String reason,
    required double amount,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Extract the time from the timeSlot (e.g., "09:00 - 12:00" -> "09:00")
      final startTime = timeSlot.split(' - ').first.trim();

      // Format the appointment date with time as required by the backend
      // Create a full ISO datetime string
      final dateComponents =
          appointmentDate.toString().split(' ')[0]; // Get YYYY-MM-DD
      final fullDateTime =
          '$dateComponents $startTime:00'; // Format: YYYY-MM-DD HH:MM:00

      print("Booking appointment with datetime: $fullDateTime");

      final response = await _apiService.createAppointment(
        doctorId: doctorId,
        dateTime: fullDateTime, // Changed from appointmentDate
        timeSlot: timeSlot,
        reasonForVisit: reason, // Changed from reason
        amount: amount,
      );

      if (response['success'] == true) {
        // Create notification for doctor
        final appointmentData = response['data'];
        if (appointmentData != null && appointmentData['doctorId'] != null) {
          await _apiService.createNotification(
            userId: appointmentData['doctorId'],
            title: 'New Appointment Request',
            message: 'You have a new appointment request from a patient',
            type: 'appointment_created',
            relatedId: appointmentData['_id'],
          );
        }

        await loadAppointments(); // Refresh the list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Extract error message
        String errorMessage;
        if (response['message'] is List) {
          // Join multiple error messages
          errorMessage = (response['message'] as List).join(', ');
        } else {
          errorMessage =
              response['message']?.toString() ?? 'Failed to book appointment';
        }

        _error = errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update appointment status (for both patients and doctors)
  Future<bool> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response =
          await _apiService.updateAppointmentStatus(appointmentId, status);

      if (response['success']) {
        // Create notification about status change
        final appointmentData = response['appointment'];
        if (appointmentData != null) {
          String notificationUserId;
          String notificationTitle;
          String notificationMessage;

          if (status == 'confirmed') {
            notificationUserId = appointmentData['patientId'];
            notificationTitle = 'Appointment Confirmed';
            notificationMessage = 'Your appointment has been confirmed';
          } else if (status == 'cancelled') {
            // Assuming cancellation by doctor
            notificationUserId = appointmentData['patientId'];
            notificationTitle = 'Appointment Cancelled';
            notificationMessage = 'Your appointment has been cancelled';
          } else if (status == 'completed') {
            notificationUserId = appointmentData['patientId'];
            notificationTitle = 'Appointment Completed';
            notificationMessage =
                'Your appointment has been marked as completed';
          } else {
            notificationUserId = appointmentData['patientId'];
            notificationTitle = 'Appointment Status Updated';
            notificationMessage =
                'Your appointment status has been updated to $status';
          }

          await _apiService.createNotification(
            userId: notificationUserId,
            title: notificationTitle,
            message: notificationMessage,
            type: 'appointment',
            relatedId: appointmentId,
          );
        }

        await loadAppointments(); // Refresh the list
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update appointment status';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Convenience methods for common status changes
  Future<bool> confirmAppointment(String appointmentId) =>
      updateAppointmentStatus(appointmentId, 'confirmed');

  Future<bool> completeAppointment(String appointmentId) =>
      updateAppointmentStatus(appointmentId, 'completed');

  Future<bool> cancelAppointment(String appointmentId) =>
      updateAppointmentStatus(appointmentId, 'cancelled');

  Future<bool> markNoShow(String appointmentId) =>
      updateAppointmentStatus(appointmentId, 'no-show');

  // Add review to appointment
  Future<bool> addReview(
      String appointmentId, int rating, String comment) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.addAppointmentReview(
          appointmentId, rating, comment);

      if (response['success']) {
        await loadAppointments(); // Refresh the list
        return true;
      } else {
        _error = response['message'] ?? 'Failed to add review';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create medical record for an appointment (doctor only)
  // Replace the createMedicalRecord method (lines 162-193) with this:
// Create medical record for an appointment (doctor only)
  Future<bool> createMedicalRecord(
      String appointmentId, Map<String, dynamic> medicalData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createMedicalRecord(
        appointmentId: appointmentId,
        diagnosis: medicalData['diagnosis'] ?? '',
        symptoms: medicalData['symptoms'] ?? '',
        treatment: medicalData['treatment'] ?? '',
        prescription: medicalData['prescription'] ?? '',
        tests: medicalData['tests'] ?? '',
        notes: medicalData['notes'] ?? '',
      );
      if (response['success']) {
        await loadAppointments(); // Refresh the list
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create medical record';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get doctor availability
  Future<Map<String, List<String>>> getDoctorAvailability(
      String doctorId) async {
    try {
      // If we already have the data, return it
      if (_doctorAvailability.containsKey(doctorId)) {
        return _doctorAvailability[doctorId] ?? {};
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getDoctorAvailability(doctorId);

      if (response['success'] && response['availability'] != null) {
        // Process the availability data
        final Map<String, List<String>> availability = {};

        for (var slot in response['availability']) {
          final String day = slot['day'];
          final List<String> times = List<String>.from(slot['slots'] ?? []);
          availability[day] = times;
        }

        // Cache the data
        _doctorAvailability[doctorId] = availability;

        _isLoading = false;
        notifyListeners();
        return availability;
      } else {
        _error = response['message'] ?? 'Failed to get doctor availability';
        _isLoading = false;
        notifyListeners();
        return {};
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }

  // Update doctor availability (doctor only)
  Future<bool> updateDoctorAvailability(
      String doctorId, Map<String, List<String>> availability) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Convert to the format expected by the API
      final List<Map<String, dynamic>> availabilityData = [];

      availability.forEach((day, slots) {
        availabilityData.add({
          'day': day,
          'slots': slots,
        });
      });

      final response = await _apiService.updateDoctorAvailability(
          doctorId, availabilityData);

      if (response['success']) {
        // Update the cached data
        _doctorAvailability[doctorId] = availability;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update doctor availability';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
