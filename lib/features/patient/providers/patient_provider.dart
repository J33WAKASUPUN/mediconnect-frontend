import 'package:flutter/material.dart';
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement API call to get patient profile
      // Will be implemented when we add the backend endpoint
      _lastUpdated = '2025-03-08 14:38:02'; // Update timestamp
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}