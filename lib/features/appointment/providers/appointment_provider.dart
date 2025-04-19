import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/api_service.dart';

class AppointmentProvider with ChangeNotifier {
  final ApiService _apiService;

  AppointmentProvider({required ApiService apiService}) : _apiService = apiService;

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  Map<String, Map<String, List<String>>> _doctorAvailability = {};

  // Getters
  List<Appointment> get appointments => _appointments;
  List<Appointment> get pendingAppointments => _appointments.where((apt) => apt.status == 'pending').toList();
  List<Appointment> get confirmedAppointments => _appointments.where((apt) => apt.status == 'confirmed').toList();
  List<Appointment> get upcomingAppointments => _appointments.where((apt) => apt.isUpcoming).toList();
  List<Appointment> get pastAppointments => _appointments.where((apt) => apt.isPast).toList();
  List<Appointment> get todayAppointments {
    final today = DateTime.now();
    return _appointments.where((apt) => 
      apt.appointmentDate.year == today.year && 
      apt.appointmentDate.month == today.month && 
      apt.appointmentDate.day == today.day &&
      (apt.status == 'confirmed' || apt.status == 'pending')
    ).toList();
  }
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, Map<String, List<String>>> get doctorAvailability => _doctorAvailability;

  // Load all appointments
  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final jsonList = await _apiService.getAppointments();
      _appointments = jsonList.map((json) => Appointment.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
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

      final response = await _apiService.createAppointment(
        doctorId: doctorId,
        appointmentDate: DateFormat('yyyy-MM-dd').format(appointmentDate),
        timeSlot: timeSlot,
        reason: reason,
        amount: amount,
      );

      if (response['success']) {
        await loadAppointments(); // Refresh the list
        return true;
      } else {
        _error = response['message'] ?? 'Failed to book appointment';
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
  Future<bool> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateAppointmentStatus(appointmentId, status);
      
      if (response['success']) {
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
  Future<bool> addReview(String appointmentId, int rating, String comment) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.addAppointmentReview(
        appointmentId, 
        rating, 
        comment
      );
      
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
  Future<Map<String, List<String>>> getDoctorAvailability(String doctorId) async {
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

      final response = await _apiService.updateDoctorAvailability(doctorId, availabilityData);
      
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