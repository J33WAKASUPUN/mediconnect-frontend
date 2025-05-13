import 'package:flutter/material.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class DoctorProvider with ChangeNotifier {
  final ApiService _apiService;
  User? _doctorProfile;
  bool _isLoading = false;
  String? _error;
  String _lastUpdated = '2025-05-12 19:19:03'; // Current UTC timestamp
  
  // Additional metrics for the dashboard with defaults
  int _patientCount = 45; // Default value
  int _newPatientsThisMonth = 8; // Default value
  int _totalConsultations = 127; // Default value

  DoctorProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  User? get doctorProfile => _doctorProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastUpdated => _lastUpdated;
  int get patientCount => _patientCount;
  int get newPatientsThisMonth => _newPatientsThisMonth;
  int get totalConsultations => _totalConsultations;

  // Get doctor profile
  Future<void> getDoctorProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getProfile();
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        if (data['doctorProfile'] != null) {
          _doctorProfile = DoctorProfile.fromJson(data['doctorProfile']) as User?;
          
          // Debug information
          print("Doctor profile loaded: $_doctorProfile");
          print("Specialization: ${_doctorProfile?.specialization}");
          print("Experience: ${_doctorProfile?.yearsOfExperience}");
        } else {
          _doctorProfile = DoctorProfile() as User?; // Default empty profile
        }
      }
      
      // Update timestamp
      _lastUpdated = DateTime.now().toUtc().toString();
      
    } catch (e) {
      _error = e.toString();
      print("Error getting doctor profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method for timestamp
  String getCurrentTimestamp() {
    return _lastUpdated;
  }
}