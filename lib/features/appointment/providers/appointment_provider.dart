import 'package:flutter/material.dart';
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
  final Map<String, String> _localPaymentMapping = {};

  // NEW: Store the latest created appointment
  Appointment? _latestAppointment;

  // Add set for tracking refunded appointments
  final Set<String> _refundedAppointments = {};

  // Getters
  List<Appointment> get appointments {
    return _appointments.map((apt) {
      if (_paidAppointments.contains(apt.id) &&
          !_refundedAppointments.contains(apt.id)) {
        // Create a new appointment with payment info
        return Appointment(
          id: apt.id,
          doctorId: apt.doctorId,
          patientId: apt.patientId,
          appointmentDate: apt.appointmentDate,
          timeSlot: apt.timeSlot,
          reason: apt.reason,
          amount: apt.amount,
          status: apt.status,
          createdAt: apt.createdAt,
          updatedAt: apt.updatedAt,
          doctorDetails: apt.doctorDetails,
          patientDetails: apt.patientDetails,
          review: apt.review,
          medicalRecord: apt.medicalRecord,
          paymentId: "payment-completed", // Mark as paid
          isNotified: apt.isNotified,
          cancelledBy: apt.cancelledBy,
          cancellationReason: apt.cancellationReason,
        );
      } else if (_refundedAppointments.contains(apt.id)) {
        // Create a new appointment with refunded payment info
        return Appointment(
          id: apt.id,
          doctorId: apt.doctorId,
          patientId: apt.patientId,
          appointmentDate: apt.appointmentDate,
          timeSlot: apt.timeSlot,
          reason: apt.reason,
          amount: apt.amount,
          status: apt.status,
          createdAt: apt.createdAt,
          updatedAt: apt.updatedAt,
          doctorDetails: apt.doctorDetails,
          patientDetails: apt.patientDetails,
          review: apt.review,
          medicalRecord: apt.medicalRecord,
          paymentId: "payment-refunded", // Mark as refunded
          isNotified: apt.isNotified,
          cancelledBy: apt.cancelledBy,
          cancellationReason: apt.cancellationReason,
        );
      }
      return apt;
    }).toList();
  }

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

  // NEW: Getter for the latest appointment
  Appointment? get latestAppointment => _latestAppointment;

  // Add this method to register payment locally
  void registerPaymentForAppointment(String appointmentId, String paymentId) {
    _localPaymentMapping[appointmentId] = paymentId;
    print(
        "Locally registered payment $paymentId for appointment $appointmentId");
    notifyListeners();
  }

  // Add this method to check if an appointment has a payment locally
  bool hasLocalPayment(String appointmentId) {
    return _localPaymentMapping.containsKey(appointmentId);
  }

  // Add this method to get the local payment ID
  String? getLocalPaymentId(String appointmentId) {
    return _localPaymentMapping[appointmentId];
  }

  // Method to check if an appointment is refunded
  bool isAppointmentRefunded(String appointmentId) {
    // First check in our tracked refunded appointments
    if (_refundedAppointments.contains(appointmentId)) {
      return true;
    }

    // Then check if it's a cancelled appointment with a payment
    final appointment = findAppointmentById(appointmentId);
    if (appointment != null &&
        appointment.status.toLowerCase() == 'cancelled' &&
        appointment.paymentId != null) {
      return true;
    }

    return false;
  }

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

      await syncPaymentStatus();

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

  // UPDATED: Book a new appointment with latestAppointment storage
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
      // Reset the latest appointment
      _latestAppointment = null;
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
        // NEW: Store the latest appointment for direct payment flow
        if (response['data'] != null) {
          try {
            _latestAppointment = _extractAppointmentFromJson(response['data']);
            print("Stored latest appointment: ${_latestAppointment?.id}");
          } catch (e) {
            print("Error extracting appointment from response: $e");
          }
        }

        // Create notification for doctor
        final appointmentData = response['data'];
        if (appointmentData != null && appointmentData['doctorId'] != null) {
          String? doctorId = _extractUserId(appointmentData['doctorId']);
          if (doctorId != null && doctorId.isNotEmpty) {
            await _apiService.createNotification(
              userId: doctorId,
              title: 'New Appointment Request',
              message: 'You have a new appointment request from a patient',
              type: 'appointment_created',
              relatedId: appointmentData['_id'],
            );
          }
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

  final Set<String> _paidAppointments = {};

  // Method to load and check payment status for appointments
  Future<void> syncPaymentStatus() async {
    try {
      print("Syncing appointment payment status...");

      // Now identify refunded appointments:
      // Any cancelled appointment that previously had a payment ID
      for (var apt in _appointments) {
        if (apt.status.toLowerCase() == 'cancelled' && apt.paymentId != null) {
          _refundedAppointments.add(apt.id);
          print("Marked refunded appointment from cancellation: ${apt.id}");
        }
      }

      // Also check payment history for explicit refund records
      try {
        final response =
            await _apiService.getPaymentHistory(page: 1, limit: 100);

        if (response['status'] == 'success' &&
            response['data'] != null &&
            response['data']['payments'] != null) {
          final payments = response['data']['payments'] as List<dynamic>;

          // Go through all payments to find refunds and completed payments
          for (var payment in payments) {
            final status = payment['status']?.toString().toUpperCase();
            final appointmentId = payment['appointmentId'] is Map
                ? payment['appointmentId']['_id']?.toString()
                : payment['appointmentId']?.toString();

            if (appointmentId != null) {
              if (status == 'COMPLETED') {
                _paidAppointments.add(appointmentId);
                print(
                    "Found completed payment for appointment: $appointmentId");
              } else if (status == 'REFUNDED') {
                _refundedAppointments.add(appointmentId);
                print("Found refunded payment for appointment: $appointmentId");
              }
            }
          }
        }
      } catch (e) {
        print("Error loading payment history: $e");
      }

      print(
          "Payment status sync complete. Paid: ${_paidAppointments.length}, Refunded: ${_refundedAppointments.length}");
      notifyListeners();
    } catch (e) {
      print("Error syncing payment status: $e");
    }
  }

  // Check if an appointment is paid (and not refunded)
  bool isAppointmentPaid(String appointmentId) {
    return _paidAppointments.contains(appointmentId) &&
        !_refundedAppointments.contains(appointmentId);
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
        final appointmentData = response['appointment'] ?? response['data'];
        if (appointmentData != null) {
          String notificationUserId;
          String notificationTitle;
          String notificationMessage;

          if (status == 'confirmed') {
            notificationUserId = _extractUserId(appointmentData['patientId']) ??
                appointmentData['patientId'].toString();
            notificationTitle = 'Appointment Confirmed';
            notificationMessage = 'Your appointment has been confirmed';
          } else if (status == 'cancelled') {
            notificationUserId = _extractUserId(appointmentData['patientId']) ??
                appointmentData['patientId'].toString();
            notificationTitle = 'Appointment Cancelled';
            notificationMessage = 'Your appointment has been cancelled';
          } else if (status == 'completed') {
            notificationUserId = _extractUserId(appointmentData['patientId']) ??
                appointmentData['patientId'].toString();
            notificationTitle = 'Appointment Completed';
            notificationMessage =
                'Your appointment has been marked as completed';
          } else {
            notificationUserId = _extractUserId(appointmentData['patientId']) ??
                appointmentData['patientId'].toString();
            notificationTitle = 'Appointment Status Updated';
            notificationMessage =
                'Your appointment status has been updated to $status';
          }

          if (notificationUserId.isNotEmpty) {
            await _apiService.createNotification(
              userId: notificationUserId,
              title: notificationTitle,
              message: notificationMessage,
              type: 'appointment',
              relatedId: appointmentId,
            );
          }
        }

        await loadAppointments(); // Refresh the list
        _isLoading = false;
        notifyListeners();
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
        _isLoading = false;
        notifyListeners();
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
  Future<bool> createMedicalRecord(
      String appointmentId, Map<String, dynamic> medicalData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createMedicalRecord(
        appointmentId: appointmentId,
        diagnosis: medicalData['diagnosis'] ?? '',
        notes: medicalData['notes'] ?? '',
        prescriptions: medicalData['prescriptions'] ?? [],
        testResults: medicalData['testResults'] ?? [],
      );

      if (response['success']) {
        await loadAppointments(); // Refresh the list
        _isLoading = false;
        notifyListeners();
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

  // Method to find a specific appointment by ID
  Appointment? findAppointmentById(String appointmentId) {
    try {
      final appointment = _appointments.firstWhere(
        (apt) => apt.id == appointmentId,
      );

      // If we have a local payment record for this appointment, create a modified version
      if (_localPaymentMapping.containsKey(appointmentId)) {
        return Appointment(
          id: appointment.id,
          doctorId: appointment.doctorId,
          patientId: appointment.patientId,
          appointmentDate: appointment.appointmentDate,
          timeSlot: appointment.timeSlot,
          reason: appointment.reason,
          amount: appointment.amount,
          status: appointment.status,
          createdAt: appointment.createdAt,
          updatedAt: appointment.updatedAt,
          doctorDetails: appointment.doctorDetails,
          patientDetails: appointment.patientDetails,
          review: appointment.review,
          medicalRecord: appointment.medicalRecord,
          paymentId:
              _localPaymentMapping[appointmentId], // Use local payment ID
          isNotified: appointment.isNotified,
          cancelledBy: appointment.cancelledBy,
          cancellationReason: appointment.cancellationReason,
        );
      }

      return appointment;
    } catch (e) {
      print("Error finding appointment: $e");
      return null;
    }
  }

  // NEW: Method to clear the latest appointment reference
  void clearLatestAppointment() {
    _latestAppointment = null;
    notifyListeners();
  }

  // APPOINTMENT CANCELLATION
  bool _isCancelling = false;
  bool get isCancelling => _isCancelling;

  Future<Map<String, dynamic>> cancelAppointmentWithRefund(
      String appointmentId, String reason) async {
    try {
      _isCancelling = true;
      _error = null;
      notifyListeners();

      // Call the correct endpoint with the right parameters
      final response = await _apiService.updateAppointmentStatus(
          appointmentId, 'cancelled',
          cancellationReason: reason);

      _isCancelling = false;

      if (response['success'] == true) {
        // If this appointment had a payment, mark it as refunded locally too
        if (_paidAppointments.contains(appointmentId)) {
          _refundedAppointments.add(appointmentId);
        }

        // Find the appointment to update in the local list
        int index = _appointments.indexWhere((apt) => apt.id == appointmentId);

        if (index >= 0) {
          // Get the existing appointment
          Appointment oldAppointment = _appointments[index];

          // Create a new appointment with updated properties
          Appointment updatedAppointment = Appointment(
            id: oldAppointment.id,
            doctorId: oldAppointment.doctorId,
            patientId: oldAppointment.patientId,
            appointmentDate: oldAppointment.appointmentDate,
            timeSlot: oldAppointment.timeSlot,
            reason: oldAppointment.reason,
            amount: oldAppointment.amount,
            status: 'cancelled', // Updated status
            createdAt: oldAppointment.createdAt,
            updatedAt: DateTime.now(), // Update the time
            doctorDetails: oldAppointment.doctorDetails,
            patientDetails: oldAppointment.patientDetails,
            review: oldAppointment.review,
            medicalRecord: oldAppointment.medicalRecord,
            paymentId: oldAppointment.paymentId,
            isNotified: oldAppointment.isNotified,
            cancelledBy: 'patient', // Set as cancelled by patient
            cancellationReason: reason, // Set the cancellation reason
          );

          // Replace the old appointment with the updated one
          _appointments[index] = updatedAppointment;
        }

        notifyListeners();

        // Refresh appointments to get updated data from the server
        await loadAppointments();

        // Also refresh payment status data
        await syncPaymentStatus();

        return {
          'success': true,
          'message': response['message']?.toString() ??
              'Appointment cancelled successfully and refund initiated'
        };
      } else {
        _error =
            response['message']?.toString() ?? 'Failed to cancel appointment';
        notifyListeners();
        return {'success': false, 'message': _error!};
      }
    } catch (e) {
      _error = e.toString();
      _isCancelling = false;
      notifyListeners();
      return {'success': false, 'message': _error!};
    }
  }

  Future<bool> confirmAppointmentWithNotes(
      String appointmentId, String notes) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Use the existing updateAppointmentStatus method but add notes
      final response = await _apiService
          .updateAppointmentStatus(appointmentId, 'confirmed', notes: notes);

      if (response['success']) {
        // Create notification about confirmation with notes
        final appointmentData = response['data'] ?? response['appointment'];
        String? patientId = appointmentData != null
            ? _extractUserId(appointmentData['patientId'])
            : null;
        if (patientId != null && patientId.isNotEmpty) {
          String message = 'Your appointment has been confirmed';
          if (notes.isNotEmpty) {
            message += ' with a note from the doctor';
          }

          await _apiService.createNotification(
            userId: patientId,
            title: 'Appointment Confirmed',
            message: message,
            type: 'appointment_confirmed',
            relatedId: appointmentId,
          );
        }

        await loadAppointments(); // Refresh the list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to confirm appointment';
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

  String? _extractUserId(dynamic userData) {
    if (userData == null) return null;

    if (userData is Map && userData['_id'] != null) {
      return userData['_id'].toString();
    } else if (userData is String) {
      return userData;
    } else {
      print("Warning: Unable to extract user ID from $userData");
      return null;
    }
  }

  Future<bool> cancelAppointmentWithReason(
      String appointmentId, String reason) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print("DEBUG: Cancelling with reason: $reason");

      // Create data object with all fields correctly set
      final response = await _apiService.updateAppointmentStatus(
        appointmentId,
        'cancelled',
        cancellationReason: reason, // Make sure this is passed correctly
      );

      print("DEBUG: Response from cancellation: $response");

      if (response['success']) {
        // Create notification about cancellation with reason
        final appointmentData = response['data'] ?? response['appointment'];
        if (appointmentData != null) {
          String? patientId = _extractUserId(appointmentData['patientId']);
          if (patientId != null && patientId.isNotEmpty) {
            await _apiService.createNotification(
              userId: patientId,
              title: 'Appointment Cancelled by Doctor',
              message: 'Your appointment has been cancelled. Reason: $reason',
              type: 'appointment_cancelled',
              relatedId: appointmentId,
            );
          }
        }

        await loadAppointments(); // Refresh the list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to cancel appointment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("ERROR in cancelAppointmentWithReason: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
