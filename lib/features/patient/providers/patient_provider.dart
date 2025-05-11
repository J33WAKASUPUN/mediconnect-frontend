import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/profile_models.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class PatientProvider with ChangeNotifier {
  // ignore: unused_field
  final ApiService _apiService;
  User? _patientProfile;
  bool _isLoading = false;
  String? _error;
  String _lastUpdated = '2025-03-08 14:38:02'; // Current UTC timestamp

  PatientProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  User? get patientProfile => _patientProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastUpdated => _lastUpdated;

  // Get patient profile
  Future<void> getPatientProfile() async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _apiService.getProfile();
    
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      
      if (data['patientProfile'] != null) {
        _patientProfile = PatientProfile.fromJson(data['patientProfile']) as User?;
        
        // Debug information
        print("Patient profile loaded: $_patientProfile");
        print("Blood Type: ${_patientProfile?.bloodType}");
        print("Allergies: ${_patientProfile?.allergies}");
      } else {
        _patientProfile = PatientProfile() as User?; // Default empty profile
      }
    }
    
  } catch (e) {
    _error = e.toString();
    print("Error getting patient profile: $e");
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}